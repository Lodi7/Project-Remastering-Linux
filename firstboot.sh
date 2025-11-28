#!/bin/bash

# ===== Fungsi warna =====
HIJAU='\033[0;32m'
SIAU='\033[0;36m'
BIRU_CERAH='\033[1;34m'  
NC='\033[0m'

# ===== Banner ASCII LOS =====
clear
echo -e "${BIRU_CERAH}"
echo "░▒▓█▓▒░      ░▒▓██████▓▒░ ░▒▓███████▓▒░ ";
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        ";
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        ";
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░  ";
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░ ";
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░ ";
echo "░▒▓████████▓▒░▒▓██████▓▒░░▒▓███████▓▒░  ";
echo ""
echo "       Selamat datang di LOS!"
echo "Mohon tunggu sebentar, sistem akan dikonfigurasi untuk penggunaan pertama."
echo "Beberapa pengaturan dan folder akan dibuat secara otomatis."
echo -e "${NC}"
sleep 1

# ===== Langkah 1: Update & Upgrade Sistem =====
echo -e "${SIAU}[1/5] Mohon tunggu sebentar, memperbarui dan meng-upgrade sistem...${NC}"
apt-get update && apt-get -y upgrade
apt-get -y autoremove && apt-get -y autoclean
echo -e "${HIJAU}[OK] Sistem LOS telah diperbarui!${NC}"
sleep 0.5

# ===== Langkah 2: Konfigurasi Git =====
echo -e "${SIAU}[2/5] Mohon tunggu sebentar, mengatur Git...${NC}"
read -p "Masukkan Nama Git Anda: " GIT_NAME
read -p "Masukkan Email Git Anda: " GIT_EMAIL
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo -e "${HIJAU}[OK] Git berhasil dikonfigurasi!${NC}"
sleep 0.5

# ===== Langkah 3: Tambahkan User ke Grup Docker =====
TARGET_USER=${SUDO_USER:-$(whoami)}
echo -e "${SIAU}[3/5] Mohon tunggu sebentar, menambahkan user '$TARGET_USER' ke grup Docker...${NC}"
# Pastikan grup docker sudah ada di chroot
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker
    echo -e "${HIJAU}[OK] Grup Docker dibuat!${NC}"
fi
usermod -aG docker "$TARGET_USER"
echo -e "${HIJAU}[OK] User '$TARGET_USER' berhasil ditambahkan ke grup Docker!${NC}"
sleep 0.5

# ===== Langkah 4: Buat folder VS Code dan settings.json =====
echo -e "${SIAU}[4/6] Membuat VS Code User settings...${NC}"
VSCODE_DIR="/home/$TARGET_USER/.config/Code/User"
sudo -u $TARGET_USER mkdir -p "$VSCODE_DIR"
sudo -u $TARGET_USER tee "$VSCODE_DIR/settings.json" > /dev/null <<'EOF'
{
  "workbench.startupEditor": "none",
  "workbench.sideBar.location": "right",
  "editor.fontSize": 20,
  "editor.lineHeight": 2.2,
  "editor.mouseWheelZoom": true,
  "workbench.iconTheme": "vscode-icons",
  "workbench.colorTheme": "One Dark Pro Night Flat",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.cursorStyle": "line",
  "editor.cursorBlinking": "smooth",
  "editor.formatOnSave": true,
  "files.autoSave": "off",
  "code-runner.runInTerminal": true,
  "code-runner.fileDirectoryAsCwd": true,
  "code-runner.saveFileBeforeRun": true,
  "python.defaultInterpreterPath": "/usr/bin/python3",
  "C_Cpp.default.compilerPath": "/usr/bin/gcc",
  "python.terminal.executeInFileDir": true,
  "python.autoComplete.extraPaths": [],
  "code-runner.executorMapByFileExtension": {
    ".py": "python3",
    ".c": "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
    ".cpp": "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
    ".java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
    ".js": "node",
    ".ts": "ts-node",
    ".sh": "bash"
  },
  "files.associations": {
    "*.py": "python",
    "*.c": "c",
    "*.cpp": "cpp",
    "*.java": "java",
    "*.js": "javascript"
  },
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash"
    },
    "zsh": {
      "path": "/usr/bin/zsh"
    }
  },
  "git.enabled": true,
  "editor.renderWhitespace": "all",
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.minimap.enabled": false
}
EOF
echo -e "${HIJAU}[OK] VS Code settings siap digunakan!${NC}"
sleep 0.5

# ===== Langkah 5: Buat Workspace =====
echo -e "${SIAU}[5/6] Membuat folder workspace...${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Workspace
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Projects
echo -e "${HIJAU}[OK] Folder workspace siap digunakan!${NC}"
sleep 0.5

# ===== Langkah 6: Finish & Cleanup =====
echo -e "${SIAU}[6/6] Menyelesaikan konfigurasi...${NC}"
if [ -f /home/$TARGET_USER/.config/autostart/firstboot.desktop ]; then
    rm -f /home/$TARGET_USER/.config/autostart/firstboot.desktop
fi
echo -e "${HIJAU}[OK] First boot setup LOS selesai!${NC}"
sleep 0.5

# ===== Banner Selesai =====
echo -e "${BIRU_CERAH}"
echo "==========================================================="
echo "                 First boot LOS selesai!"
echo " Silakan logout/login atau restart agar grup Docker aktif."
echo "==========================================================="
echo -e "${NC}"
