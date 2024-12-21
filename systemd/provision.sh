#!/usr/bin/bash
#cat /vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
timedatectl set-timezone Europe/Moscow 

#Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова ALERT
cat /vagrant/watchlog > /etc/default/watchlog
cat /vagrant/watchlog.sh > /opt/watchlog.sh
chmod +x /opt/watchlog.sh
cat /vagrant/watchlog.service > /etc/systemd/system/watchlog.service
cat /vagrant/watchlog.timer > /etc/systemd/system/watchlog.timer
cat /vagrant/watchlog.log > /var/log/watchlog.log
systemctl daemon-reload
systemctl start watchlog.timer

# Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта
apt-get update
apt-get install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
mkdir /etc/spawn-fcgi
cat /vagrant/fcgi.conf > /etc/spawn-fcgi/fcgi.conf
cat /vagrant/spawn-fcgi.service > /etc/systemd/system/spawn-fcgi.service
systemctl start spawn-fcgi

# nginx@.service для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно
systemctl disable apache2
systemctl stop apache2
apt-get install nginx -y
systemctl status nginx
cp '/vagrant/nginx@.service' '/etc/systemd/system/nginx@.service'
chmod 640 '/etc/systemd/system/nginx@.service'
cat /vagrant/nginx-first.conf > /etc/nginx/nginx-first.conf
cat /vagrant/nginx-second.conf > /etc/nginx/nginx-second.conf
systemctl start nginx@first
systemctl start nginx@second

