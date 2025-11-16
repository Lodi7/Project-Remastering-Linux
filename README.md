# Project Remastering LOS

**Membangun lingkungan pengembangan khusus untuk software development dengan linux mint xfce version**

## Step 1 Jalankan pembaruan pertama kali setelah instalasi Linux untuk memastikan semua paket terbaru dan keamanan sistem sudah terpasang.

`sudo apt update && sudo apt upgrade -y`

## Step 2 install cubic

1. `sudo apt-add-repository universe`
2. `sudo apt-add-repository ppa:cubic-wizard/release`
3. `sudo apt update`
4. `sudo apt install cubic`

## Step 3 Modifikasi parameter boot kernel

1. `sudo nano /etc/default/grub`
2. Cari GRUB_CMDLINE_LINUX_DEFAULT
3. Edit isinya menjadi GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 panic=10 fsck.mode=auto fsck.repair=yes"
- **Note** : Jika tidak menggunakan cubic dan langsung merubahnya di terminal lakukan `sudo update-grub` lalu `sudo reboot`

## Step 4 install aplikasi yang dibutuhkan

### Install python

1. `sudo apt install -y python3 python3-pip python3-venv`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `python3 --version` dan `pip3 --version`

### Install GCC

1. `sudo apt install -y build-essential`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `gcc --version`,`g++ --version`, dan `make --version`

### Install OpenJDK

1. Cek versi Java yang tersedia `apt search -jdk --names-only`
2. Lalu install sesuai dengan versi yang di inginkan `sudo apt install -y openjdk-xx-jdk`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `java -version` dan `javac -version`

### Install Node.Js

1. Jika curl belum terinstall `sudo apt-get install curl`
2. Jika sudah ada langsung `curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -`
3. `sudo apt-get install nodejs`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `node -v` dan `npm -v`

### Install Vscode

#### Penginstallan aplikasi

1. Lakukan `sudo apt update && sudo apt ugrade -y` jika belum
2. Install dependensi yang diperlukan `sudo apt install curl gpg dirmngr software-properties-common apt-transport-https`
3. Tambahkan repositori resmi VSCode Microsoft Impor kunci GPG Microsoft `curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg > /dev/null`
4. Tambahkan repositori Visual Studio Code `echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null`
5. Jalankan `sudo apt update` untuk memperbarui daftar paket
6. Install Vscode `sudo apt install code`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `code ---version`

#### Penginstallan extension

1. siapkan file/package-nya yang berisikan nama publisher.nama-extension dengan format .txt yang ingin di install (digithub saya sudah ada dengan nama extension-vscode.txt)
2. Install extensionnya `cat extension-vscode.txt | grep -v '^#' | xargs -L 1 code --install-extension`

#### Pengaturan konfigurasi

sebentar

### Install Git

1. `sudo apt install -y git gitk git-gui`
2. Atur konfigurasi git
   - `git config --system core.editor "code --wait"`
   - `git config --system init.defaultBranch main`
   - `git config --system pull.rebase false`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `git --version`

### Install Docker

1. `sudo apt update` jika belum pernah
2. Instal paket prasyarat untuk memungkinkan apt menggunakan repositori melalui HTTPS `sudo apt install ca-certificates curl`
3. Buat direktori untuk kunci GPG Docker `sudo install -m 0755 -d /etc/apt/keyrings`
4. Tambahkan Docker's official GPG key
   - `sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc`
   - `sudo chmod a+r /etc/apt/keyrings/docker.asc`
