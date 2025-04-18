#!/bin/bash

# === Colors ===
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
YELLOW='\e[33m'
NC='\e[0m'  # No color

LOG_FILE="project_log.txt"
# Dependencies needed for the script
DEPENDENCIES=("sshpass" "curl" "nmap" "whois" "perl" "tor")

# 1.1 Install the needed applications.
function install_dependencies() {
	user=$(whoami)
    if [ "$user" == "root" ]; then
        echo -e "${GREEN}✔ You are root.. continuing..${NC}"                                # Works with root only.
    else
        echo -e "${RED}✘ You are not root.. exiting...${NC}"
        exit
    fi
    for package in "${DEPENDENCIES[@]}"; do
        dpkg -s "$package" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}[*] Installing $package...${NC}"
            sudo apt-get install "$package" -y >/dev/null 2>&1 | tee -a "$LOG_FILE"
            if [ $? -eq 0 ]; then                                        # 1.2 If the applications are already installed, don’t install them again.
                echo -e "${GREEN}[✔] $package installed.${NC}" | tee -a "$LOG_FILE"
            else
                echo -e "${RED}[!] Failed to install $package.${NC}"
            fi
        else
            echo -e "${GREEN}[✔] $package is already installed.${NC}"
        fi
    done
}

# Function to install and configure Nipe
function install_nipe() {
    if [ ! -d "./.nipe" ]; then
        echo -e "${YELLOW}[*] Installing Nipe...${NC}"
        git clone https://github.com/htrgouvea/nipe .nipe >/dev/null 2>&1
        cd .nipe || { echo -e "${RED}[!] Failed to enter the Nipe directory.${NC}"; return 37; }
        cd ..
        echo -e "${GREEN}[✔] Nipe installed successfully.${NC}"
    else
        echo -e "${GREEN}[✔] Nipe is already installed.${NC}"
    fi
}

# Function to check and enable anonymity using Nipe
function check_anonymity() {
    echo -e "${BLUE}[*] Starting Nipe...${NC}" | tee -a "$LOG_FILE"
    cd .nipe || exit
    sudo perl nipe.pl start 2>&1 | tee -a "$LOG_FILE"

	nipe=$(sudo perl nipe.pl status)
    nipe_status=$(echo "$nipe" | grep -i "true")                         # 1.3 Check if the network connection is anonymous; if not, alert the user and exit.

    if [[ -n "$nipe_status" ]]; then
        echo -e "${GREEN}[✔] Nipe is active. Verifying anonymity...${NC}" | tee -a "$LOG_FILE"
        
        # Extract spoofed IP
        spoofed_ip=$(echo "$nipe" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        
        # Get spoofed country
        if [[ -n "$spoofed_ip" ]]; then
            spoofed_country=$(geoiplookup "$spoofed_ip")                 # 1.4 If the network connection is anonymous, display the spoofed country name.
            echo -e "${YELLOW}🌍 Your spoofed IP is: $spoofed_ip${NC}" | tee -a "$LOG_FILE"
            echo -e "${YELLOW}🌐 Your spoofed country is: $spoofed_country${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}[!] Failed to retrieve spoofed IP.${NC}" | tee -a "$LOG_FILE"
        fi
        
        cd ..
    else
        echo -e "${RED}[!] Nipe failed to activate. You are not anonymous.${NC}" | tee -a "$LOG_FILE"
        cd ..
        exit 1
    fi
}

# Function to connect to a remote server and execute commands
function remote_operations() {
	    read -p "Enter the remote server IP address: " REMOTE_IP
    read -p "Enter the username for the remote server: " USERNAME
    echo "Enter the password for the remote server:"
    read -s PASSWORD
    read -p "Enter the target address to scan: " TARGET_ADDRESS              # 1.5 Allow the user to specify the address to scan via remote server; save into a variable.
    log "Remote server: $REMOTE_IP"
    log "Username: $USERNAME"
    log "Target address: $TARGET_ADDRESS"

    echo -e "${BLUE} Testing SSH connection...${NC}"
    sshpass -p "$PASSWORD" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USERNAME@$REMOTE_IP" "exit" 
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[✘] SSH connection to $REMOTE_IP failed. Check IP, credentials, or network.${NC}"
        exit 1
    else
        echo -e "${GREEN}[✔] SSH connection successful. Proceeding with remote tasks.${NC}"
    fi
    echo -e "${BLUE}[*] Connecting to the remote server...${NC}"

    # 2. Automatically Connect and Execute Commands on the Remote Server via SSH
    # 2.1 Display the details of the remote server (country, IP, and Uptime).
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$REMOTE_IP" "
        echo 'Remote Server Details:';
        echo 'Country: ' \$(curl -s ipinfo.io/country);
        echo 'Public IP: ' \$(curl -s ifconfig.me);
        echo 'Uptime: ' \$(uptime -p);
        
        echo 'Performing Whois on $TARGET_ADDRESS...';
        whois '$TARGET_ADDRESS' > ~/whois.txt;
        
        echo 'Scanning $TARGET_ADDRESS with Nmap...';
        nmap -oN ~/nmap.txt '$TARGET_ADDRESS' >/dev/null 2>&1 ;
    " | tee -a "$LOG_FILE"

    echo -e "${BLUE}[*] Retrieving results from the remote server...${NC}"
    sshpass -p "$PASSWORD" scp "$USERNAME@$REMOTE_IP:~/whois.txt" ./whois.txt 
    sshpass -p "$PASSWORD" scp "$USERNAME@$REMOTE_IP:~/nmap.txt" ./nmap.txt 
    echo -e "${YELLOW}[*] Removing txt files from remote server...${NC}" 
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$REMOTE_IP" "rm -rf ~/whois.txt ~/nmap.txt"
    log "Whois and Nmap results retrieved and deleted from remote server."
}

# Function to log actions
function log() {
    LOG_FILE="project_log.txt"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Main script flow
echo -e "${BLUE}==========================================="
echo -e "  Remote Control & Anonymized "
echo -e " Network Reconnaissance Script"
echo -e "===========================================${NC}"

echo -e "${BLUE} Starting the script...${NC}"
install_dependencies
log "Dependencies checked and installed."

install_nipe
log "Nipe installed and configured."

check_anonymity
log "Anonymity check completed using Nipe."

remote_operations
log "Remote operations and data collection (whois and nmap) completed."  # 3.2 Create a log and audit your data collecting.

echo -e "${BLUE} Please provide path+name of the output directory (e.g., /home/kali/Desktop/REMOTE_CONTROL)${NC}"
read OUTPUT_DIR
mkdir -p "$OUTPUT_DIR"
[[ -f "project_log.txt" ]] && mv project_log.txt "$OUTPUT_DIR/"
[[ -f "whois.txt" ]] && mv whois.txt "$OUTPUT_DIR/"
[[ -f "nmap.txt" ]] && mv nmap.txt "$OUTPUT_DIR/"

echo -e "${GREEN}[✔] Script completed successfully. Logs saved in: $OUTPUT_DIR/project_log.txt${NC}"


