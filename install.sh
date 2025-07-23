#!/bin/bash
# A multi-purpose script for installing, uninstalling, or changing the port of the subscription server.
# Version 12.4: Uses APT to install Python packages, complying with PEP 668 on modern systems.

set -e

# --- Variables ---
GITHUB_REPO_URL="https://raw.githubusercontent.com/2amir563/khodamneveshtammyusersub/main"
INSTALL_DIR="/opt/sub_server"
SERVICE_NAME="subscription"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# --- Functions ---

function install_service() {
    echo ">>> Starting All-in-One Subscription Server Setup..."

    read -p "Please enter the port for the service [default: 2096]: " APP_PORT
    APP_PORT=${APP_PORT:-2096}
    
    # این بخش برای پرسیدن پورت SSH اضافه شده تا از قفل شدن جلوگیری شود
    read -p "Please enter your SSH port [default: 22]: " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    echo "--> Service will run on port: $APP_PORT"
    echo "--> SSH port is set to: $SSH_PORT"

    echo "--> Updating system and installing dependencies..."
    sudo apt-get update
    # --- تغییر اصلی ۱: نصب تمام پکیج‌ها با apt ---
    # این روش با اوبونتو ۲۰، ۲۲ و ۲۴ سازگار است
    sudo apt-get install -y python3-flask python3-gunicorn ufw

    echo "--> Creating installation directory at $INSTALL_DIR..."
    sudo mkdir -p $INSTALL_DIR

    echo "--> Downloading application files from GitHub..."
    sudo curl -sL "$GITHUB_REPO_URL/sub_server.py" -o "$INSTALL_DIR/sub_server.py"
    echo "from sub_server import app" | sudo tee "$INSTALL_DIR/wsgi.py" > /dev/null

    echo "--> Downloading and setting up systemd service..."
    sudo curl -sL "$GITHUB_REPO_URL/subscription.service" -o "$SERVICE_FILE"
    sudo sed -i "s/PORT_PLACEHOLDER/$APP_PORT/g" "$SERVICE_FILE"
    sudo sed -i "s|WorkingDirectory=/opt/sub_server/|WorkingDirectory=$INSTALL_DIR/|g" "$SERVICE_FILE"
    # --- تغییر اصلی ۲: استفاده از مسیر صحیح gunicorn ---
    # مسیر gunicorn نصب شده با apt همیشه استاندارد است و معمولاً gunicorn3 نام دارد
    # این دستور هم با نسخه های قدیمی و هم جدید سازگار است
    if [ -f /usr/bin/gunicorn3 ]; then
        sudo sed -i "s|ExecStart=/usr/bin/gunicorn|ExecStart=/usr/bin/gunicorn3|g" "$SERVICE_FILE"
    else
        sudo sed -i "s|ExecStart=/usr/bin/gunicorn|ExecStart=/usr/bin/gunicorn|g" "$SERVICE_FILE"
    fi

    echo "--> Configuring firewall (UFW)..."
    echo "y" | sudo ufw reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow $SSH_PORT/tcp
    sudo ufw allow $APP_PORT/tcp
    # اضافه کردن لیست پورت‌های پیش‌فرض
    PREDEFINED_PORTS="13289 2095 2096 2090 2091 80 443 2054 2053 22"
    for port in $PREDEFINED_PORTS; do
        sudo ufw allow $port
    done
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
}

# (توابع دیگر بدون تغییر باقی می‌مانند)

function uninstall_service() {
    echo ">>> Starting Uninstallation Process..."
    if [ ! -f "$SERVICE_FILE" ]; then echo "--> Service file not found. It seems the service is not installed."; exit 0; fi
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

function change_port() {
    echo ">>> Starting Port Change Process..."
    if [ ! -f "$SERVICE_FILE" ]; then echo "--> Service file not found. You must install the service first."; exit 1; fi
    CURRENT_PORT=$(grep -oP '(?<=--bind 0.0.0.0:)[0-9]+' $SERVICE_FILE || echo "")
    if [[ -z "$CURRENT_PORT" ]]; then echo "--> Could not detect the current port. Aborting."; exit 1; fi
    echo "--> Current port is: $CURRENT_PORT"
    read -p "Please enter the NEW port you want to use: " NEW_PORT
    if [[ -z "$NEW_PORT" ]]; then echo "--> No new port entered. Aborting."; exit 1; fi
    echo "--> Updating service file to use port $NEW_PORT..."
    sudo sed -i "s/--bind 0.0.0.0:$CURRENT_PORT/--bind 0.0.0.0:$NEW_PORT/g" "$SERVICE_FILE"
    echo "--> Updating firewall rules..."
    sudo ufw delete allow $CURRENT_PORT/tcp
    sudo ufw allow $NEW_PORT/tcp
    echo "Firewall updated."
    echo "--> Reloading and restarting the service..."
    sudo systemctl daemon-reload
    sudo systemctl restart ${SERVICE_NAME}.service
    echo ""
    echo "========================================="
    echo "===      Port Change Complete!        ==="
    echo "========================================="
    echo "Service has been successfully moved from port $CURRENT_PORT to $NEW_PORT."
}

function main() {
    case "$1" in
        install|'')
            install_service
            ;;
        uninstall)
            uninstall_service
            ;;
        changeport)
            change_port
            ;;
        *)
            echo "Error: Invalid argument."
            echo "Usage: $0 {install|uninstall|changeport}"
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"
