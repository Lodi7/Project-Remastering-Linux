# Project Remastering LOS

**Membangun lingkungan pengembangan khusus untuk software development dengan linux mint xfce version**

## Step 1 Jalankan pembaruan pertama kali setelah instalasi Linux untuk memastikan semua paket terbaru dan keamanan sistem sudah terpasang.

`sudo apt update && sudo apt upgrade -y`

## Step 2 install cubic

1. `sudo apt-add-repository universe`
2. `sudo apt-add-repository ppa:cubic-wizard/release`
3. `sudo apt update`
4. `sudo apt install cubic -y`

## Step 3 Modifikasi parameter boot kernel

1. `sudo nano /etc/default/grub`
2. Cari GRUB_CMDLINE_LINUX_DEFAULT
3. Edit isinya menjadi GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 panic=10 fsck.mode=auto fsck.repair=yes"
   - Penjelasan Fungsi Masing-Masing Parameter
      - quiet
        - Menyembunyikan sebagian besar pesan booting.
        - Sistem tetap berjalan normal, tapi output kernel tidak tampil di layar.
        - Boot jadi lebih bersih/minimalis.
      - splash
         - Menampilkan tampilan grafis (gambar/animasi) saat boot, seperti Plymouth.
         - Biasanya dipasangkan dengan quiet.
      - loglevel=3
         - Menentukan tingkat verbosity pesan kernel.
         - Nilai 3 = hanya menampilkan pesan penting (error, warning).
         - Cocok untuk membuat boot lebih "bersih" tapi tetap menampilkan error penting.
      - panic=10
         - Jika kernel mengalami kernel panic, sistem akan otomatis reboot setelah 10 detik.
         - Berguna di server/headless environment agar tidak hang selamanya.
      - fsck.mode=auto
         - Mengatur perilaku fsck (pemeriksaan filesystem) saat boot.
         - auto = biarkan sistem memutuskan, biasanya memeriksa otomatis jika perlu.
      - fsck.repair=yes
         - Menginstruksikan sistem untuk memperbaiki kerusakan filesystem secara otomatis tanpa menunggu input.
         - Cocok untuk sistem yang startup otomatis (server, kiosk), karena tidak memblok boot.
- **Note** : Jika tidak menggunakan cubic dan langsung merubahnya di terminal lakukan `sudo update-grub` lalu `sudo reboot`

## Step 4 install aplikasi yang dibutuhkan

### Install python

1. `sudo apt install -y python3 python3-pip python3-venv`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `python3 --version` dan `pip3 --version`

### Install GCC

1. `sudo apt install -y build-essential`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `gcc --version`,`g++ --version`, dan `make --version`

### Install OpenJDK

1. Cek versi Java yang tersedia `apt search openjdk-`
2. Lalu install sesuai dengan versi yang di inginkan `sudo apt install -y openjdk-17-jdk`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `java -version` dan `javac -version`

### Install Node.Js

1. Jika curl belum terinstall `sudo apt-get install curl`
2. Jika sudah ada langsung `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash`
3. `\. "$HOME/.nvm/nvm.sh"`
4. install node.js versi 24(lTS) `nvm install 24`
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
2. Install extensionnya `cat extension-vscode.txt | grep -v '^#' | xargs -L 1 code --install-extension`, gunakan ini jika di cubic Install extension ke temporary directory dulu
`cat extension-vscode.txt | grep -v '^#' | sed "s/[^a-zA-Z0-9.-]//g" | xargs -L 1 sudo code --no-sandbox --user-data-dir=/tmp/vscode-data --install-extension`
3. Buat direktori di /etc/skel
`sudo mkdir -p /etc/skel/.vscode/extensions/`
4. Copy extension dari temp ke /etc/skel
`sudo mv /root/.vscode/extensions/* /etc/skel/.vscode/extensions/`
5. Set permission
`sudo chmod -R 755 /etc/skel/.vscode/`

#### Pengaturan konfigurasi

Jadi satu dengan skrip otomatis 

### Install Git

