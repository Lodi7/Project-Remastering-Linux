#!/bin/bash

# ===== Fungsi warna =====
HIJAU='\033[0;32m'
CYAN='\033[0;36m'  # DIPERBAIKI: dari SIAU menjadi CYAN
BIRU_CERAH='\033[1;34m'
KUNING='\033[1;33m'
NC='\033[0m'
MERAH='\033[0;31m'

TARGET_USER=${SUDO_USER:-$(whoami)}

# ===== Error Handler =====
set -o pipefail  # DITAMBAHKAN: Deteksi error di pipeline

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
echo -e "${NC}Beberapa pengaturan dan folder akan dibuat secara otomatis.${NC}"
echo ""
sleep 1

# ===== Cek Koneksi Internet dengan Retry =====
echo -e "${CYAN}Mengecek koneksi internet...${NC}"
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "${HIJAU}Koneksi OK!${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo -e "${KUNING}Percobaan $RETRY_COUNT gagal, mencoba lagi...${NC}"
        sleep 2
    else
        error_exit "Tidak ada koneksi internet setelah $MAX_RETRIES percobaan!"
    fi
done
echo ""

# ===== Langkah 1: Update & Upgrade Sistem =====
echo -e "${CYAN}[1/8] Memperbarui dan meng-upgrade sistem...${NC}"
apt-get update || error_exit "Gagal update repository"
apt-get -y upgrade || error_exit "Gagal upgrade sistem"
apt-get -y autoremove && apt-get -y autoclean

# Install xdotool untuk auto-close terminal (jika belum ada)
if ! command -v xdotool &> /dev/null; then
    echo -e "${CYAN}Menginstall xdotool...${NC}"
    apt-get install -y xdotool || echo -e "${KUNING}[WARNING] xdotool gagal diinstall${NC}"
fi

echo -e "${HIJAU}[OK] Sistem LOS telah diperbarui!${NC}"
sleep 0.5