6. Tambahkan repositori nya ke Apt sources `echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`
7. Update repository nya `sudo apt update`
8. Install Docker package-nya `sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
9. Jalankan Docker tanpa sudo (opsional)
   - `sudo groupadd docker`
   - `usermod -aG docker $USER` (dicubic pakai skrip otomatis)
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `docker --version` dan `docker composer version`

## Step 5 Hapus aplikasi bawaan (bloatware) yang tidak digunakan atau tidak relevan

1. `sudo apt update` (opsional jika sudah pernah tidak usah)
2. Meghapus paket dan semua konfigurasi nya `sudo apt purge -y nama-aplikasi`
3. Menghapus library yang tidak terpakai `sudo apt autoremove -y`

## Step 6 Merubah tampilan atau tema

### Mengekstrak dan Memindahkan tema ke folder themes

1. Download tema yang ingin digunakan bisa di pling atau git clone
2. ekstrak tema yang sudah di download
   - zip gunakan `unzip nama-theme.zip -d nama-theme`
   - tar.gz gunakan `tar -xvf nama-theme.tar.gz`
3. Pindahkan ke folder global
  - Untuk GTK/Windows Manager Theme gunakan `sudo mv nama-theme /usr/share/themes/`
  - Untuk Icons dan Cursor gunaka `sudo mv nama-theme /usr/share/icons`
  - Untuk Wallpaper atau Background gunakan `sudo mv nama-bg /usr/share/backgrounds`
- **Note** : Pastikan sebelumnya kalian sudah di folder tempat tema yang kalian download dengan `cd ~/path-folder-tema`

### Mengatur hak akses
#### GTK Theme
- `sudo chmod -R 755 /usr/share/themes/nama-gtk-theme`
- `sudo chown -R root:root /usr/share/themes/nama-gtk-theme`

# Window Manager Theme
- `sudo chmod -R 755 /usr/share/themes/nama-wm-theme`
- `sudo chown -R root:root /usr/share/themes/nama-wm-theme`

# Icon Theme
- `sudo chmod -R 755 /usr/share/icons/nama-icon-theme`
- `sudo chown -R root:root /usr/share/icons/nama-icon-theme`

# Cursor Theme
- `sudo chmod -R 755 /usr/share/icons/nama-cursor-theme`
- `sudo chown -R root:root /usr/share/icons/nama-cursor-theme`

# Wallpaper
- `sudo chmod 644 /usr/share/backgrounds/nama-wallpaper.jpg`
- `sudo chown root:root /usr/share/backgrounds/nama-wallpaper.jpg`

### Mengatur Xfce untuk pakai tema

#### GTK Theme
  `xfconf-query -c xsettings -p /Net/ThemeName -s "nama-gtk-theme"`
#### Windows Manager Theme
  `xfconf-query -c xfwm4 -p /general/theme -s "nama-wm-theme"`
#### Icons Theme (Jika Ada)
  `xfconf-query -c xsettings -p /Net/IconThemeName -s "nama-icons-theme"`
#### Cursor Theme (Jika Ada)
  ```xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "nama-cursor-theme"```
  ```xfconf-query -c xsettings -p /Gtk/CursorSize -s 24```
#### Wallpaper
  `xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/nama-wallpaper.jpg"`
- **Note** : Jika sudah lakukan `xfdesktop --reload` dan `xfce4-panel -r` agar tema tadi diterapkan
- **Tambahan** : Jika tidak tau nama tema yang akan digunakan bisa lakukan `ls /usr/share/path-nya/`

## Step 7 Merubah tampilan splash screen dan logo animasi booting

### Splash Screen booting

1. Siapkan plymouth yang akan digunakan
2. Ekstra terlebih dahulu
   - zip gunakan `unzip nama-plymouth.zip -d nama-plymouth`
   - tar.gz gunakan `tar -xvf nama-plymouth.tar.gz`
3. Pindahkan ke folder plymouth `sudo mv nama-plymouth /usr/share/plymouth/themes/`
4. Cek isi folder (opsional) `ls /usr/share/plymouth/themes/nama-plymouth`
5. Set tema plymouth baru dengan `sudo plymouth-set-default-theme nama-plymouth -R`
- **Note** : Pastikan sebelumnya kalian sudah di folder tempat plymouth yang kalian siapkan dengan `cd ~/path-folder-plymouth `
- **Tambahan** : Jika ingin tes tema plymouth tanpa reboot bisa lakukan `sudo plymouthd` `sudo plymouthd --show-splash` `sudo pkill plymouthd`

### Login screen logo

1. Siapkan logo yang ingin digunakan
2. Backup logo lama (opsional) `sudo cp /usr/share/plymouth/nama-logo-distro.png{,.bak}`
3. Lalu ganti dengan logo yang disiapkan `sudo cp ~/pathfolder/nama-logo.png /usr/share/plymouth/nama-logo-distro.png`

## Step 8 Menambahkan Skrip Otomatis
1. Siapkah skrip otomatis yang ingin digunakan (direpo firstboot.sh)
2. pindahkan skrip ke `mv /path/lokasi/firstboot.sh /usr/local/bin/nama-skrip.sh`
3. Berikan akses `chmod +x /usr/local/bin/nama-skrip.sh`
4. Buat systemd service untuk firstboot `nano /etc/systemd/system/nama-skrip.service`
5. Lalu isi dengan
   ```[Unit]
Description=First Boot Configuration LOS
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nama-file.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target```
6. Setelah disimpan atur agar service jalan `systemctl enable nama-file.service`