1. `sudo apt install -y git gitk git-gui`
2. Atur konfigurasi git
   - `sudo git config --system core.editor "code --wait"`
   - `sudo git config --system init.defaultBranch main`
   - `sudo git config --system pull.rebase false`
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `git --version`

### Install Docker

1. `sudo apt update` jika belum pernah
2. Instal paket prasyarat untuk memungkinkan apt menggunakan repositori melalui HTTPS `sudo apt install ca-certificates curl`
3. Buat direktori untuk kunci GPG Docker `sudo install -m 0755 -d /etc/apt/keyrings`
4. Tambahkan Docker's official GPG key
   - `sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc`
   - `sudo chmod a+r /etc/apt/keyrings/docker.asc`
6. Tambahkan repositori nya ke Apt sources `echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`
7. Update repository nya `sudo apt update`
8. Install Docker package-nya `sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
9. Jalankan Docker tanpa sudo (opsional)
   - `sudo groupadd docker`
   - `usermod -aG docker $USER` (dicubic pakai skrip otomatis)
- **Note** : Cek apakah sudah terinstall dengan benar menggunakan `docker --version` dan `docker composer version`

### Install Brave
1. `sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg`
2. `sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources`
3. `sudo apt update`
4. `sudo apt install brave-browser`

## Step 5 Hapus aplikasi bawaan (bloatware) yang tidak digunakan atau tidak relevan

1. `sudo apt update` (opsional jika sudah pernah tidak usah)
2. Meghapus paket dan semua konfigurasi nya `sudo apt remove --purge -y hypnotix, thingy, libreoffice-base-core
,libreoffice-common, libreoffice-draw, fingwit, webapp-manager, firefox`
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
  - Untuk Wallpaper atau Background gunakan `sudo mv nama-bg /usr/share/backgrounds` atau `sudo mv nama-bg /usr/share/xfce4/backdrops/`
- **Note** : Pastikan sebelumnya kalian sudah di folder tempat tema yang kalian download dengan `cd ~/path-folder-tema` atau jika tidak menggunakan cubic **drag** & **drop** ke cd /usr/share/pathnya

### Mengatur hak akses (opsional)
#### GTK Theme
- `sudo chmod -R 755 /usr/share/themes/nama-gtk-theme`
- `sudo chown -R root:root /usr/share/themes/nama-gtk-theme`

#### Window Manager Theme
- `sudo chmod -R 755 /usr/share/themes/nama-wm-theme`
- `sudo chown -R root:root /usr/share/themes/nama-wm-theme`

#### Icon Theme
- `sudo chmod -R 755 /usr/share/icons/nama-icon-theme`
- `sudo chown -R root:root /usr/share/icons/nama-icon-theme`

#### Cursor Theme
- `sudo chmod -R 755 /usr/share/icons/nama-cursor-theme`
- `sudo chown -R root:root /usr/share/icons/nama-cursor-theme`

#### Wallpaper
- `sudo chmod 644 /usr/share/backgrounds/nama-wallpaper.jpg`
- `sudo chown root:root /usr/share/backgrounds/nama-wallpaper.jpg`

### Mengatur Xfce untuk pakai tema
### Cara 1 (hanya user lokal saja)
#### GTK Theme
  `xfconf-query -c xsettings -p /Net/ThemeName -s "nama-gtk-theme" --create`
#### Windows Manager Theme
  `xfconf-query -c xfwm4 -p /general/theme -s "nama-wm-theme" --create`
#### Icons Theme (Jika Ada)
  `xfconf-query -c xsettings -p /Net/IconThemeName -s "nama-icons-theme" --create`
#### Cursor Theme (Jika Ada)
  ```xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "nama-cursor-theme" --create```
  ```xfconf-query -c xsettings -p /Gtk/CursorSize -s 24```
#### Wallpaper
`xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/anime.jpg" --create --type string`


### Cara 2 (global)
1. setelah cara 1 langsung copy ke /etc/skel
   - `sudo mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/` (kalau belum ada)
   - `sudo cp -r ~/.config/xfce4/xfconf/xfce-perchannel-xml/*.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/`