# ===== Langkah 2: Konfigurasi Git =====
echo -e "${CYAN}[2/8] Mengatur Git...${NC}"
# DIPERBAIKI: Validasi input
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
    # DITAMBAHKAN: Validasi format email
    if [[ "$GIT_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        echo -e "${MERAH}Format email tidak valid!${NC}"
    fi
done

git config --global user.name "$GIT_NAME" || error_exit "Gagal konfigurasi Git name"
git config --global user.email "$GIT_EMAIL" || error_exit "Gagal konfigurasi Git email"
echo -e "${HIJAU}[OK] Git berhasil dikonfigurasi!${NC}"
sleep 0.5

# ===== Langkah 3: Tambahkan User ke Grup Docker =====
echo -e "${CYAN}[3/8] Menambahkan user '$TARGET_USER' ke grup Docker...${NC}"
# Pastikan grup docker sudah ada
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker || error_exit "Gagal membuat grup Docker"
    echo -e "${HIJAU}[OK] Grup Docker dibuat!${NC}"
fi
usermod -aG docker "$TARGET_USER" || error_exit "Gagal menambahkan user ke grup Docker"
echo -e "${HIJAU}[OK] User '$TARGET_USER' berhasil ditambahkan ke grup Docker!${NC}"
sleep 0.5

# ===== Cek phpMyAdmin Existing untuk User Baru =====
PHPMYADMIN_EXISTS=false
PHPMYADMIN_USER=""
PHPMYADMIN_PASS_SET=false
PHPMYADMIN_DB=""

if dpkg -l | grep -q phpmyadmin && systemctl is-active --quiet mariadb 2>/dev/null; then
    PHPMYADMIN_EXISTS=true
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
            read -p "$(echo -e ${KUNING})Masukkan username database: $(echo -e ${NC})" DB_USER
            # DITAMBAHKAN: Validasi username database
            if [ -n "$DB_USER" ] && [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
                break
            else
                echo -e "${MERAH}Username harus alfanumerik dan underscore saja!${NC}"
            fi
        done
        
        # Input password database
        while true; do
            read -s -p "$(echo -e ${KUNING})Masukkan password database: $(echo -e ${NC})" DB_PASS
            echo ""
            if [ -n "$DB_PASS" ] && [ ${#DB_PASS} -ge 6 ]; then  # DITAMBAHKAN: Minimal 6 karakter
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
        echo -e "${CYAN}Membuat akun database '$DB_USER'...${NC}"
        
        # DIPERBAIKI: Gunakan heredoc untuk keamanan password
        if [ "$ACCESS_LEVEL" = "1" ]; then
            # Full access
            mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
            
            if [ $? -eq 0 ]; then
                echo -e "${HIJAU}[OK] Akun database berhasil dibuat dengan full access!${NC}"
                PHPMYADMIN_USER="$DB_USER"
                PHPMYADMIN_PASS_SET=true
            else
                echo -e "${MERAH}[WARNING] Gagal membuat akun database!${NC}"
                echo -e "${KUNING}User mungkin sudah ada. Anda bisa login dengan akun existing.${NC}"
            fi
            
        elif [ "$ACCESS_LEVEL" = "2" ]; then
            # Limited access - buat database pribadi
            DB_NAME="${DB_USER}_db"
            
            mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
            
            if [ $? -eq 0 ]; then
                echo -e "${HIJAU}[OK] Akun database dan database '$DB_NAME' berhasil dibuat!${NC}"
                PHPMYADMIN_USER="$DB_USER"
                PHPMYADMIN_PASS_SET=true
                PHPMYADMIN_DB="$DB_NAME"
            else
                echo -e "${MERAH}[WARNING] Gagal membuat akun database!${NC}"
                echo -e "${KUNING}User mungkin sudah ada. Anda bisa login dengan akun existing.${NC}"
            fi
        fi
        
        echo ""
    else
        echo -e "${KUNING}[OK] Melewati pembuatan akun database.${NC}"
        echo ""
    fi
fi

# ===== Langkah 4: Instalasi Package Tambahan =====
# ===== Deteksi Paket yang Sudah Terinstall =====
echo -e "${CYAN}Mendeteksi paket yang sudah terinstall...${NC}"

FRONTEND_INSTALLED=false
BACKEND_INSTALLED=false
MOBILE_INSTALLED=false
GAME_INSTALLED=false
DATASCIENCE_INSTALLED=false
DEVOPS_INSTALLED=false

# Cek Frontend (yarn DAN sass tools)
if command -v yarn &> /dev/null && (command -v sassc &> /dev/null || command -v sass &> /dev/null); then
    FRONTEND_INSTALLED=true
fi

# Cek Backend
if command -v php &> /dev/null && command -v composer &> /dev/null && systemctl is-active --quiet mariadb 2>/dev/null; then
    BACKEND_INSTALLED=true
fi

# Cek Mobile Dev - PERBAIKAN: Cek snap dan flutter
if command -v snap &> /dev/null && snap list 2>/dev/null | grep -q flutter && command -v adb &> /dev/null; then
    MOBILE_INSTALLED=true
fi

# Cek Game Dev
if command -v godot3 &> /dev/null || dpkg -l | grep -q libsdl2-dev; then
    GAME_INSTALLED=true
fi

# Cek Data Science
if dpkg -l | grep -q python3-numpy && dpkg -l | grep -q python3-pandas; then
    DATASCIENCE_INSTALLED=true
fi

# Cek DevOps
if command -v ansible &> /dev/null || command -v terraform &> /dev/null; then
    DEVOPS_INSTALLED=true
fi

# ===== Menu Paket Development =====
echo -e "${CYAN}[4/8] Pilih paket tambahan sesuai bidang development:${NC}"
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
echo -e "${NC}       -> snapd, flutter(snap), adb, android-sdk"

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

# ===== Fungsi Install yang Lebih Robust =====
install_packages() {
    echo -e "${CYAN}Menginstall paket: $@${NC}"
    local FAILED_PACKAGES=""
    
    for pkg in "$@"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            echo -e "${HIJAU}✓ $pkg berhasil diinstall${NC}"
        else
            echo -e "${MERAH}✗ $pkg gagal diinstall${NC}"
            FAILED_PACKAGES="$FAILED_PACKAGES $pkg"
        fi
    done
    
    if [ -n "$FAILED_PACKAGES" ]; then
        echo -e "${KUNING}[WARNING] Paket gagal:$FAILED_PACKAGES${NC}"
    fi
}

# ===== Fungsi Install Yarn dengan GPG Key (PERBAIKAN) =====
install_yarn_repo() {
    echo -e "${CYAN}Menambahkan repository Yarn...${NC}"
    
    if command -v yarn &> /dev/null; then
        echo -e "${HIJAU}✓ Yarn sudah terinstall, melewati...${NC}"
        return 0
    fi
    
    # Install curl jika belum ada
    if ! command -v curl &> /dev/null; then
        apt-get install -y curl || {
            echo -e "${MERAH}[ERROR] Gagal install curl${NC}"
            return 1
        }
    fi
    
    # Tambah GPG key dan repo
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list > /dev/null
        apt-get update || {
            echo -e "${MERAH}[ERROR] Gagal update repo Yarn${NC}"
            return 1
        }
        echo -e "${HIJAU}✓ Repository Yarn berhasil ditambahkan${NC}"
    else
        echo -e "${MERAH}[ERROR] Gagal menambahkan GPG key Yarn${NC}"
        return 1
    fi
}

# ===== Fungsi Install Sass (PERBAIKAN untuk dart-sass) =====
install_sass_tools() {
    echo -e "${CYAN}Menginstall Sass compilers...${NC}"
    
    # Coba install sassc (LibSass)
    if apt-get install -y sassc libsass1 2>/dev/null; then
        echo -e "${HIJAU}✓ sassc (LibSass) berhasil diinstall${NC}"
        return 0
    else
        echo -e "${KUNING}! sassc gagal, mencoba alternatif...${NC}"
    fi
    
    # Alternatif: Install dart-sass via npm (lebih reliable)
    if command -v npm &> /dev/null; then
        echo -e "${CYAN}Menginstall sass via npm...${NC}"
        npm install -g sass 2>/dev/null && {
            echo -e "${HIJAU}✓ sass (Dart Sass) berhasil diinstall via npm${NC}"
            return 0
        }
    fi
    
    echo -e "${KUNING}[WARNING] Sass compiler tidak bisa diinstall, Anda bisa install manual nanti${NC}"
    echo -e "${CYAN}Cara manual: npm install -g sass${NC}"
    return 1
}

# ===== Fungsi Install Snapd dan Flutter (PERBAIKAN) =====
install_flutter_mobile() {
    echo -e "${CYAN}=== Menginstall paket Mobile Development ===${NC}"
    
    # 1. Install snapd terlebih dahulu
    echo -e "${CYAN}Menginstall snapd...${NC}"
    if ! command -v snap &> /dev/null; then
        apt-get install -y snapd || {
            echo -e "${MERAH}[ERROR] Gagal install snapd${NC}"
            echo -e "${KUNING}Flutter membutuhkan snapd untuk diinstall${NC}"
            return 1
        }
        
        # Start snapd service
        systemctl enable snapd.socket 2>/dev/null
        systemctl start snapd.socket 2>/dev/null
        
        # Tunggu snapd siap
        echo -e "${CYAN}Menunggu snapd siap...${NC}"
        sleep 3
        
        # Coba jalankan snap untuk memastikan
        snap version &>/dev/null || {
            echo -e "${MERAH}[ERROR] snapd tidak berfungsi dengan baik${NC}"
            return 1
        }
        
        echo -e "${HIJAU}✓ snapd berhasil diinstall dan aktif${NC}"
    else
        echo -e "${HIJAU}✓ snapd sudah terinstall${NC}"
    fi
    
    # 2. Install Flutter via snap
    echo -e "${CYAN}Menginstall Flutter via Snap...${NC}"
    if ! snap list 2>/dev/null | grep -q flutter; then
        snap install flutter --classic 2>&1 | tee /tmp/flutter_install.log
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo -e "${HIJAU}✓ Flutter berhasil diinstall!${NC}"
            
            # Setup Flutter path untuk user
            FLUTTER_PATH="/snap/bin"
            if ! echo "$PATH" | grep -q "$FLUTTER_PATH"; then
                echo 'export PATH="$PATH:/snap/bin"' >> /home/$TARGET_USER/.bashrc
                echo -e "${HIJAU}✓ Flutter path ditambahkan ke .bashrc${NC}"
            fi
        else
            echo -e "${MERAH}[ERROR] Flutter gagal diinstall${NC}"
            echo -e "${CYAN}Log error tersimpan di: /tmp/flutter_install.log${NC}"
            cat /tmp/flutter_install.log
            return 1
        fi
    else
        echo -e "${HIJAU}✓ Flutter sudah terinstall${NC}"
    fi
    
    # 3. Install Android tools
    echo -e "${CYAN}Menginstall Android tools...${NC}"
    install_packages adb android-sdk-platform-tools-common
    
    echo -e "${HIJAU}[OK] Paket Mobile Dev selesai diinstall!${NC}"
    echo -e "${KUNING}Tips: Jalankan 'flutter doctor' untuk cek konfigurasi Flutter${NC}"
}

# ===== Fungsi Konfigurasi phpMyAdmin =====
configure_phpmyadmin() {
    echo -e "${CYAN}Mengkonfigurasi phpMyAdmin...${NC}"
    
    # Cek apakah MariaDB sudah running
    if ! systemctl is-active --quiet mariadb; then
        systemctl start mariadb || {
            echo -e "${MERAH}[ERROR] Gagal start MariaDB${NC}"
            return 1
        }
    fi
    systemctl enable mariadb
    
    # Buat symbolic link
    if [ -L /var/www/html/phpmyadmin ]; then
        rm -f /var/www/html/phpmyadmin
    fi
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    
    # Enable konfigurasi Apache
    if [ -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
        a2enconf phpmyadmin 2>/dev/null
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
        a2enconf phpmyadmin 2>/dev/null
    fi
    
    # Start dan reload Apache
    if ! systemctl is-active --quiet apache2; then
        systemctl start apache2 || {
            echo -e "${MERAH}[ERROR] Gagal start Apache2${NC}"
            return 1
        }
    fi
    systemctl enable apache2
    systemctl reload apache2
    
    echo -e "${HIJAU}✓ phpMyAdmin berhasil dikonfigurasi!${NC}"
    
    # Buat akun database
    echo ""
    echo -e "${KUNING}=================================================${NC}"
    echo -e "${KUNING}    Buat Akun Database untuk Login phpMyAdmin${NC}"
    echo -e "${KUNING}=================================================${NC}"
    echo ""
    
    while true; do
        read -p "$(echo -e ${KUNING})Masukkan username database: $(echo -e ${NC})" DB_USER
        if [ -n "$DB_USER" ] && [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
            break
        else
            echo -e "${MERAH}Username harus alfanumerik dan underscore!${NC}"
        fi
    done
    
    while true; do
        read -s -p "$(echo -e ${KUNING})Masukkan password database: $(echo -e ${NC})" DB_PASS
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
    
    echo -e "${CYAN}Membuat akun database '$DB_USER'...${NC}"
    
    if [ "$ACCESS_LEVEL" = "1" ]; then
        mysql -u root <<MYSQL_SCRIPT 2>/dev/null
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
        
        if [ $? -eq 0 ]; then
            echo -e "${HIJAU}✓ Akun database berhasil dibuat!${NC}"
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
            echo -e "${HIJAU}✓ Akun dan database '$DB_NAME' berhasil dibuat!${NC}"
            PHPMYADMIN_USER="$DB_USER"
            PHPMYADMIN_PASS_SET=true
            PHPMYADMIN_DB="$DB_NAME"
        fi
    fi
}

# ===== Eksekusi Pilihan Multi =====
PHPMYADMIN_INSTALLED=false

if [ "$PHPMYADMIN_EXISTS" = true ]; then
    PHPMYADMIN_INSTALLED=true
fi

for CHOICE in "${CHOICES[@]}"; do
    case $CHOICE in
      0)
        echo -e "${HIJAU}[OK] Tidak ada paket tambahan${NC}"
        ;;
      1)
        if [ "$FRONTEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Frontend sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall Frontend ===${NC}"
            install_yarn_repo
            install_packages yarn
            install_sass_tools
            echo -e "${HIJAU}[OK] Frontend selesai!${NC}"
        fi
        ;;
      2)
        if [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Backend sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall Backend ===${NC}"
            install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
            
            add-apt-repository -y universe
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
            
            configure_phpmyadmin
            PHPMYADMIN_INSTALLED=true
            echo -e "${HIJAU}[OK] Backend selesai!${NC}"
        fi
        ;;
      3)
        if [ "$FRONTEND_INSTALLED" = true ] && [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Fullstack sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall Fullstack ===${NC}"
            
            if [ "$FRONTEND_INSTALLED" = false ]; then
                install_yarn_repo
                install_packages yarn
                install_sass_tools
            fi
            
            if [ "$BACKEND_INSTALLED" = false ]; then
                install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
                
                add-apt-repository -y universe
                apt-get update
                DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
                
                configure_phpmyadmin
                PHPMYADMIN_INSTALLED=true
            fi
            
            echo -e "${HIJAU}[OK] Fullstack selesai!${NC}"
        fi
        ;;
      4)
        if [ "$MOBILE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Mobile Dev sudah terinstall${NC}"
        else
            install_flutter_mobile
        fi
        ;;
      5)
        if [ "$GAME_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Game Dev sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall Game Dev ===${NC}"
            install_packages godot3 libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
            echo -e "${HIJAU}[OK] Game Dev selesai!${NC}"
        fi
        ;;
      6)
        if [ "$DATASCIENCE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Data Science sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall Data Science ===${NC}"
            # PERBAIKAN: Hapus pytorch karena tidak ada di repo standar
            install_packages python3-numpy python3-pandas python3-sklearn python3-matplotlib python3-seaborn jupyter-notebook python3-scipy
            
            # Opsi install PyTorch via pip
            echo -e "${CYAN}PyTorch tidak tersedia di repo, install via pip? (y/n)${NC}"
            read -p "> " INSTALL_TORCH
            if [[ "$INSTALL_TORCH" =~ ^[Yy]$ ]]; then
                apt-get install -y python3-pip
                pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
            fi
            
            echo -e "${HIJAU}[OK] Data Science selesai!${NC}"
        fi
        ;;
      7)
        if [ "$DEVOPS_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] DevOps sudah terinstall${NC}"
        else
            echo -e "${CYAN}=== Menginstall DevOps ===${NC}"
            install_packages ansible nginx apache2-utils
            
            # Terraform dan kubectl perlu repo khusus
            echo -e "${KUNING}Terraform & kubectl memerlukan setup repo tambahan${NC}"
            echo -e "${CYAN}Untuk install manual:${NC}"
            echo -e "  - Terraform: https://developer.hashicorp.com/terraform/install"
            echo -e "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
            
            echo -e "${HIJAU}[OK] DevOps selesai!${NC}"
        fi
        ;;
      *)
        echo -e "${MERAH}[ERROR] Pilihan tidak valid: $CHOICE${NC}"
        ;;
    esac
done

# ===== Langkah 5: Buat folder VS Code dan settings.json =====
echo -e "${CYAN}[5/8] Menyiapkan VS Code User settings...${NC}"
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
echo -e "${CYAN}[6/8] Membuat folder projects dan workspace...${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Workspace || echo -e "${KUNING}[WARNING] Gagal membuat Workspace${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Projects || echo -e "${KUNING}[WARNING] Gagal membuat Projects${NC}"
echo -e "${HIJAU}[OK] Folder projects dan workspace siap digunakan!${NC}"
sleep 0.5

# ===== Langkah 7: Konfigurasi Plank Dock =====
echo -e "${CYAN}[7/8] Mengkonfigurasi Plank dock...${NC}"

# Pastikan Plank terinstall
if command -v plank &> /dev/null; then
    # Konfigurasi via gsettings
    sudo -u $TARGET_USER gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ zoom-enabled true
    sudo -u $TARGET_USER gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ zoom-percent 130
    sudo -u $TARGET_USER gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ theme 'Default'
    sudo -u $TARGET_USER gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ alignment 'center'
    sudo -u $TARGET_USER gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ position 'bottom'
    
    # Restart Plank jika sedang berjalan
    if pgrep -u $TARGET_USER plank > /dev/null; then
        sudo -u $TARGET_USER killall plank 2>/dev/null
        sleep 1
        sudo -u $TARGET_USER nohup plank &>/dev/null &
    fi
    
    echo -e "${HIJAU}[OK] Plank dock berhasil dikonfigurasi!${NC}"
else
    echo -e "${KUNING}[WARNING] Plank tidak terinstall, melewati konfigurasi${NC}"
fi
sleep 0.5

# ===== Langkah 7: Finish & Cleanup =====
echo -e "${CYAN}[8/8] Menyelesaikan konfigurasi...${NC}"
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
