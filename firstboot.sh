#!/bin/bash

# ===== Fungsi warna =====
HIJAU='\033[0;32m'
CYAN='\033[0;36m'
BIRU_CERAH='\033[1;34m'
KUNING='\033[1;33m'
NC='\033[0m'
MERAH='\033[0;31m'

TARGET_USER=${SUDO_USER:-$(whoami)}

# ===== Fungsi Loading Animation =====
show_loading() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1} ${message}...${NC}"
        sleep 0.1
    done
    printf "\r${HIJAU}${message} selesai!${NC}\n"
}

# Fungsi loading untuk command dengan output
loading_exec() {
    local message=$1
    shift
    local command="$@"
    
    echo -ne "${CYAN}⏳ ${message}...${NC}"
    
    # Jalankan command dan capture output
    local output
    output=$($command 2>&1)
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "\r${HIJAU}${message} selesai!${NC}                    "
        return 0
    else
        echo -e "\r${MERAH}${message} gagal!${NC}                      "
        echo -e "${KUNING}Detail error: $output${NC}"
        return 1
    fi
}

# Fungsi progress bar
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] ${percentage}%% - ${message}${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# ===== Error Handler =====
set -o pipefail

error_exit() {
    echo -e "${MERAH}ERROR: $1${NC}" >&2
    echo -e "${KUNING}Terminal akan tertutup dalam 10 detik...${NC}"
    read -t 10
    exit 1
}

# ===== Banner ASCII LOS =====
clear
echo -e "${BIRU_CERAH}"
echo "░▒▓█▓▒░      ░▒▓██████▓▒░ ░▒▓███████▓▒░ "
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        "
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░        "
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░  "
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░ "
echo "░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░ "
echo "░▒▓████████▓▒░▒▓██████▓▒░░▒▓███████▓▒░  "
echo ""
echo -e "${KUNING}       Selamat datang di LOS!${NC}"
echo -e "${NC}Mohon tunggu sebentar, sistem akan dikonfigurasi untuk penggunaan pertama."
echo ""
sleep 1

# ===== Cek Koneksi Internet dengan Retry & Loading =====
echo -e "${CYAN}Memeriksa Koneksi Internet...${NC}"
echo ""

MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo -ne "${CYAN}Percobaan $(($RETRY_COUNT + 1))/$MAX_RETRIES - Ping ke 8.8.8.8...${NC}"
    
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "\r${HIJAU}Koneksi internet tersedia!${NC}                              "
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo -e "\r${KUNING}Percobaan $RETRY_COUNT gagal, mencoba lagi...${NC}              "
        sleep 2
    else
        error_exit "Tidak ada koneksi internet setelah $MAX_RETRIES percobaan!"
    fi
done

echo ""
sleep 0.5

# ===== Langkah 1: Update & Upgrade Sistem =====
echo -e "${CYAN}[1/7] Memperbarui dan meng-upgrade sistem...${NC}"

# Update repository + install xdotool (silent)
(
    apt-get update > /tmp/apt-update.log 2>&1

    if ! command -v xdotool &> /dev/null; then
        apt-get install -y xdotool > /dev/null 2>&1
    fi
) &
show_loading $! "Memperbarui daftar paket"

if [ $? -ne 0 ]; then
    error_exit "Gagal update repository"
fi

echo ""
echo -e "${CYAN}Ditemukan paket-paket yang bisa di-upgrade.${NC}"
echo -e "${CYAN}Proses upgrade dapat memakan waktu beberapa menit.${NC}"
echo ""
read -p "$(echo -e ${KUNING})Apakah Anda ingin meng-upgrade sistem sekarang? (y/n): $(echo -e ${NC})" DO_UPGRADE
DO_UPGRADE=${DO_UPGRADE:-y}

if [[ "$DO_UPGRADE" =~ ^[Yy]$ ]]; then
    echo ""
    
    # Hitung jumlah paket yang akan di-upgrade
    UPGRADE_COUNT=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    
    if [ $UPGRADE_COUNT -gt 0 ]; then
        echo -e "${CYAN}Akan meng-upgrade $UPGRADE_COUNT paket...${NC}"
        echo ""

        (
            apt-get -y upgrade > /dev/null 2>&1
        ) &
        show_loading $! "Meng-upgrade sistem"

    else
        echo -e "${HIJAU}Sistem sudah up-to-date!${NC}"
    fi
else
    echo ""
    echo -e "${KUNING}Upgrade sistem dilewati.${NC}"
    echo -e "${CYAN}Anda bisa upgrade manual nanti dengan: ${NC}sudo apt upgrade${NC}"
fi

echo ""

# Cleanup
(
    apt-get -y autoremove > /dev/null 2>&1
    apt-get -y autoclean > /dev/null 2>&1
) &
show_loading $! "Membersihkan paket yang tidak diperlukan"
echo -e "\r${HIJAU}Cleanup selesai!${NC}                                    "

echo ""
sleep 0.5

# ===== Langkah 2: Konfigurasi Git =====
echo -e "${CYAN}[2/7] Mengatur Git...${NC}"
while true; do
    read -p "$(echo -e ${KUNING})Masukkan Nama Git Anda: $(echo -e ${NC})" GIT_NAME
    if [ -n "$GIT_NAME" ]; then
        break
    else
        echo -e "${MERAH}Nama tidak boleh kosong!${NC}"
    fi
done

while true; do
    read -p "$(echo -e ${KUNING})Masukkan Email Git Anda: $(echo -e ${NC})" GIT_EMAIL
    if [[ "$GIT_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        echo -e "${MERAH}Format email tidak valid!${NC}"
    fi
done

echo ""
echo -ne "${CYAN}Mengkonfigurasi Git...${NC}"

git config --global user.name "$GIT_NAME" > /dev/null 2>&1 || error_exit "Gagal konfigurasi Git name"
git config --global user.email "$GIT_EMAIL" > /dev/null 2>&1 || error_exit "Gagal konfigurasi Git email"

echo -e "\r${HIJAU}Git berhasil dikonfigurasi!${NC}                    "
echo -e "${CYAN}  ├─ Nama : $GIT_NAME${NC}"
echo -e "${CYAN}  └─ Email: $GIT_EMAIL${NC}"
echo ""
sleep 0.5

# ===== Langkah 3: Tambahkan User ke Grup Docker =====
echo -e "${CYAN}[3/7] Menambahkan user '$TARGET_USER' ke grup Docker...${NC}"
# Cek grup docker
if ! getent group docker > /dev/null 2>&1; then
    echo -ne "${CYAN}Membuat grup Docker...${NC}"
    groupadd docker > /dev/null 2>&1 || error_exit "Gagal membuat grup Docker"
    echo -e "\r${HIJAU}Grup Docker dibuat!${NC}                    "
fi

# Tambahkan user
echo -ne "${CYAN}Menambahkan user '$TARGET_USER' ke grup Docker...${NC}"
usermod -aG docker "$TARGET_USER" > /dev/null 2>&1 || error_exit "Gagal menambahkan user ke grup Docker"
echo -e "\r${HIJAU}User '$TARGET_USER' ditambahkan ke grup Docker!${NC}                              "

echo ""
sleep 0.5

# ===== Cek phpMyAdmin Existing untuk User Baru =====
PHPMYADMIN_EXISTS=false
PHPMYADMIN_USER=""
PHPMYADMIN_PASS_SET=false
PHPMYADMIN_DB=""

echo -ne "${CYAN}Memeriksa phpMyAdmin yang sudah ada...${NC}"

if dpkg -l | grep -q phpmyadmin && systemctl is-active --quiet mariadb 2>/dev/null; then
    PHPMYADMIN_EXISTS=true
    echo -e "\r${HIJAU}phpMyAdmin terdeteksi di sistem!${NC}                              "
    echo ""
    echo -e "${KUNING}==================================================${NC}"
    echo -e "${KUNING}         phpMyAdmin Terdeteksi di Sistem!${NC}"
    echo -e "${KUNING}==================================================${NC}"
    echo ""
    echo -e "${CYAN}phpMyAdmin sudah terinstall di sistem ini.${NC}"
    echo -e "${CYAN}Apakah Anda ingin membuat akun database untuk user '$TARGET_USER'?${NC}"
    echo ""
    read -p "$(echo -e ${KUNING})Buat akun database sekarang? (y/n): $(echo -e ${NC})" CREATE_DB_USER
    CREATE_DB_USER=${CREATE_DB_USER:-y}
    
    if [[ "$CREATE_DB_USER" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Membuat akun database untuk Anda...${NC}"
        echo ""
        
        # Input username database
        while true; do
            read -p "$(echo -e ${KUNING})Username database: $(echo -e ${NC})" DB_USER
            if [ -n "$DB_USER" ] && [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
                break
            else
                echo -e "${MERAH}Username harus alfanumerik dan underscore saja!${NC}"
            fi
        done
        
        # Input password database
        while true; do
            read -s -p "$(echo -e ${KUNING})Password database: $(echo -e ${NC})" DB_PASS
            echo ""
            if [ -n "$DB_PASS" ] && [ ${#DB_PASS} -ge 6 ]; then
                read -s -p "$(echo -e ${KUNING})Konfirmasi password: $(echo -e ${NC})" DB_PASS_CONFIRM
                echo ""
                if [ "$DB_PASS" = "$DB_PASS_CONFIRM" ]; then
                    break
                else
                    echo -e "${MERAH}Password tidak cocok! Silakan coba lagi.${NC}"
                fi
            else
                echo -e "${MERAH}Password minimal 6 karakter!${NC}"
            fi
        done
        
        # Pilih level akses
        echo ""
        echo -e "${KUNING}Pilih level akses database:${NC}"
        echo -e "${CYAN}  1) Full Access - Bisa kelola semua database${NC}"
        echo -e "${CYAN}  2) Limited Access - Hanya database pribadi${NC}"
        echo ""
        read -p "$(echo -e ${KUNING})Pilihan (1/2): $(echo -e ${NC})" ACCESS_LEVEL
        ACCESS_LEVEL=${ACCESS_LEVEL:-1}
        
        echo ""
        echo -ne "${CYAN}Membuat akun database '$DB_USER'...${NC}"
        
        if [ "$ACCESS_LEVEL" = "1" ]; then
            # Full access
            mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
            
            if [ $? -eq 0 ]; then
                echo -e "\r${HIJAU}Akun database berhasil dibuat dengan full access!${NC}                    "
                PHPMYADMIN_USER="$DB_USER"
                PHPMYADMIN_PASS_SET=true
            else
                echo -e "\r${MERAH}Gagal membuat akun database!${NC}                                         "
                echo -e "${KUNING}User mungkin sudah ada. Anda bisa login dengan akun existing.${NC}"
            fi
            
        elif [ "$ACCESS_LEVEL" = "2" ]; then
            # Limited access
            DB_NAME="${DB_USER}_db"
            
            mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
            
            if [ $? -eq 0 ]; then
                echo -e "\r${HIJAU}Akun database dan database '$DB_NAME' berhasil dibuat!${NC}                    "
                PHPMYADMIN_USER="$DB_USER"
                PHPMYADMIN_PASS_SET=true
                PHPMYADMIN_DB="$DB_NAME"
            else
                echo -e "\r${MERAH}Gagal membuat akun database!${NC}                                               "
                echo -e "${KUNING}User mungkin sudah ada. Anda bisa login dengan akun existing.${NC}"
            fi
        fi
        
        echo ""
    else
        echo -e "${KUNING}Melewati pembuatan akun database.${NC}"
        echo ""
    fi
else
    echo -e "\r${CYAN}phpMyAdmin belum terinstall di sistem${NC}                              "
fi

echo ""
sleep 0.5

# ===== Langkah 4: Instalasi Package Tambahan =====
# ===== Deteksi Paket yang Sudah Terinstall =====
echo -e "${CYAN}Mendeteksi paket yang sudah terinstall...${NC}"

FRONTEND_INSTALLED=false
BACKEND_INSTALLED=false
MOBILE_INSTALLED=false
GAME_INSTALLED=false
DATASCIENCE_INSTALLED=false
DEVOPS_INSTALLED=false

# Progress bar untuk scanning
TOTAL_CHECKS=6
current=0

# Cek Frontend
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning Frontend tools"
if command -v yarn &> /dev/null && (command -v sassc &> /dev/null || command -v sass &> /dev/null); then
    FRONTEND_INSTALLED=true
fi

# Cek Backend
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning Backend tools"
if command -v php &> /dev/null && command -v composer &> /dev/null && systemctl is-active --quiet mariadb 2>/dev/null; then
    BACKEND_INSTALLED=true
fi

# Cek Mobile Dev
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning Mobile Dev tools"
if command -v flutter &> /dev/null && command -v adb &> /dev/null; then
    MOBILE_INSTALLED=true
fi

# Cek Game Dev
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning Game Dev tools"
if command -v godot3 &> /dev/null || dpkg -l | grep -q libsdl2-dev; then
    GAME_INSTALLED=true
fi

# Cek Data Science
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning Data Science tools"
if dpkg -l | grep -q python3-numpy && dpkg -l | grep -q python3-pandas; then
    DATASCIENCE_INSTALLED=true
fi

# Cek DevOps
current=$((current + 1))
show_progress $current $TOTAL_CHECKS "Scanning DevOps tools"
if command -v ansible &> /dev/null || command -v terraform &> /dev/null; then
    DEVOPS_INSTALLED=true
fi

echo ""
echo -e "${HIJAU}Scanning selesai!${NC}"
echo ""
sleep 0.5

# ===== Menu Paket Development =====
echo -e "${CYAN}[4/7] Pilih paket tambahan sesuai bidang development:${NC}"
echo ""
echo -e "${KUNING}  0)${NC} Default (tanpa paket tambahan)"
echo -e "${NC}       -> python3,gcc,node.js,java,git,docker,Vscode"

# Frontend
if [ "$FRONTEND_INSTALLED" = true ]; then
    echo -e "${KUNING}  1)${NC} Web Dev - Frontend ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  1)${NC} Web Dev - Frontend"
fi
echo -e "${NC}       -> yarn, sassc/sass"

# Backend
if [ "$BACKEND_INSTALLED" = true ]; then
    echo -e "${KUNING}  2)${NC} Web Dev - Backend ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  2)${NC} Web Dev - Backend"
fi
echo -e "${NC}       -> php, composer, mariadb-server, apache2, phpMyAdmin"

# Fullstack
if [ "$FRONTEND_INSTALLED" = true ] && [ "$BACKEND_INSTALLED" = true ]; then
    echo -e "${KUNING}  3)${NC} Fullstack ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  3)${NC} Fullstack"
fi
echo -e "${NC}       -> Frontend + Backend + phpMyAdmin"

# Mobile Dev
if [ "$MOBILE_INSTALLED" = true ]; then
    echo -e "${KUNING}  4)${NC} Mobile Dev (Flutter + Android) ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  4)${NC} Mobile Dev (Flutter + Android)"
fi
echo -e "${NC}       -> flutter(manual), adb, android-sdk"

# Game Dev
if [ "$GAME_INSTALLED" = true ]; then
    echo -e "${KUNING}  5)${NC} Game Dev ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  5)${NC} Game Dev"
fi
echo -e "${NC}       -> godot3, libsdl2-dev, libsdl2-image-dev, libsdl2-mixer-dev, libsdl2-ttf-dev"

# Data Science
if [ "$DATASCIENCE_INSTALLED" = true ]; then
    echo -e "${KUNING}  6)${NC} Data Science & ML ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  6)${NC} Data Science & ML"
fi
echo -e "${NC}       -> numpy, pandas, scikit-learn, matplotlib, seaborn, jupyter-notebook, scipy"

# DevOps
if [ "$DEVOPS_INSTALLED" = true ]; then
    echo -e "${KUNING}  7)${NC} DevOps & Automation ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  7)${NC} DevOps & Automation"
fi
echo -e "${NC}       -> ansible, terraform, kubectl, helm, nginx, apache2-utils"

echo ""
read -p "$(echo -e ${BIRU_CERAH})Masukkan pilihan paket (pisahkan spasi jika lebih dari satu, misal 1 2 6): $(echo -e ${NC})" -a CHOICES
echo ""

# ===== Fungsi Install yang Lebih Robust dengan Progress =====
install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0
    local FAILED_PACKAGES=""
    
    echo -e "${CYAN}Menginstall ${total} paket...${NC}"
    echo ""
    
    for pkg in "${packages[@]}"; do
        current=$((current + 1))
        
        # Cek apakah sudah terinstall
        if dpkg -l | grep -q "^ii.*$pkg "; then
            echo -e "${HIJAU}[$current/$total] $pkg ${CYAN}(sudah terinstall)${NC}"
            continue
        fi
        
        echo -ne "${CYAN}[$current/$total] Installing $pkg...${NC}"
        
        if apt-get install -y "$pkg" > /tmp/install-$pkg.log 2>&1; then
            echo -e "\r${HIJAU}[$current/$total] $pkg berhasil diinstall${NC}                              "
        else
            echo -e "\r${MERAH}[$current/$total] $pkg gagal diinstall${NC}                                "
            FAILED_PACKAGES="$FAILED_PACKAGES $pkg"
        fi
    done
    
    echo ""
    
    if [ -n "$FAILED_PACKAGES" ]; then
        echo -e "${KUNING}Paket yang gagal diinstall:$FAILED_PACKAGES${NC}"
        echo -e "${CYAN}Anda bisa mencoba install manual nanti.${NC}"
        echo ""
    else
        echo -e "${HIJAU}Semua paket berhasil diinstall!${NC}"
        echo ""
    fi
}

# ===== Fungsi Install Yarn dengan GPG Key & Progress =====
install_yarn_repo() {
    echo -e "${CYAN}Menambahkan repository Yarn...${NC}"
    
    if command -v yarn &> /dev/null; then
        echo -e "${HIJAU}Yarn sudah terinstall, melewati...${NC}"
        echo ""
        return 0
    fi
    
    # Install curl
    if ! command -v curl &> /dev/null; then
        echo -ne "${CYAN}Menginstall curl...${NC}"
        apt-get install -y curl > /dev/null 2>&1 || {
            echo -e "\r${MERAH}Gagal install curl${NC}                              "
            return 1
        }
        echo -e "\r${HIJAU}curl berhasil diinstall${NC}                              "
    fi
    
    # Tambah GPG key
    echo -ne "${CYAN}Menambahkan GPG key Yarn...${NC}"
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "\r${HIJAU}GPG key Yarn berhasil ditambahkan${NC}                              "
        
        # Tambah repository
        echo -ne "${CYAN}Menambahkan repository Yarn...${NC}"
        echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list > /dev/null
        
        # Update repo
        apt-get update > /dev/null 2>&1 || {
            echo -e "\r${MERAH}Gagal update repo Yarn${NC}                              "
            return 1
        }
        echo -e "\r${HIJAU}Repository Yarn berhasil ditambahkan${NC}                              "
        echo ""
    else
        echo -e "\r${MERAH}Gagal menambahkan GPG key Yarn${NC}                              "
        return 1
    fi
}

# ===== Fungsi Install Sass dengan Fallback =====
install_sass_tools() {
    echo -e "${CYAN}Menginstall Sass compilers...${NC}"
    
    # Coba install sassc (LibSass)
    echo -ne "${CYAN}Menginstall sassc (LibSass)...${NC}"
    if apt-get install -y sassc libsass1 > /dev/null 2>&1; then
        echo -e "\r${HIJAU}sassc (LibSass) berhasil diinstall${NC}                              "
        echo ""
        return 0
    else
        echo -e "\r${KUNING}sassc gagal, mencoba alternatif...${NC}                              "
    fi
    
    # Alternatif: Install dart-sass via npm
    if command -v npm &> /dev/null; then
        echo -ne "${CYAN}Menginstall sass via npm...${NC}"
        npm install -g sass > /dev/null 2>&1 && {
            echo -e "\r${HIJAU}sass (Dart Sass) berhasil diinstall via npm${NC}                              "
            echo ""
            return 0
        }
    fi
    
    echo ""
    echo -e "${KUNING}Sass compiler tidak bisa diinstall otomatis${NC}"
    echo -e "${CYAN}Cara manual: ${NC}npm install -g sass${NC}"
    echo ""
    return 1
}

# ===== Fungsi Install Flutter dan Android Tools (TANPA SNAP) =====
install_flutter_mobile() {
    echo -e "${CYAN}Menginstall paket Mobile Development...${NC}"
    
    # 1. Install dependencies
    echo -e "${CYAN}Menginstall dependencies...${NC}"
    install_packages curl git unzip xz-utils zip libglu1-mesa adb android-sdk-platform-tools-common
    
    # 2. Download dan install Flutter manual
    echo -e "${CYAN}Menginstall Flutter...${NC}"
    
    FLUTTER_DIR="/opt/flutter"
    FLUTTER_VERSION="stable"
    
    if [ -d "$FLUTTER_DIR" ]; then
        echo -e "${KUNING}Flutter sudah ada di $FLUTTER_DIR${NC}"
        read -p "$(echo -e ${KUNING})Hapus dan install ulang? (y/n): $(echo -e ${NC})" REINSTALL
        if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
            echo -ne "${CYAN}Menghapus Flutter lama...${NC}"
            rm -rf "$FLUTTER_DIR"
            echo -e "\r${HIJAU}Flutter lama berhasil dihapus${NC}                              "
        else
            echo -e "${HIJAU}Menggunakan Flutter yang sudah ada${NC}"
            
            # Setup PATH jika belum ada
            if ! command -v flutter &> /dev/null; then
                echo 'export PATH="$PATH:/opt/flutter/bin"' >> /home/$TARGET_USER/.bashrc
                export PATH="$PATH:/opt/flutter/bin"
            fi
            return 0
        fi
    fi
    
    # Deteksi arsitektur
    echo -ne "${CYAN}Mendeteksi arsitektur sistem...${NC}"
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz"
        FLUTTER_FILE="flutter_linux_x64.tar.xz"
        echo -e "\r${HIJAU}Arsitektur: x86_64 (AMD64)${NC}                              "
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_arm64_3.24.5-stable.tar.xz"
        FLUTTER_FILE="flutter_linux_arm64.tar.xz"
        echo -e "\r${HIJAU}Arsitektur: ARM64${NC}                              "
    else
        echo -e "\r${MERAH}Arsitektur $ARCH tidak didukung${NC}                              "
        return 1
    fi
    
    echo ""

    # Download Flutter dengan progress bar
    cd /tmp
    
    echo -e "${CYAN}Mendownload Flutter SDK (~600MB)...${NC}"
    echo -e "${KUNING}Ini mungkin memakan waktu beberapa menit...${NC}"
    echo ""
    
    # Download dengan wget progress
    wget --progress=bar:force:noscroll -O "$FLUTTER_FILE" "$FLUTTER_URL" 2>&1 | \
    while IFS= read -r line; do
        if [[ "$line" =~ ([0-9]+)% ]]; then
            percent="${BASH_REMATCH[1]}"
            # Progress bar manual
            completed=$((percent / 2))
            remaining=$((50 - completed))
            printf "\r${CYAN}["
            printf "%${completed}s" | tr ' ' '█'
            printf "%${remaining}s" | tr ' ' '░'
            printf "] ${percent}%%${NC}"
        fi
    done
    
    echo ""
    
    # Cek apakah download berhasil
    if [ ! -f "$FLUTTER_FILE" ]; then
        echo -e "${MERAH}Download Flutter SDK gagal!${NC}"
        return 1
    fi
    
    echo -e "${HIJAU}Download Flutter SDK selesai!${NC}"
    echo ""
    
    # Extract Flutter
    echo -ne "${CYAN}Mengekstrak Flutter SDK (tunggu sebentar)...${NC}"
    
    tar xf "$FLUTTER_FILE" -C /opt/ 2>&1 | while read line; do
        echo -ne "."
    done
    
    if [ $? -eq 0 ]; then
        echo -e "\r${HIJAU}Flutter SDK berhasil diekstrak!${NC}                                          "
    else
        echo -e "\r${MERAH}Gagal ekstrak Flutter SDK${NC}                                          "
        rm -f "$FLUTTER_FILE"
        return 1
    fi
    
    # Cleanup file download
    echo -ne "${CYAN}Membersihkan file download...${NC}"
    rm -f "$FLUTTER_FILE"
    echo -e "\r${HIJAU}File download dihapus (~600MB freed)${NC}                              "
    
    # Set permissions
    echo -ne "${CYAN}Mengatur permissions...${NC}"
    chown -R $TARGET_USER:$TARGET_USER /opt/flutter
    echo -e "\r${HIJAU}Permissions berhasil diatur${NC}                              "
    echo ""
    
    echo -ne "${CYAN}Menambahkan Flutter ke PATH...${NC}"
    if ! grep -q "/opt/flutter/bin" /home/$TARGET_USER/.bashrc; then
        echo 'export PATH="$PATH:/opt/flutter/bin"' >> /home/$TARGET_USER/.bashrc
    fi
    export PATH="$PATH:/opt/flutter/bin"
    echo -e "\r${HIJAU}Flutter berhasil ditambahkan ke PATH${NC}                              "
    
    echo ""
    
    # Jalankan flutter precache
    echo -e "${CYAN}Mendownload Flutter dependencies...${NC}"
    echo -e "${KUNING}Ini akan memakan waktu beberapa menit...${NC}"
    echo ""
    
    # Jalankan dengan progress
    sudo -u $TARGET_USER /opt/flutter/bin/flutter precache --linux 2>&1 | \
    while IFS= read -r line; do
        if [[ "$line" =~ Downloading ]]; then
            file=$(echo "$line" | awk '{print $2}')
            echo -ne "\r${CYAN}Downloading: $file...${NC}                                        "
        elif [[ "$line" =~ "Flutter" ]]; then
            echo -e "\r${HIJAU}Flutter precache selesai!${NC}                                          "
        fi
    done
    
    echo ""
    echo -e "${HIJAU}Flutter SDK berhasil diinstall!${NC}"
    echo ""

    # 3. Install Android SDK
    echo -e "${KUNING}Apakah Anda ingin install Android SDK lengkap?${NC}"
    echo -e "${CYAN}Diperlukan untuk build aplikasi Android (ukuran ~2GB)${NC}"
    echo ""
    read -p "$(echo -e ${KUNING})Install Android SDK? (y/n): $(echo -e ${NC})" INSTALL_ANDROID_SDK
    
    if [[ "$INSTALL_ANDROID_SDK" =~ ^[Yy]$ ]]; then
        echo ""
        
        ANDROID_SDK_DIR="/home/$TARGET_USER/Android/Sdk"
        ANDROID_TOOLS_FILE="commandlinetools-linux.zip"
        
        echo -ne "${CYAN}Membuat direktori Android SDK...${NC}"
        sudo -u $TARGET_USER mkdir -p "$ANDROID_SDK_DIR/cmdline-tools"
        echo -e "\r${HIJAU}Direktori Android SDK dibuat${NC}                              "
        
        cd /tmp
        
        echo ""
        echo -e "${CYAN}Mendownload Android Command Line Tools...${NC}"
        echo ""
        
        wget --progress=bar:force:noscroll -O "$ANDROID_TOOLS_FILE" \
        https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip 2>&1 | \
        while IFS= read -r line; do
            if [[ "$line" =~ ([0-9]+)% ]]; then
                percent="${BASH_REMATCH[1]}"
                completed=$((percent / 2))
                remaining=$((50 - completed))
                printf "\r${CYAN}["
                printf "%${completed}s" | tr ' ' '█'
                printf "%${remaining}s" | tr ' ' '░'
                printf "] ${percent}%%${NC}"
            fi
        done

        echo ""
        
        if [ -f "$ANDROID_TOOLS_FILE" ]; then
            echo ""
            echo -ne "${CYAN}Mengekstrak Android Command Line Tools...${NC}"
            
            sudo -u $TARGET_USER unzip -q "$ANDROID_TOOLS_FILE" -d "$ANDROID_SDK_DIR/cmdline-tools/"
            sudo -u $TARGET_USER mv "$ANDROID_SDK_DIR/cmdline-tools/cmdline-tools" "$ANDROID_SDK_DIR/cmdline-tools/latest"
            
            echo -e "\r${HIJAU}Android Command Line Tools berhasil diekstrak${NC}                              "
            
            # Cleanup
            echo -ne "${CYAN}Membersihkan file download Android SDK...${NC}"
            rm -f "$ANDROID_TOOLS_FILE"
            echo -e "\r${HIJAU}File download dihapus (~150MB freed)${NC}                              "
            
            # Setup Android SDK PATH
            echo -ne "${CYAN}Menambahkan Android SDK ke PATH...${NC}"
            if ! grep -q "ANDROID_HOME" /home/$TARGET_USER/.bashrc; then
                cat >> /home/$TARGET_USER/.bashrc <<'ANDROID_ENV'
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
ANDROID_ENV
            fi
            echo -e "\r${HIJAU}Android SDK berhasil ditambahkan ke PATH${NC}                              "
            
            echo ""
            echo -e "${HIJAU}Android Command Line Tools berhasil diinstall!${NC}"
            echo ""
            echo -e "${KUNING}Note: Jalankan command berikut setelah restart terminal:${NC}"
            echo -e "${CYAN}   flutter doctor --android-licenses${NC}"
            echo ""
        else
            echo -e "${MERAH}Download Android Command Line Tools gagal!${NC}"
            rm -f "$ANDROID_TOOLS_FILE"
        fi
    else
        echo -e "${KUNING}Skip Android SDK installation${NC}"
        echo ""
    fi
    
    # CLEANUP FINAL
    echo -ne "${CYAN}Membersihkan semua file temporary...${NC}"
    cd /tmp
    rm -f flutter*.tar.xz commandlinetools*.zip 2>/dev/null
    echo -e "\r${HIJAU}Cleanup selesai!${NC}                              "
    
    echo ""
    echo -e "${HIJAU}[OK] Flutter Mobile Dev selesai diinstall!${NC}"
    echo ""
    echo -e "${KUNING}=== PENTING: Restart terminal atau jalankan: ===${NC}"
    echo -e "${CYAN}source ~/.bashrc${NC}"
    echo ""
    echo -e "${KUNING}Kemudian jalankan untuk cek status:${NC}"
    echo -e "${CYAN}flutter doctor -v${NC}"
    echo ""
}

# ===== Fungsi Konfigurasi phpMyAdmin =====
configure_phpmyadmin() {
    echo -e "${CYAN}Mengkonfigurasi phpMyAdmin...${NC}"
    
    # Start MariaDB
    echo -ne "${CYAN}Memeriksa status MariaDB...${NC}"
    if ! systemctl is-active --quiet mariadb; then
        systemctl start mariadb || {
            echo -e "\r${MERAH}Gagal start MariaDB${NC}                              "
            return 1
        }
        echo -e "\r${HIJAU}MariaDB berhasil distart${NC}                              "
    else
        echo -e "\r${HIJAU}MariaDB sudah running${NC}                              "
    fi
    
    echo -ne "${CYAN}Enable MariaDB autostart...${NC}"
    systemctl enable mariadb > /dev/null 2>&1
    echo -e "\r${HIJAU}MariaDB autostart enabled${NC}                              "
    
    # Buat symbolic link
    echo -ne "${CYAN}Membuat symbolic link phpMyAdmin...${NC}"
    if [ -L /var/www/html/phpmyadmin ]; then
        rm -f /var/www/html/phpmyadmin
    fi
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    echo -e "\r${HIJAU}Symbolic link berhasil dibuat${NC}                              "
    
    # Enable konfigurasi Apache
    echo -ne "${CYAN}Mengkonfigurasi Apache untuk phpMyAdmin...${NC}"
    if [ -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
        a2enconf phpmyadmin > /dev/null 2>&1
    else
        # Buat konfigurasi manual
        cat > /etc/apache2/conf-available/phpmyadmin.conf <<'PHPCONF'
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    Require all granted
</Directory>

<Directory /usr/share/phpmyadmin/templates>
    Require all denied
</Directory>
<Directory /usr/share/phpmyadmin/libraries>
    Require all denied
</Directory>
PHPCONF
        a2enconf phpmyadmin > /dev/null 2>&1
    fi
    echo -e "\r${HIJAU}Apache untuk phpMyAdmin berhasil dikonfigurasi${NC}                              "
    
    # Start Apache
    echo -ne "${CYAN}Memeriksa status Apache2...${NC}"
    if ! systemctl is-active --quiet apache2; then
        systemctl start apache2 || {
            echo -e "\r${MERAH}Gagal start Apache2${NC}                              "
            return 1
        }
        echo -e "\r${HIJAU}Apache2 berhasil distart${NC}                              "
    else
        echo -e "\r${HIJAU}Apache2 sudah running${NC}                              "
    fi
    
    echo -ne "${CYAN}Enable Apache2 autostart...${NC}"
    systemctl enable apache2 > /dev/null 2>&1
    echo -e "\r${HIJAU}Apache2 autostart enabled${NC}                              "
    
    echo -ne "${CYAN}Reload Apache2 configuration...${NC}"
    systemctl reload apache2 > /dev/null 2>&1
    echo -e "\r${HIJAU}Apache2 configuration reloaded${NC}                              "
    
    echo ""
    echo -e "${HIJAU}phpMyAdmin berhasil dikonfigurasi!${NC}"
    echo ""
    
    # Buat akun database
    echo ""
    echo -e "${KUNING}=================================================${NC}"
    echo -e "${KUNING}    Buat Akun Database untuk Login phpMyAdmin${NC}"
    echo -e "${KUNING}=================================================${NC}"
    echo ""
    
    while true; do
        read -p "$(echo -e ${KUNING})Username database: $(echo -e ${NC})" DB_USER
        if [ -n "$DB_USER" ] && [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
            break
        else
            echo -e "${MERAH}Username harus alfanumerik dan underscore!${NC}"
        fi
    done
    
    while true; do
        read -s -p "$(echo -e ${KUNING})Password database: $(echo -e ${NC})" DB_PASS
        echo ""
        if [ -n "$DB_PASS" ] && [ ${#DB_PASS} -ge 6 ]; then
            read -s -p "$(echo -e ${KUNING})Konfirmasi password: $(echo -e ${NC})" DB_PASS_CONFIRM
            echo ""
            if [ "$DB_PASS" = "$DB_PASS_CONFIRM" ]; then
                break
            else
                echo -e "${MERAH}Password tidak cocok!${NC}"
            fi
        else
            echo -e "${MERAH}Password minimal 6 karakter!${NC}"
        fi
    done
    
    echo ""
    echo -e "${KUNING}Pilih level akses:${NC}"
    echo -e "${CYAN}  1) Full Access${NC}"
    echo -e "${CYAN}  2) Limited Access${NC}"
    read -p "$(echo -e ${KUNING})Pilihan (1/2): $(echo -e ${NC})" ACCESS_LEVEL
    ACCESS_LEVEL=${ACCESS_LEVEL:-1}
    
    echo ""
    echo -ne "${CYAN}Membuat akun database '$DB_USER'...${NC}"
    
    if [ "$ACCESS_LEVEL" = "1" ]; then
        mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
        
        if [ $? -eq 0 ]; then
            echo -e "\r${HIJAU}Akun database berhasil dibuat dengan full access!${NC}                    "
            PHPMYADMIN_USER="$DB_USER"
            PHPMYADMIN_PASS_SET=true
        fi
    else
        DB_NAME="${DB_USER}_db"
        mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
        
        if [ $? -eq 0 ]; then
            echo -e "\r${HIJAU}Akun dan database '$DB_NAME' berhasil dibuat!${NC}                    "
            PHPMYADMIN_USER="$DB_USER"
            PHPMYADMIN_PASS_SET=true
            PHPMYADMIN_DB="$DB_NAME"
        fi
    fi
    
    echo ""
}

# ===== Eksekusi Pilihan Multi =====
PHPMYADMIN_INSTALLED=false

if [ "$PHPMYADMIN_EXISTS" = true ]; then
    PHPMYADMIN_INSTALLED=true
fi

echo -e "${CYAN}Memulai Instalasi Paket yang Dipilih...${NC}"
echo ""

for CHOICE in "${CHOICES[@]}"; do
    case $CHOICE in
      0)
        echo -e "${HIJAU}Menggunakan paket default saja${NC}"
        echo ""
        ;;
        
      1)
        if [ "$FRONTEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Frontend sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi Frontend Development Tools${NC}"
            echo ""
            
            install_yarn_repo
            if [ $? -eq 0 ]; then
                install_packages yarn
            fi
            
            install_sass_tools
            
            echo -e "${HIJAU}Frontend Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;
        
      2)
        if [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Backend sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi Backend Development Tools${NC}"
            echo ""
            
            install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
            
            echo ""
            echo -e "${CYAN}Menambahkan repository universe...${NC}"
            add-apt-repository -y universe > /dev/null 2>&1
            
            echo -ne "${CYAN}Update repository...${NC}"
            apt-get update > /dev/null 2>&1
            echo -e "\r${HIJAU}Repository berhasil diupdate${NC}                              "
            
            echo ""
            echo -ne "${CYAN}Menginstall phpMyAdmin...${NC}"
            DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin > /tmp/phpmyadmin-install.log 2>&1
            echo -e "\r${HIJAU}phpMyAdmin berhasil diinstall${NC}                              "
            
            echo ""
            configure_phpmyadmin
            PHPMYADMIN_INSTALLED=true
            
            echo -e "${HIJAU}Backend Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;

        3)
        if [ "$FRONTEND_INSTALLED" = true ] && [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Fullstack sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi Fullstack Development Tools${NC}"
            echo ""
            
            # Frontend
            if [ "$FRONTEND_INSTALLED" = false ]; then
                echo -e "${CYAN}[1/2] Installing Frontend Tools...${NC}"
                echo ""
                install_yarn_repo
                if [ $? -eq 0 ]; then
                    install_packages yarn
                fi
                install_sass_tools
                echo ""
            else
                echo -e "${HIJAU}Frontend tools sudah terinstall${NC}"
                echo ""
            fi
            
            # Backend
            if [ "$BACKEND_INSTALLED" = false ]; then
                echo -e "${CYAN}[2/2] Installing Backend Tools...${NC}"
                echo ""
                install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
                
                echo ""
                echo -ne "${CYAN}Menambahkan repository universe...${NC}"
                add-apt-repository -y universe > /dev/null 2>&1
                apt-get update > /dev/null 2>&1
                echo -e "\r${HIJAU}Repository berhasil diupdate${NC}                              "
                
                echo ""
                echo -ne "${CYAN}Menginstall phpMyAdmin...${NC}"
                DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin > /tmp/phpmyadmin-install.log 2>&1
                echo -e "\r${HIJAU}phpMyAdmin berhasil diinstall${NC}                              "
                
                echo ""
                configure_phpmyadmin
                PHPMYADMIN_INSTALLED=true
            else
                echo -e "${HIJAU}Backend tools sudah terinstall${NC}"
                echo ""
            fi
            
            echo -e "${HIJAU}Fullstack Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;
        
      4)
        if [ "$MOBILE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Mobile Dev sudah terinstall${NC}"
            echo ""
        else
            install_flutter_mobile
        fi
        ;;

        5)
        if [ "$GAME_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Game Dev sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi Game Development Tools${NC}"
            echo ""
            
            install_packages godot3 libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
            
            echo -e "${HIJAU}Game Dev Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;
        
      6)
        if [ "$DATASCIENCE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Data Science sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi Data Science & ML Tools${NC}"
            echo ""
            
            install_packages python3-numpy python3-pandas python3-sklearn python3-matplotlib python3-seaborn jupyter-notebook python3-scipy
            
            echo ""
            echo -e "${KUNING}Install PyTorch (Opsional)${NC}"
            echo ""
            echo -e "${CYAN}PyTorch tidak tersedia di repo apt.${NC}"
            echo -e "${CYAN}Apakah Anda ingin install via pip? (ukuran ~2GB)${NC}"
            echo ""
            read -p "$(echo -e ${KUNING})Install PyTorch? (y/n): $(echo -e ${NC})" INSTALL_TORCH
            
            if [[ "$INSTALL_TORCH" =~ ^[Yy]$ ]]; then
                echo ""
                echo -e "${CYAN}Mendownload & install PyTorch (ini akan lama)...${NC}"
                echo ""
                
                pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu 2>&1 | \
                while IFS= read -r line; do
                    if [[ "$line" =~ Downloading ]]; then
                        package=$(echo "$line" | awk '{print $2}')
                        echo -ne "\r${CYAN}Downloading: $package...${NC}                                        "
                    elif [[ "$line" =~ Installing ]]; then
                        package=$(echo "$line" | awk '{print $2}')
                        echo -ne "\r${CYAN}Installing: $package...${NC}                                        "
                    fi
                done
                
                echo -e "\r${HIJAU}PyTorch berhasil diinstall!${NC}                                          "
                echo ""
            else
                echo -e "${KUNING}Skip PyTorch installation${NC}"
                echo ""
            fi
            
            echo -e "${HIJAU}Data Science Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;
        
      7)
        if [ "$DEVOPS_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] DevOps sudah terinstall${NC}"
            echo ""
        else
            echo -e "${CYAN}Instalasi DevOps & Automation Tools${NC}"
            echo ""
            
            install_packages ansible nginx apache2-utils
            
            echo ""
            echo -e "${KUNING}Info: Terraform & kubectl${NC}"
            echo ""
            echo -e "${CYAN}Terraform & kubectl memerlukan setup repository tambahan.${NC}"
            echo -e "${CYAN}Untuk install manual, kunjungi:${NC}"
            echo -e "${KUNING}  • Terraform: ${NC}https://developer.hashicorp.com/terraform/install"
            echo -e "${KUNING}  • kubectl  : ${NC}https://kubernetes.io/docs/tasks/tools/"
            echo ""
            
            echo -e "${HIJAU}DevOps Tools Berhasil Diinstall!${NC}"
            echo ""
        fi
        ;;
        
      *)
        echo -e "${MERAH}Pilihan tidak valid: $CHOICE${NC}"
        echo ""
        ;;
    esac
done

sleep 1
# ===== Langkah 5: Buat folder VS Code dan settings.json =====
echo -e "${CYAN}[5/7] Menyiapkan VS Code User settings...${NC}"
VSCODE_DIR="/home/$TARGET_USER/.config/Code/User"
sudo -u $TARGET_USER mkdir -p "$VSCODE_DIR" || error_exit "Gagal membuat direktori VS Code"
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

if [ $? -eq 0 ]; then
    echo -e "${HIJAU}[OK] VS Code settings siap digunakan!${NC}"
else
    echo -e "${KUNING}[WARNING] Gagal membuat VS Code settings${NC}"
fi
sleep 0.5

# ===== Langkah 6: Buat Workspace =====
echo ""
echo -e "${CYAN}[6/7] Membuat folder projects dan workspace...${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Workspace || echo -e "${KUNING}[WARNING] Gagal membuat Workspace${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Projects || echo -e "${KUNING}[WARNING] Gagal membuat Projects${NC}"
echo -e "${HIJAU}[OK] Folder projects dan workspace siap digunakan!${NC}"
sleep 0.5

# ===== Langkah 7: Finish & Cleanup =====
echo ""
echo -e "${CYAN}[7/7] Menyelesaikan konfigurasi...${NC}"
if [ -f /home/$TARGET_USER/.config/autostart/firstboot.desktop ]; then
    rm -f /home/$TARGET_USER/.config/autostart/firstboot.desktop
    echo -e "${HIJAU}[OK] File autostart firstboot dihapus!${NC}"
fi
echo -e "${HIJAU}[OK] First boot setup LOS selesai!${NC}"
sleep 0.5

# ===== Banner Selesai =====
echo ""
echo -e "${BIRU_CERAH}===========================================================${NC}"
echo -e "${KUNING}                 First boot LOS selesai!${NC}"
echo -e "${NC} Silakan logout/login atau restart agar grup Docker aktif."

# Tampilkan info phpMyAdmin jika diinstall
if [ "$PHPMYADMIN_INSTALLED" = true ]; then
    echo ""
    echo -e "${CYAN} 🌐 phpMyAdmin sudah siap digunakan!${NC}"
    echo -e "${CYAN}    Akses di: ${KUNING}http://localhost/phpmyadmin${NC}"


    if [ "$PHPMYADMIN_PASS_SET" = true ]; then
        echo -e "${CYAN}    Username: ${KUNING}$PHPMYADMIN_USER${NC}"
        echo -e "${CYAN}    Password: ${KUNING}(password yang Anda buat tadi)${NC}"
        if [ -n "$PHPMYADMIN_DB" ]; then
            echo -e "${CYAN}    Database: ${KUNING}$PHPMYADMIN_DB${NC}"
        fi
    else
        echo -e "${CYAN}    Username: ${KUNING}root${NC}"
        echo -e "${CYAN}    Password: ${KUNING}(kosongkan, tekan Enter)${NC}"
        echo ""
        echo -e "${KUNING} 💡 Tips: Sebaiknya set password root untuk keamanan!${NC}"
        echo -e "${CYAN}    Jalankan: ${NC}sudo mysql_secure_installation${NC}"
    fi
fi

echo -e "${BIRU_CERAH}===========================================================${NC}"
echo -e "${KUNING}Terminal akan tertutup otomatis dalam 5 detik...${NC}"
echo -e "${KUNING}Atau tekan Enter untuk menutup sekarang...${NC}"
echo ""

# Countdown timer dengan option untuk skip
COUNTDOWN=5
while [ $COUNTDOWN -gt 0 ]; do
    echo -ne "${CYAN}Menutup dalam ${COUNTDOWN}...${NC}\r"
    
    # Check if user pressed Enter (non-blocking)
    read -t 1 -n 1 key 2>/dev/null
    if [ $? -eq 0 ]; then
        break
    fi
    
    COUNTDOWN=$((COUNTDOWN - 1))
done

echo -e "\n${HIJAU}Setup selesai!${NC}"
echo -e "${CYAN}Terminal akan tertutup...${NC}"
sleep 2

# Method 1: Tutup terminal dengan cara yang aman (via window manager)
if [ -n "$DISPLAY" ]; then
    # Dapatkan Window ID dari terminal ini
    WINDOW_ID=$(xdotool getactivewindow 2>/dev/null)
    
    if [ -n "$WINDOW_ID" ]; then
        # Tutup window dengan xdotool (cara paling aman)
        xdotool windowkill "$WINDOW_ID" 2>/dev/null &
    else
        # Fallback: tutup parent terminal process
        TERM_PID=$PPID
        # Gunakan SIGTERM (lebih halus dari SIGKILL)
        kill -15 "$TERM_PID" 2>/dev/null &
        sleep 0.5
        # Jika masih hidup, gunakan SIGKILL
        kill -9 "$TERM_PID" 2>/dev/null &
    fi
fi

exit 0