2. Kalau maud edit lagi tinggal `sudo nano /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/nama-setting.xml` 
   - Untuk gtk,icons,cursor ada di `xsettings.xml` lalu cari ini
      - `<property name="Net/ThemeName" type="string" value="nama-gtk-theme"/>`
      - `<property name="Net/IconThemeName" type="string" value="nama-icons-theme"/>`
      - `<property name="Gtk/CursorThemeName" type="string" value="nama-cursor-theme"/>`
      - `<property name="Gtk/CursorSize" type="int" value="24"/>`
   - Untuk WM `xfwm4.xml` lalu cari ini
      - `<property name="theme" type="string" value="nama-theme"/>`
   - Untuk wallpaper `xfce4-desktop.xml`  lalu cari ini
     - `value = /usr/share/backgrounds/nama-bg.jpg` atau `value = /usr/share/xfce4/backdrops/nama-bg.jpg`
3. Jika sudah jangan lupa `sudo chown -R root:root /etc/skel/.config/xfce4` dan `sudo chmod -R 755 /etc/skel/.config/xfce4`
- **Note** : Jika sudah lakukan `xfdesktop --reload` dan `xfce4-panel -r` agar tema tadi diterapkan. Note lainnya kalau cp ke /etc/xdg/
- **Tambahan** : Jika tidak tau nama tema yang akan digunakan bisa lakukan `ls /usr/share/path-nya/` lalu jika waktu di cubic tidak bisa xfconf lakukan
   - `dbus-launch`
   - `xfce4-session &`
   - `sleep 2`
 
### Merubah posisi login window
1. `sudo nano /etc/lightdm/slick-greeter.conf/`
2. isi dengan folder lightdm yang telah disiapkan
3. tambahkan permission `sudo chmod 644 /etc/lightdm/slick-greeter.conf`
4. kalau belum di chroot `sudo systemctl restart lightdm`
5. Jika gagal isi semua /etc/lightdm dengan folder yang telah disiapkan

