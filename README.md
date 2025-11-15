# Project-Remasterin-Ubuntu

## Step 1 Lakukan Pembaruan pertama kali install
```sudo apt update && sudo apt upgrade -y```

## Step 2 install cubic 
1. ```sudo apt-add-repository universe```
2. ```sudo apt-add-repository ppa:cubic-wizard/release```
3. ```sudo apt update```
4. ```sudo apt install cubic```

## Step 3 Modifikasi parameter boot kernel
1. ```sudo nano /etc/default/grub```
2. Cari GRUB_CMDLINE_LINUX_DEFAULT
3. Edit isinya menjadi GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 panic=10 fsck.mode=auto fsck.repair=yes"

## Step 4 install aplikasi yang dibutuhkan
### Install python
1. ```sudo apt install -y python3 python3-pip python3-venv```
2. Cek apakah sudah terinstall dengan benar menggunakan
   * ```python3 --version```
   * ```pip3 --version```

### Install GCC
1. ```sudo apt install -y build-essential```
2. Cek apakah sudah terinstall dengan benar menggunakan
   * ```gcc --version```
   * ```g++ --version```
   * ```make --version```

### Install OpenJDK
1. Cek versi Java yang tersedia ```apt search -jdk --names-only```
2. Lalu install sesuai dengan versi yang di inginkan ```sudo apt install -y openjdk-xx-jdk```
3. Cek apakah sudah terinstall dengan benar menggunakan
   * ```java -version```
   * ```javac -version```

### Install Node.Js
1. Jika curl belum terinstall ```sudo apt-get install curl```
2. Jika sudah ada langsung ```curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -```
3. ```sudo apt-get install nodejs```
4.  Cek apakah sudah terinstall dengan benar menggunakan
   * ```node -v```
   * ```npm -v```


