Automate User Management

Automating User Creation and Management with Bash.
This involves creating user accounts, setting up configurations, and ensuring security.
To address these needs, the create_users.sh script was developed. This script is an automation tool designed to streamline the onboarding process for new developers by efficiently creating user accounts and configuring them on Linux systems.
In this article, we will create a Bash script that automates user and group creation, sets up home directories, and generates random passwords. This script will also log all actions and securely store generated passwords.
This technical article will explain the script’s architecture and explain the logic behind each function


Step-by-Step Guide to create_users.sh Script 

Step 1: Check for Root Privileges
Purpose: Ensure the script is run with administrative (root) privileges.
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi
Explanation:
$(id -u): Fetches the current user's ID. An ID of 0 indicates root.
Why? Managing users and groups requires root access. If the script is not run as root, it will terminate early to prevent errors.

Step 2: Define Log and Password File Paths
Purpose: Specify where logs and password information will be stored.
LOG_DIR='/var/log'
LOG_FILE="$LOG_DIR/user_management.log"
SECURE_DIR='/var/secure'
SECURE_FILE="$SECURE_DIR/user_passwords.txt"
Explanation:
Variables LOG_FILE and SECURE_FILE hold paths for the log file and password file respectively.
Why? Centralizing file paths improves readability and makes future modifications easier.

Step 3: Create Required Directories and Files
Purpose: Ensure necessary directories and files exist, and set correct permissions.
create_directory_and_file() {
    local directory=$1
    local file=$2
    local owner=$3
    local dir_permissions=$4
    local file_permissions=$5

    if [ ! -d "$directory" ]; then
        mkdir -p "$directory"
    fi

    if [ ! -f "$file" ]; then
        touch "$file"
    fi

    chown "$owner:$owner" "$directory" "$file"
    chmod "$dir_permissions" "$directory"
    chmod "$file_permissions" "$file"
}

create_directory_and_file "$LOG_DIR" "$LOG_FILE" "${SUDO_USER:-$(whoami)}" 755 644
create_directory_and_file "$SECURE_DIR" "$SECURE_FILE" "${SUDO_USER:-$(whoami)}" 700 600
Explanation:
Checks if directories and files exist and creates them if not.
Sets appropriate ownership and permissions.
Why? Ensures that logging can occur and passwords are stored securely.

Step 4: Check for Input File
Purpose: Ensure an input file is provided and exists.
if [ $# -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Usage: $0 <input_file>" | tee -a $LOG_FILE
    exit 1
fi
input_file=$1
if [ ! -f "$input_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: File '$input_file' not found." | tee -a $LOG_FILE
    exit 1
fi
Explanation:
Verifies that the script is run with an input file argument.
Checks if the input file exists.
Why? Prevents errors and ensures the script has the necessary data to process.

Step 5: Generate Secure Passwords
Purpose: Generate a random, secure password for each new user.
generate_password() {
    tr -dc '[:alnum:]' < /dev/urandom | head -c 12
    echo
}
Explanation:

tr -dc '[:alnum:]' < /dev/urandom | head -c 12: Generates a random 12-character alphanumeric password.
Why? Ensures that each user has a strong, unique password, enhancing security.

Step 6: Create Users and Groups
Purpose: Read the input file, create users, assign groups, and set passwords.
create_user() {
    local username=$1

    if id "$username" &>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' already exists." | tee -a $LOG_FILE
        return 1
    fi

    local password=$(generate_password)
    echo "$username,$password" >> $SECURE_FILE

    useradd -m -s /bin/bash "$username"
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to add user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    echo "$username:$password" | chpasswd
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to set password for user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    local user_dir="/home/$username"
    mkdir -p "$user_dir"
    chown "$username:$username" "$user_dir"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' successfully created and home directory set up." | tee -a $LOG_FILE
}

user_groups() {
    local username=$1
    local groups=$2

    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if grep -q "^$group:" /etc/group; then
            if id -nG "$username" | grep -qw "$group"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' is already in Group '$group'" | tee -a $LOG_FILE
            else
                usermod -aG "$group" "$username"
                if [ $? -ne 0 ]; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to add user '$username' to group '$group'." | tee -a $LOG_FILE
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' added to $group" | tee -a $LOG_FILE
                fi
            fi
        else
            groupadd "$group"
            if [ $? -ne 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to create Group '$group'." | tee -a $LOG_FILE
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - '$group' successfully created." | tee -a $LOG_FILE
            fi
            usermod -aG "$group" "$username"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' added to newly created $group" | tee -a $LOG_FILE
        fi
    done
}

while IFS=';' read -r user groups || [[ -n "$user" ]]; do
    user=$(echo "$user" | sed 's/ //g')
    groups=$(echo "$groups" | sed 's/ //g')
    create_user $user
    user_groups $user $groups
done < "$input_file"

echo "Completed"

Explanation:
Creating Users:
Checks if the user already exists.
Generates and sets a random password.
Creates a home directory with appropriate permissions.
Managing Groups:
Checks if specified groups exist and creates them if not.
Adds the user to specified groups.


Conclusion
By reading a text file containing usernames and their corresponding group names, the script seamlessly creates users and groups as specified. It also sets up home directories with the appropriate permissions and ownership, generates random secure passwords for the users, and logs all actions to /var/log/user_management.log. Additionally, the script ensures the secure storage of generated passwords in /var/secure/user_passwords.txt. This comprehensive automation tool significantly enhances the efficiency and security of the user onboarding process, making it an essential tool for system administrators. 
For more insights into the internship visit the HNG Internship page here(https://hng.tech/internship/) 