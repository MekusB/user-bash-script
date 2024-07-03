Automate User Management

Automating User Creation and Management with Bash.
This involves creating user accounts, setting up configurations, and ensuring compliance with security standards.
To address these needs, the create_users.sh script was developed. This script is a robust automation tool designed to streamline the onboarding process for new developers by efficiently creating user accounts and configuring them on Linux systems.
In this article, we will create a Bash script that automates user and group creation, sets up home directories, and generates random passwords. This script will also log all actions and securely store generated passwords.
This technical article will explain the script’s architecture and explain the logic behind each function


Script Breakdown
Initial Setup

The script begins first run as root
# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1


# Check if input file is provided
if [ -z "$input_file" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1

The script begins by defining the log and password file paths and checking if the script is being run as the root user.

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
Input File Validation

It verifies if an input file containing the usernames and groups is provided.

if [ -z "$1" ]; then
  echo "Usage: $0 <name-of-text-file>"
  exit 1
fi
Creating Directories

Necessary directories for logging and storing passwords are created if they don't already exist.
mkdir -p /var/log
mkdir -p /var/secure

Logging and Password File Initialization
The log and password files are initialized.

echo "User Management Log" > $LOG_FILE
echo "username,password" > $PASSWORD_FILE
Reading and Processing the Input File


The script reads the input file line by line, extracts the username and groups, and handles user and group creation.
while IFS=';' read -r username groups; do
  # Processing each line
done < "$INPUT_FILE"


Generating Random Passwords
A function is defined to generate random passwords.
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}


Conclusion
Automating user and group creation with a bash script simplifies the onboarding process, enhances security, and ensures consistency. By following the steps outlined in this article, you can effectively manage user accounts on your system.

For more information about the HNG Internship, visit the HNG Internship(https://hng.tech/internship) 
