# Remote-Control
#  🚀 Remote Control & Anonymized Network Reconnaissance Script

## 📌 Overview
This **Bash script** automates **remote reconnaissance** while ensuring **anonymity** using `Nipe` (Tor-based traffic routing).  
It performs **dependency installation, anonymity verification, remote command execution, and data collection** via `Whois` and `Nmap`.  

## 🔥 Features
✔ **Automated Dependency Installation** – Installs `sshpass`, `curl`, `nmap`, `whois`, `perl` if not already installed.  
✔ **Ensures Anonymity with Nipe** – Routes traffic through Tor before scanning.  
✔ **Remote Reconnaissance via SSH** – Connects to a remote server, executes commands, and retrieves results.  
✔ **Data Collection & Logging** – Stores **Whois & Nmap results** in a user-defined directory.  
✔ **Secure Cleanup** – Deletes temporary files from the remote machine after execution.  

---

## 🛠️ Installation & Setup

### **1. Clone the Repository**
```bash
git clone https://github.com/your-repo-name.git
cd ./Remote-Control
chmod +x remotecontrol.sh
2. Install Dependencies
The script automatically installs required dependencies, but you can manually install them:

bash
Copy
Edit
sudo apt update
sudo apt install sshpass curl nmap whois perl -y
git clone https://github.com/htrgouvea/nipe .nipe
cd .nipe
sudo perl nipe.pl start
🚀 Usage
Run the Script
bash
Copy
Edit
sudo ./remotecontrol.sh
⚠ This script must be run as root because Nipe requires privileged access.

Step-by-Step Execution
Checks if running as root (exits if not).
Installs necessary tools (sshpass, curl, nmap, whois, perl).
Ensures anonymity using Nipe (Tor-based traffic routing).
Prompts for remote server details (IP, username, password, target address).
Executes Whois and Nmap scans on the target from the remote machine.
Retrieves and saves results in a user-defined directory.
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
