#!/bin/bash
# ===== Fungsi warna =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ===== Banner ASCII =====
clear
echo -e "${MAGENTA}"
echo "============================================"
echo "        Welcome to LOS Setup"
echo "============================================"
echo -e "${NC}"
sleep 1

# ===== Step 1: Update & Upgrade Sistem =====
echo -e "${CYAN}[1/5] Updating & upgrading system...${NC}"
apt update && apt -y upgrade
apt -y autoremove && apt -y autoclean
echo -e "${GREEN}[OK] System updated!${NC}"
sleep 0.5

# ===== Step 2: Konfigurasi Git =====
echo -e "${CYAN}[2/5] Setting up Git...${NC}"
read -p "Enter your Git Name: " GIT_NAME
read -p "Enter your Git Email: " GIT_EMAIL
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo -e "${GREEN}[OK] Git configured for $(whoami)!${NC}"
sleep 0.5

# ===== Step 3: Tambahkan User ke Grup Docker =====
TARGET_USER=${SUDO_USER:-$(whoami)}
echo -e "${CYAN}[3/5] Adding user '$TARGET_USER' to docker group...${NC}"
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker
    echo -e "${GREEN}[OK] Docker group created!${NC}"
fi
usermod -aG docker "$TARGET_USER"
echo -e "${GREEN}[OK] User '$TARGET_USER' added to docker group!${NC}"
sleep 0.5

# ===== Step 4: Buat Workspace & Shortcut =====
echo -e "${CYAN}[4/5] Creating workspace and shortcuts...${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Workspace
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Projects

# Shortcut VS Code jika terinstall
if [ -f /usr/bin/code ]; then
    sudo -u $TARGET_USER ln -sf /usr/bin/code /home/$TARGET_USER/Desktop/VSCode
fi
echo -e "${GREEN}[OK] Workspace & shortcuts ready!${NC}"
sleep 0.5

# ===== Step 5: Finish & Cleanup =====
echo -e "${CYAN}[5/5] Finalizing setup...${NC}"
# Nonaktifkan service first boot
if [ -f /etc/systemd/system/firstboot.service ]; then
    systemctl disable firstboot.service
    rm -f /etc/systemd/system/firstboot.service
fi
echo -e "${GREEN}[OK] First boot setup complete!${NC}"
sleep 0.5

# ===== Banner Selesai =====
echo -e "${MAGENTA}"
echo "============================================"
echo "     First Boot Finished Successfully!"
echo "  Logout/Login to activate Docker group"
echo "============================================"
echo -e "${NC}"
