#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
# آدرس ریپازیتوری گیت‌هاب خود را اینجا وارد کنید
GITHUB_REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main"
# پوشه نصب برنامه
INSTALL_DIR="/opt/sub_server"

echo ">>> Starting All-in-One Subscription Server Setup..."

# --- Step 1: Update System and Install Dependencies ---
echo "--> Updating system and installing dependencies (python, pip, gunicorn, ufw)..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip gunicorn ufw

# --- Step 2: Create Directory and Download Files ---
echo "--> Creating installation directory at $INSTALL_DIR..."
sudo mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo "--> Downloading application files from GitHub..."
sudo curl -sL "$GITHUB_REPO_URL/sub_server.py" -o "$INSTALL_DIR/sub_server.py"

# --- Step 3: Create WSGI Entry Point ---
echo "--> Creating WSGI entry point..."
echo "from sub_server import app" | sudo tee "$INSTALL_DIR/wsgi.py" > /dev/null

# --- Step 4: Setup Systemd Service ---
echo "--> Downloading and setting up systemd service..."
sudo curl -sL "$GITHUB_REPO_URL/subscription.service" -o "/etc/systemd/system/subscription.service"
# Replace the default working directory in the service file
sudo sed -i "s|WorkingDirectory=/opt/sub_server/|WorkingDirectory=$INSTALL_DIR/|g" /etc/systemd/system/subscription.service
sudo sed -i "s|ExecStart=/usr/bin/gunicorn|ExecStart=$(which gunicorn)|g" /etc/systemd/system/subscription.service


# --- Step 5: Setup Firewall ---
echo "--> Configuring firewall (UFW)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh # Allow SSH connections
sudo ufw allow 8080/tcp # Allow app port
echo "y" | sudo ufw enable

# --- Step 6: Start and Enable the Service ---
echo "--> Starting and enabling the subscription service..."
sudo systemctl daemon-reload
sudo systemctl start subscription.service
sudo systemctl enable subscription.service

echo ""
echo "================================================================="
echo "===                  Setup Complete!                          ==="
echo "================================================================="
echo ""
echo "Your subscription server is now running."
echo "You can check its status with: sudo systemctl status subscription.service"
echo ""
echo "Your subscription link format is:"
echo "http://YOUR_SERVER_IP:8080/<username>"
echo ""
