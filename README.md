# Remote-Control
# 🚀 Remote Control & Anonymized Network Reconnaissance Script

## 📌 Overview
This **Bash script** automates **remote reconnaissance** while ensuring **anonymity** using `Nipe` (Tor-based traffic routing).  
It performs **dependency installation, anonymity verification, remote command execution, and data collection** via `Whois` and `Nmap`.  

## 🔥 Features
✔ **Automated Dependency Installation** – Installs `sshpass`, `curl`, `nmap`, `whois`, `perl` if not already installed.  
✔ **Ensures Anonymity with Nipe** – Routes traffic through Tor before scanning.  
✔ **Remote Reconnaissance via SSH** – Connects to a remote server, executes commands, and retrieves results.  
✔ **Data Collection & Logging** – Stores Whois & Nmap results in a user-defined directory.  
✔ **Secure Cleanup** – Deletes temporary files from the remote machine after execution.  

---

## 🛠️ Installation & Setup

### **1️⃣ Clone the Repository**
```bash
git clone https://github.com/Remote-Control.git
cd ./Remote-Control
chmod +x remotecontrol.sh
2️⃣ Install Dependencies
The script automatically installs required dependencies.
You can manually install them using:
sudo apt update
sudo apt install sshpass curl nmap whois perl -y
git clone https://github.com/htrgouvea/nipe .nipe
🚀 Usage

sudo ./remotecontrol.sh
#!/bin/bash


LOG_FILE="project_log.txt"
# Dependencies needed for the script
DEPENDENCIES=("sshpass" "curl" "nmap" "whois" "perl")

# 1.1 Install the needed applications.
function install_dependencies() {
	user=$(whoami)
    if [ "$user" == "root" ]; then
        echo "You are root.. continuing.."                                # Works with root only.
    else
        echo "You are not root.. exiting..."
        exit
    fi
    for package in "${DEPENDENCIES[@]}"; do
        dpkg -s "$package" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Installing $package..."
            sudo apt-get install "$package" -y >/dev/null 2>&1 | tee -a "$LOG_FILE"
            if [ $? -eq 0 ]; then                                        #1.2 If the applications are already installed, don’t install them again.
                echo "[*] $package installed." | tee -a "$LOG_FILE"
            else
                echo "[!] Failed to install $package."
            fi
        else
            echo "[*] $package is already installed."
        fi
    done
}

# Function to install and configure Nipe
function install_nipe() {
    if [ ! -d "./.nipe" ]; then
        echo "[*] Installing Nipe..."
        git clone https://github.com/htrgouvea/nipe .nipe >/dev/null 2>&1
        cd .nipe || { echo "[!] Failed to enter the Nipe directory."; return 37; }
        cd ..
        echo "[*] Nipe installed successfully."
    else
        echo "[*] Nipe is already installed."
    fi
}

# Function to check and enable anonymity using Nipe
function check_anonymity() {
    echo "[*] Starting Nipe..." | tee -a "$LOG_FILE"
    cd .nipe || exit
    sudo perl nipe.pl start 2>&1 | tee -a "$LOG_FILE"

	nipe=$(sudo perl nipe.pl status)
    nipe_status=$(echo "$nipe" | grep -i "true")                         #1.3 Check if the network connection is anonymous; if not, alert the user and exit.

    if [[ -n "$nipe_status" ]]; then
        echo "[*] Nipe is active. Verifying anonymity..." | tee -a "$LOG_FILE"
        
        # Extract spoofed IP
        spoofed_ip=$(echo "$nipe" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
        
        # Get spoofed country
        if [[ -n "$spoofed_ip" ]]; then
            spoofed_country=$(geoiplookup "$spoofed_ip")                 #1.4 If the network connection is anonymous, display the spoofed country name.
            echo "Your spoofed IP is: $spoofed_ip" | log "Your spoofed IP is: $spoofed_ip"
            echo "Your spoofed country is: $spoofed_country" | log "Your spoofed country is: $spoofed_country"
        else
            echo "[!] Failed to retrieve spoofed IP." | tee -a "$LOG_FILE"
        fi
        
        cd ..
    else
        echo "[!] Nipe failed to activate. You are not anonymous." | tee -a "$LOG_FILE"
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
    read -p "Enter the target address to scan: " TARGET_ADDRESS          #1.5 Allow the user to specify the address to scan via remote server; save into a variable.
    log "Remote server: $REMOTE_IP"
    log "Username: $USERNAME"
    log "Target address: $TARGET_ADDRESS"
   echo "[*] Connecting to the remote server..."
#2. Automatically Connect and Execute Commands on the Remote Server via SSH
#2.1 Display the details of the remote server (country, IP, and Uptime).
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$REMOTE_IP" "
    echo 'Remote Server Details:';
    echo 'Country: ' \$(curl -s ipinfo.io/country);
    echo 'Public IP: ' \$(curl -s ifconfig.me);
    echo 'Uptime: ' \$(uptime -p);
    
    echo 'Performing Whois on $TARGET_ADDRESS...';
    whois '$TARGET_ADDRESS' > ~/whois.txt;
    
    echo 'Scanning $TARGET_ADDRESS with Nmap...';
    nmap -oN ~/nmap.txt '$TARGET_ADDRESS'
"

echo "[*] Retrieving results from the remote server..."
sshpass -p "$PASSWORD" scp "$USERNAME@$REMOTE_IP:~/whois.txt" ./whois.txt 
sshpass -p "$PASSWORD" scp "$USERNAME@$REMOTE_IP:~/nmap.txt" ./nmap.txt 
echo "Removing txt files from remote server..." 
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$REMOTE_IP" "rm -rf ~/whois.txt ~/nmap.txt"
log "Whois and Nmap results retrieved and deleted from remote server."
#2.2 Get the remote server to check the Whois of the given address.
#2.3 Get the remote server to scan for open ports on the given address.
#3.1 Save the Whois and Nmap data into files on the local computer.
}

# Function to log actions
function log() {
    LOG_FILE="project_log.txt"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Main script flow
echo "Starting the script..."
install_dependencies
log "Dependencies checked and installed."

install_nipe
log "Nipe installed and configured."

check_anonymity
log "Anonymity check completed using Nipe."

remote_operations
log "Remote operations and data collection(whois and nmap) completed."                                #3.2 Create a log and audit your data collecting.
echo "Please provide path+name of the output directory (e.g., /home/kali/Desktop/REMOTE_CONTROL)"
read OUTPUT_DIR
mkdir -p "$OUTPUT_DIR"
[[ -f "project_log.txt" ]] && mv project_log.txt "$OUTPUT_DIR/"
[[ -f "whois.txt" ]] && mv whois.txt "$OUTPUT_DIR/"
[[ -f "nmap.txt" ]] && mv nmap.txt "$OUTPUT_DIR/"

echo "Script completed successfully. Logs saved in: $OUTPUT_DIR/project_log.txt"

⚠ This script must be run as root because Nipe requires privileged access.

Step-by-Step Execution
1️⃣ Checks if running as root (exits if not).
2️⃣ Installs necessary tools (sshpass, curl, nmap, whois, perl).
3️⃣ Ensures anonymity using Nipe (Tor-based traffic routing).
4️⃣ Prompts for remote server details (IP, username, password, target address).
5️⃣ Executes Whois and Nmap scans on the target from the remote machine.
6️⃣ Retrieves and saves results in a user-defined directory.

📂 Output & Logs
The script saves execution logs and collected data in an output directory:

Execution logs → project_log.txt
Whois results → whois.txt
Nmap scan results → nmap.txt
By default, the script prompts you to specify an output directory.

⚠️ Disclaimer
🚨 This script is intended for educational and ethical penetration testing purposes only.
🚨 Use it only on networks and systems you have explicit permission to test.
🚨 The author is not responsible for any misuse of this tool.

🛠️ Troubleshooting
🔹 Issue: "Nipe failed to activate"
✅ Ensure you have perl installed and run:

bash
Copy
Edit
cd .nipe && sudo perl nipe.pl install && sudo perl nipe.pl start
🔹 Issue: "Could not resolve host" while cloning GitHub repo
✅ Check your internet connection or try changing your DNS to Google:

bash
Copy
Edit
sudo nano /etc/resolv.conf
Add:

nginx
Copy
Edit
nameserver 8.8.8.8
nameserver 8.8.4.4
Save and restart networking.

📜 License
This project is licensed under the MIT License – you are free to use and modify it. See LICENSE for details.

✨ Author
👤 EvaRoy