### Mengganti icon start menu
1. siapkan logo icon nya yaitu LOS.png
2. pindahkan dengan `mv /lokasi/path/LOS.png /usr/share/icons/
3. berikan permission `sudo chmod 644 /usr/share/icons/LOS.png`
4. Jangan lupa ganti pathnya di /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce-panel.xml

### Menyiapkan plank
1. buat folder baru `mkdir /etc/skel/.config/plank/dock1/launchers/`
2. isi dengan folder plank yang sudah disiapkan
3. buat autostart nya `sudo nano /etc/skel/.config/autostart/plank.desktop`
4. isi dengan file yang sudah disiapkan
5. berikan permission jika belum `chmod 755 /etc/skel/.config/plank terus /plank/dock1 dan launcher kalau belum drwxr-xr-x`
6. `chmod 644 /etc/skel/.config/plank/dock/lauchers/*`

### Menghapus welcome mint
1. hapus file autostart nya `rm -r /etc/xdg/autostart/mintwelcome.desktop`

### Merubah Tema grub (opsional)
Ada 2 cara
#### Cara 1
1. Siapkan grub themes yang akan digunakan
2. Ekstra terlebih dahulu
   - zip gunakan `unzip nama-plymouth.zip -d nama-plymouth`
   - tar.gz gunakan `tar -xvf nama-plymouth.tar.gz`
3. Pindahkan `mv nama-themes-grub /boot/grub/themes/` atau `cp nama-themes-grub /boot/grub/themes/`
4. `sudo nano /etc/default/grub`
5. Edit bagian GRUB_THEME="/boot/grub/themes/nama-themes-grub/theme.txt"
6. Lalu simpan dan `sudo update-grub`
7. `sudo reboot` untuk mengecek apakah sudah terpasang
- **Note** : Jika menggunakan cubic langsung drag & drop saja tanpa `mv` atau `cp`

#### Cara 2 (jika tema yang diundah terdapat install.sh dan uninstall.sh)
1. Pastikan ada di folder tempat tema nya dengan `cd path/folder/nama-themes/`
2. lalu berikan akses ke install.sh `chmod +x install.sh`
3. `sudo ./install.sh` atau jika dicubic langsung tanpa sudo
4. `sudo reboot`
- **Note** : Jika ingin mengganti tema lakukan `./uninstall.sh` dulu dengan langkah yang sama seperti install
  
## Step 7 Merubah tampilan splash screen dan logo animasi booting

### Splash Screen booting

1. Siapkan plymouth yang akan digunakan
2. Ekstra terlebih dahulu
   - zip gunakan `unzip nama-plymouth.zip -d nama-plymouth`
   - tar.gz gunakan `tar -xvf nama-plymouth.tar.gz`
3. Pindahkan ke folder plymouth `sudo mv nama-plymouth /usr/share/plymouth/themes/`
4. Cek isi folder (opsional) `ls /usr/share/plymouth/themes/nama-plymouth`
5. Set tema plymouth baru dengan ` sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/nama-folder/nama-file.plymouth 100`
6. `sudo update-alternatives --config default.plymouth` pilih nomor plymouth yang mau digunakan
7. `sudo update-initramfs -u -k all`
- **Note** : Pastikan sebelumnya kalian sudah di folder tempat plymouth yang kalian siapkan dengan `cd ~/path-folder-plymouth `  atau jika di cubic **drag** & **drop** ke `cd /usr/share/plymouth/themes/`
- **Tambahan** : Jika ingin tes tema plymouth tanpa reboot bisa lakukan `sudo plymouthd` `sudo plymouthd --show-splash` `sudo pkill plymouthd`

### Login screen logo

1. Siapkan logo yang ingin digunakan
2. Backup logo lama (opsional) `sudo cp /usr/share/plymouth/nama-logo-distro.png{,.bak}`
3. Lalu ganti dengan logo yang disiapkan `sudo cp ~/pathfolder/nama-logo.png /usr/share/plymouth/nama-logo-distro.png`

## Step 8 Menambahkan Skrip Otomatis
1. Siapkah skrip otomatis yang ingin digunakan (direpo firstboot.sh)
2. pindahkan skrip ke `mv /path/lokasi/firstboot.sh /usr/local/bin/nama-skrip.sh`
3. Berikan akses `chmod 755 /usr/local/bin/nama-skrip.sh`
4. lalu `sudo sed -i 's/\r$//' /usr/local/bin/firstboot.sh`
5. Buat/edit sudoers `sudo visudo -f /etc/sudoers.d/auto`
6. Isi dengan `ALL ALL=(ALL) NOPASSWD: /usr/local/bin/firstboot.sh`
7. Berikan permission `sudo chmod 440 /etc/sudoers.d/auto`
8. buat autostart desktop `sudo nano /etc/skel/.config/autostart/firstboot.desktop`
9. isi dengan yang file yang telah disiapkan di autostart folder
- **Note** : folder autostart kalau belum drwxr-xr-r `chmod 755 /etc/skel/.config/autostart` terus desktopnya `chmod 644 /etc/skel/.config/autostart/*` kalau belum -rw-r--r--

## Step 9 Mengganti Menu Entry install dan slideshow
### Mengganti menu entry 
1. setelah folder project cubic ada cari folder bernama custom-disk
2. lalu ke /custom-disk/boot/grub/grub.cfg
3. ganti namanya sesuai dengan punya kita
- **Note** : jika mau yang dual bootnya juga bisa edit ke `nano /etc/os-release` dan ganti sesuai yang di inginkan yang boleh hanya NAME, PRETTY_NAME,VERSION,VERSION_CODENAME

### Mengganti slideshow waktu installasi
1. masukkan ke `cd /usr/share/ubiquity-slideshow/slides/`
2. edit file welcome.html,office.html,web.html,help.html baik deafault maupun indo , kalau indo di `/l10n/id/`
3. tambahkan icons dan screenshots yang sudah disiapkan ke folder `/icons` dan `/screenshots`
4. setelah semuanya sudah jangan lupa cek permission untuk yang *.png `chmod 644 /path/ke/arah/*.png`
5. untuk folder pakai `chmod 755`
