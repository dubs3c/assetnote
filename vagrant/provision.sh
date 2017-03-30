#!/bin/bash

# Root mysql user
ROOT_DBPASSWD="CHANGE_ME_DAMNIT"

# User account
USERNAME="assetnote"
USERPW="CHANGE_ME_TOO"

# Database name
DBNAME="assetnote"

echo -e "\n================== Provisioning has begun =================="

echo -e "\n[+] Install some packages"
# Set root password for mysql-server
debconf-set-selections <<< "mysql-server mysql-server/root_password password $ROOT_DBPASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $ROOT_DBPASSWD"

apt-get update
apt-get install -y nginx \
    python3 \
    vim \
    python3-dev \
    libmysqlclient-dev \
    python3-bcrypt \
    python3-pip \
    python3-venv \
    libffi-dev \
    build-essential \
    libssl-dev \
    mysql-server


echo -e "\n[+] Setting up the mysql server"
mysql -uroot -p$ROOT_DBPASSWD -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$USERPW';" >> /vagrant_data/logs/vm_build.log 2>&1
mysql -uroot -p$ROOT_DBPASSWD -e "CREATE DATABASE $DBNAME" >> /vagrant_data/logs/vm_build.log 2>&1
mysql -uroot -p$ROOT_DBPASSWD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$USERNAME'@'localhost' IDENTIFIED BY '$USERPW'" > /vagrant_data/logs/vm_build.log 2>&1
mysql -uroot -p$ROOT_DBPASSWD -e "FLUSH PRIVILEGES"


echo -e "\n[+] Copying to /var/www/assetnote"
cp -r /vagrant_data/ /var/www/assetnote
chown -R vagrant:vagrant /var/www/assetnote
cd /var/www/assetnote
#su assetnote

# Remove old database
rm assetnote.db

echo -e "\n[+] Setting up python virtual environment"
# Initialize python libs
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt

cp /vagrant_data/vagrant/gunicorn.service /etc/systemd/system/gunicorn.service

echo -e "\n[+] Setting up Nginx"
# Nginx
rm /etc/nginx/sites-available/default
cp /vagrant_data/vagrant/assetnote.vhost.conf /etc/nginx/sites-available/assetnote.vhost.conf
ln -s /etc/nginx/sites-available/assetnote.vhost.conf /etc/nginx/sites-enabled/assetnote.vhost.conf

# Run gunicorn, which runs the app
systemctl enable gunicorn
systemctl start gunicorn

systemctl enable nginx
systemctl start nginx
systemctl reload nginx

echo -e "\n[+] Adding cronjob"
crontab vagrant/cronjob

echo -e "\n[~] Done."
