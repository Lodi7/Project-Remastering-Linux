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
echo -e "${CYAN}[1/7] Memperbarui dan meng-upgrade sistem...${NC}"
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
echo -e "${CYAN}[2/7] Mengatur Git...${NC}"
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
echo -e "${CYAN}[3/7] Menambahkan user '$TARGET_USER' ke grup Docker...${NC}"
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

# Cek Frontend
if command -v yarn &> /dev/null && command -v sassc &> /dev/null; then
    FRONTEND_INSTALLED=true
fi

# Cek Backend
if command -v php &> /dev/null && command -v composer &> /dev/null && systemctl is-active --quiet mariadb 2>/dev/null; then
    BACKEND_INSTALLED=true
fi

# Cek Mobile Dev
if snap list 2>/dev/null | grep -q flutter && command -v adb &> /dev/null; then
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
echo -e "${NC}       -> yarn, sassc, libsass1, dart-sass"

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
echo -e "${NC}       -> flutter(snap), adb, android-sdk, android-platform-tools"

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
echo -e "${NC}       -> numpy, pandas, scikit-learn, matplotlib, seaborn, jupyter-notebook, scipy, torch"

# DevOps
if [ "$DEVOPS_INSTALLED" = true ]; then
    echo -e "${KUNING}  7)${NC} DevOps & Automation (tanpa Docker) ${HIJAU}(Sudah Terinstall)${NC}"
else
    echo -e "${KUNING}  7)${NC} DevOps & Automation (tanpa Docker)"
fi
echo -e "${NC}       -> ansible, terraform, kubectl, helm, nginx, apache2-utils"

echo ""
read -p "$(echo -e ${BIRU_CERAH})Masukkan pilihan paket (pisahkan spasi jika lebih dari satu, misal 1 2 6): $(echo -e ${NC})" -a CHOICES
echo ""

# ===== Fungsi Tambah Repo =====
add_repo_if_needed() {
    PACKAGE="$1"
    REPO="$2"
    if ! apt-cache show "$PACKAGE" > /dev/null 2>&1; then
        echo -e "${CYAN}Menambahkan repo: $REPO${NC}"
        add-apt-repository -y "$REPO" || echo -e "${KUNING}[WARNING] Gagal menambahkan repo${NC}"
        apt-get update -y
    fi
}

install_packages() {
    echo -e "${CYAN}Menginstall paket: $@${NC}"
    apt-get install -y "$@" || echo -e "${MERAH}[WARNING] Beberapa paket gagal diinstall${NC}"
}

# ===== Fungsi Install Yarn dengan GPG Key =====
install_yarn_repo() {
    echo -e "${CYAN}Menambahkan repository Yarn...${NC}"
    # DIPERBAIKI: Tambahkan GPG key dengan cara yang benar
    if ! command -v yarn &> /dev/null; then
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
        apt-get update || error_exit "Gagal update setelah tambah repo Yarn"
    fi
}

