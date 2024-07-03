#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Input file as the first argument
input_file=$1

# Check if input file is provided
if [ -z "$input_file" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi

# Log file
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.csv"

# Ensure the log file and password file exist and set correct permissions
touch $log_file
chmod 600 $log_file

mkdir -p /var/secure
touch $password_file
chmod 600 $password_file

# Function to log messages
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    tr -dc A-Za-z0-9 </dev/urandom | head -c 12

}
# Create required groups
groups=("dev" "admin" "user")
for group in "${groups[@]}"; do
  if ! getent group "$group" >/dev/null; then
    groupadd "$group"
    echo "$(date): Group $group created" >> $log_file
  else
    echo "$(date): Group $group already exists" >> $log_file
  fi
done

# Read the input file line by line
while IFS=';' read -r username groups; do
  # Remove whitespace
  username=$(echo "$username" | xargs)
  groups=$(echo "$groups" | xargs)

  # Create a primary group with the same name as the username
  if ! getent group "$username" >/dev/null; then
    groupadd "$username"
    echo "$(date): Group $username created" >> $log_file
  fi

  # Create the user with the primary group and home directory
  if ! id "$username" >/dev/null 2>&1; then
    useradd -m -g "$username" -s /bin/bash "$username"
    echo "$(date): User $username created with primary group $username and home directory" >> $log_file
  else
    echo "$(date): User $username already exists" >> $log_file
    continue
  fi

  # Add user to additional groups
  if [ -n "$groups" ]; then
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
      group=$(echo "$group" | xargs)
      if getent group "$group" >/dev/null; then
        usermod -aG "$group" "$username"
        echo "$(date): User $username added to group $group" >> $log_file
      fi
    done
  fi

  # Generate a random password
  password=$(openssl rand -base64 12)

  # Set the user's password
  echo "$username:$password" | chpasswd
  echo "$(date): Password set for user $username" >> $log_file

  # Store the username and password in the password file
  echo "$username,$password" >> $password_file
done < "$input_file"

echo "User creation process completed. Check $log_file for details."