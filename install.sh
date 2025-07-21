#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
# آدرس ریپازیتوری گیت‌هاب خود را اینجا وارد کنید (مثال شما جایگزین شده)
GITHUB_REPO_URL="https://raw.githubusercontent.com/2amir563/khodamneveshtammyusersub/main"
# پوشه نصب برنامه
INSTALL_DIR="/opt/sub_server"

echo ">>> Starting All-in-One Subscription Server Setup..."

# --- Step 1: Get Port From User ---
# از کاربر پورت را سوال می‌کند. اگر کاربر چیزی وارد نکند و Enter بزند، پورت پیش‌فرض 2096 انتخاب می‌شود
read -p "Please enter the port for the service [default: 2096]: " APP_PORT
APP_PORT=${APP_PORT:-2096}
echo "--> The service will be configured on port: $APP_PORT"

# --- Step 2: Update System and Install Dependencies ---
echo "--> Updating system and installing dependencies (python, pip, gunicorn, ufw)..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip gunicorn ufw

# --- Step 3: Create Directory and Download Files ---
echo "--> Creating installation directory at $INSTALL_DIR..."
sudo mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo "--> Downloading application files from GitHub..."
sudo curl -sL "$GITHUB_REPO_URL/sub_server.py" -o "$INSTALL_DIR/sub_server.py"

# --- Step 4: Create WSGI Entry Point ---
echo "--> Creating WSGI entry point..."
echo "from sub_server import app" | sudo tee "$INSTALL_DIR/wsgi.py" > /dev/null

# --- Step 5: Setup Systemd Service ---
echo "--> Downloading and setting up systemd service..."
sudo curl -sL "$GITHUB_REPO_URL/subscription.service" -o "/etc/systemd/system/subscription.service"

# جایگزین کردن پورت در فایل سرویس با ورودی کاربر
sudo sed -i "s/PORT_PLACEHOLDER/$APP_PORT/g" /etc/systemd/system/subscription.service

# جایگزین کردن مسیرهای دیگر به صورت داینامیک
sudo sed -i "s|WorkingDirectory=/opt/sub_server/|WorkingDirectory=$INSTALL_DIR/|g" /etc/systemd/system/subscription.service
sudo sed -i "s|ExecStart=/usr/bin/gunicorn|ExecStart=$(which gunicorn)|g" /etc/systemd/system/subscription.service

# --- Step 6: Setup Firewall ---
echo "--> Configuring firewall (UFW)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
# باز کردن پورتی که کاربر وارد کرده است
sudo ufw allow $APP_PORT/tcp
echo "y" | sudo ufw enable

# --- Step 7: Start and Enable the Service ---
echo "--> Starting and enabling the subscription service..."
sudo systemctl daemon-reload
sudo systemctl start subscription.service
sudo systemctl enable subscription.service

echo ""
echo "================================================================="
echo "===                  Setup Complete!                          ==="
echo "================================================================="
echo ""
echo "Your subscription server is now running on port $APP_PORT."
echo "You can check its status with: sudo systemctl status subscription.service"
echo ""
echo "Your subscription link format is:"
echo "http://YOUR_SERVER_IP:$APP_PORT/<username>"
echo ""