# ===== Fungsi Konfigurasi phpMyAdmin =====
configure_phpmyadmin() {
    echo -e "${CYAN}Mengkonfigurasi phpMyAdmin...${NC}"
    
    # DIPERBAIKI: Cek apakah MariaDB sudah running, jika belum start
    if ! systemctl is-active --quiet mariadb; then
        systemctl start mariadb || error_exit "Gagal start MariaDB"
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
        # Buat konfigurasi manual jika tidak ada
        cat > /etc/apache2/conf-available/phpmyadmin.conf <<'PHPCONF'
# phpMyAdmin default Apache configuration
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
<Directory /usr/share/phpmyadmin/setup/lib>
    Require all denied
</Directory>
PHPCONF
        a2enconf phpmyadmin 2>/dev/null
    fi
    
    # Start dan reload Apache
    if ! systemctl is-active --quiet apache2; then
        systemctl start apache2 || error_exit "Gagal start Apache2"
    fi
    systemctl enable apache2
    systemctl reload apache2
    
    echo -e "${HIJAU}[OK] phpMyAdmin berhasil dikonfigurasi!${NC}"
    
    # ===== Buat Akun Database untuk User =====
    echo ""
    echo -e "${KUNING}=================================================${NC}"
    echo -e "${KUNING}    Buat Akun Database untuk Login phpMyAdmin${NC}"
    echo -e "${KUNING}=================================================${NC}"
    echo ""
    echo -e "${CYAN}Anda perlu membuat akun database untuk login ke phpMyAdmin.${NC}"
    echo -e "${CYAN}Akun ini terpisah dari user sistem Linux.${NC}"
    echo ""
    
    # Input username database dengan validasi
    while true; do
        read -p "$(echo -e ${KUNING})Masukkan username database: $(echo -e ${NC})" DB_USER
        if [ -n "$DB_USER" ] && [[ "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
            break
        else
            echo -e "${MERAH}Username harus alfanumerik dan underscore saja!${NC}"
        fi
    done
    
    # Input password database dengan validasi
    while true; do
        read -s -p "$(echo -e ${KUNING})Masukkan password database: $(echo -e ${NC})" DB_PASS
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
    echo -e "${CYAN}Membuat akun database '$DB_USER'...${NC}"
    
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
            echo -e "${KUNING}Anda bisa login dengan user 'root' tanpa password.${NC}"
            PHPMYADMIN_USER="root"
            PHPMYADMIN_PASS_SET=false
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
            echo -e "${KUNING}Anda bisa login dengan user 'root' tanpa password.${NC}"
            PHPMYADMIN_USER="root"
            PHPMYADMIN_PASS_SET=false
        fi
    else
        echo -e "${KUNING}Pilihan tidak valid, menggunakan akun root default.${NC}"
        PHPMYADMIN_USER="root"
        PHPMYADMIN_PASS_SET=false
    fi
    
    echo ""
}

# ===== Eksekusi Pilihan Multi =====
PHPMYADMIN_INSTALLED=false

# Jika phpMyAdmin sudah ada dari deteksi awal, set flag
if [ "$PHPMYADMIN_EXISTS" = true ]; then
    PHPMYADMIN_INSTALLED=true
fi

for CHOICE in "${CHOICES[@]}"; do
    case $CHOICE in
      0)
        echo -e "${HIJAU}[OK] Tidak ada paket tambahan diinstall.${NC}"
        ;;
      1)
        if [ "$FRONTEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Frontend sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Frontend ===${NC}"
            install_yarn_repo  # DIPERBAIKI: Gunakan fungsi baru
            install_packages yarn sassc libsass1 dart-sass
            echo -e "${HIJAU}[OK] Paket Frontend selesai diinstall!${NC}"
        fi
        ;;
      2)
        if [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Backend sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Backend ===${NC}"
            install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
            
            # Install phpMyAdmin
            add-apt-repository -y universe
            apt-get update
            echo -e "${CYAN}Menginstall phpMyAdmin...${NC}"
            DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
            
            # Konfigurasi phpMyAdmin
            configure_phpmyadmin
            PHPMYADMIN_INSTALLED=true
            
            echo -e "${HIJAU}[OK] Paket Backend + phpMyAdmin selesai diinstall!${NC}"
        fi
        ;;
      3)
        if [ "$FRONTEND_INSTALLED" = true ] && [ "$BACKEND_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Fullstack sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Fullstack ===${NC}"
            
            # Install Frontend jika belum
            if [ "$FRONTEND_INSTALLED" = false ]; then
                install_yarn_repo  # DIPERBAIKI
                install_packages yarn sassc libsass1 dart-sass
            else
                echo -e "${KUNING}Frontend sudah ada, skip...${NC}"
            fi
            
            # Install Backend jika belum
            if [ "$BACKEND_INSTALLED" = false ]; then
                install_packages php php-cli php-fpm php-mysql php-curl php-xml php-mbstring php-zip php-gd composer mariadb-server apache2
                
                # Install phpMyAdmin
                add-apt-repository -y universe
                apt-get update
                echo -e "${CYAN}Menginstall phpMyAdmin...${NC}"
                DEBIAN_FRONTEND=noninteractive apt-get install -y phpmyadmin
                
                # Konfigurasi phpMyAdmin
                configure_phpmyadmin
                PHPMYADMIN_INSTALLED=true
            else
                echo -e "${KUNING}Backend sudah ada, skip...${NC}"
            fi
            
            echo -e "${HIJAU}[OK] Paket Fullstack selesai diinstall!${NC}"
        fi
        ;;
      4)
        if [ "$MOBILE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Mobile Dev sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Mobile Development ===${NC}"
            if ! snap list 2>/dev/null | grep -q flutter; then
                echo -e "${CYAN}Menginstall Flutter via Snap...${NC}"
                snap install flutter --classic || echo -e "${MERAH}[WARNING] Gagal install Flutter${NC}"
                if [ $? -eq 0 ]; then
                    echo -e "${HIJAU}[OK] Flutter berhasil diinstall!${NC}"
                fi
            else
                echo -e "${KUNING}Flutter sudah terinstall, melewati...${NC}"
            fi
            install_packages adb android-sdk android-sdk-platform-tools-common
            echo -e "${HIJAU}[OK] Paket Mobile Dev selesai diinstall!${NC}"
        fi
        ;;
      5)
        if [ "$GAME_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Game Dev sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Game Development ===${NC}"
            install_packages godot3 libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
            echo -e "${HIJAU}[OK] Paket Game Dev selesai diinstall!${NC}"
        fi
        ;;
      6)
        if [ "$DATASCIENCE_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket Data Science & ML sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket Data Science & ML ===${NC}"
            install_packages python3-numpy python3-pandas python3-sklearn python3-matplotlib python3-seaborn jupyter-notebook python3-scipy python3-torch
            echo -e "${HIJAU}[OK] Paket Data Science & ML selesai diinstall!${NC}"
        fi
        ;;
      7)
        if [ "$DEVOPS_INSTALLED" = true ]; then
            echo -e "${KUNING}[SKIP] Paket DevOps sudah terinstall, melewati...${NC}"
        else
            echo -e "${CYAN}=== Menginstall paket DevOps & Automation ===${NC}"
            install_packages ansible terraform kubectl helm nginx apache2-utils
            echo -e "${HIJAU}[OK] Paket DevOps selesai diinstall!${NC}"
        fi
        ;;
      *)
        echo -e "${MERAH}[ERROR] Pilihan tidak valid: $CHOICE${NC}"
        ;;
    esac
done

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
echo -e "${CYAN}[6/7] Membuat folder projects dan workspace...${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Workspace || echo -e "${KUNING}[WARNING] Gagal membuat Workspace${NC}"
sudo -u $TARGET_USER mkdir -p /home/$TARGET_USER/Projects || echo -e "${KUNING}[WARNING] Gagal membuat Projects${NC}"
echo -e "${HIJAU}[OK] Folder projects dan workspace siap digunakan!${NC}"
sleep 0.5

# ===== Langkah 7: Finish & Cleanup =====
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
