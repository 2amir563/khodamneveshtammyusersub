#!/bin/bash
# A multi-purpose script for installing or uninstalling the subscription server.
# Usage:
#   - To install: ./install.sh install  (or just ./install.sh)
#   - To uninstall: ./install.sh uninstall

set -e

# --- Variables ---
# آدرس ریپازیتوری گیت‌هاب خود را اینجا وارد کنید
GITHUB_REPO_URL="https://raw.githubusercontent.com/2amir563/khodamneveshtammyusersub/main"
INSTALL_DIR="/opt/sub_server"
SERVICE_NAME="subscription"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# --- Functions ---

function install_service() {
    echo ">>> Starting All-in-One Subscription Server Setup..."

    read -p "Please enter the port for the service [default: 2096]: " APP_PORT
    APP_PORT=${APP_PORT:-2096}
    echo "--> The service will be configured on port: $APP_PORT"

    echo "--> Updating system and installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip gunicorn ufw

    echo "--> Creating installation directory at $INSTALL_DIR..."
    sudo mkdir -p $INSTALL_DIR

    echo "--> Downloading application files from GitHub..."
    sudo curl -sL "$GITHUB_REPO_URL/sub_server.py" -o "$INSTALL_DIR/sub_server.py"
    echo "from sub_server import app" | sudo tee "$INSTALL_DIR/wsgi.py" > /dev/null

    echo "--> Downloading and setting up systemd service..."
    sudo curl -sL "$GITHUB_REPO_URL/subscription.service" -o "$SERVICE_FILE"
    sudo sed -i "s/PORT_PLACEHOLDER/$APP_PORT/g" "$SERVICE_FILE"
    sudo sed -i "s|WorkingDirectory=/opt/sub_server/|WorkingDirectory=$INSTALL_DIR/|g" "$SERVICE_FILE"
    sudo sed -i "s|ExecStart=/usr/bin/gunicorn|ExecStart=$(which gunicorn)|g" "$SERVICE_FILE"

    echo "--> Configuring firewall (UFW)..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow $APP_PORT/tcp
    echo "y" | sudo ufw enable

    echo "--> Starting and enabling the subscription service..."
    sudo systemctl daemon-reload
    sudo systemctl start ${SERVICE_NAME}.service
    sudo systemctl enable ${SERVICE_NAME}.service

    echo ""
    echo "================================================================="
    echo "===                  Setup Complete!                          ==="
    echo "================================================================="
    echo "Your subscription server is now running on port $APP_PORT."
    echo "To check status, run: sudo systemctl status $SERVICE_NAME"
    echo "Your subscription link format is: http://YOUR_SERVER_IP:$APP_PORT/<username>"
}

function uninstall_service() {
    echo ">>> Starting Uninstallation Process..."

    # هوشمندانه پورت را از فایل سرویس پیدا می‌کند
    PORT_TO_CLOSE=$(grep -oP '(?<=--bind 0.0.0.0:)[0-9]+' $SERVICE_FILE || echo "")

    echo "--> Stopping and disabling the systemd service..."
    sudo systemctl stop ${SERVICE_NAME}.service || true
    sudo systemctl disable ${SERVICE_NAME}.service || true
    echo "Service stopped and disabled."

    echo "--> Removing the systemd service file..."
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload
    echo "Service file removed."

    echo "--> Removing the application directory..."
    sudo rm -rf $INSTALL_DIR
    echo "Application directory removed."

    if [[ ! -z "$PORT_TO_CLOSE" ]]; then
        echo "--> Deleting firewall rule for automatically detected port $PORT_TO_CLOSE..."
        sudo ufw delete allow $PORT_TO_CLOSE/tcp
        echo "Firewall rule removed."
    else
        echo "--> Could not detect port. Please remove firewall rule manually if needed."
    fi

    echo ""
    echo "========================================="
    echo "===      Uninstallation Complete!     ==="
    echo "========================================="
}

function main() {
    if [[ -z "$1" || "$1" == "install" ]]; then
        install_service
    elif [[ "$1" == "uninstall" ]]; then
        uninstall_service
    else
        echo "Error: Invalid argument."
        echo "Usage: $0 {install|uninstall}"
        exit 1
    fi
}

# Run the main function
main "$@"
