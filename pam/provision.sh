#!/usr/bin/bash
#cat /vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
timedatectl set-timezone Europe/Moscow
#apt-get update
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd.service

useradd -m otusadm && useradd -m otus
echo "otusadm:Otus2022!" | chpasswd
echo "otus:Otus2022!" | chpasswd
groupadd -f admin
usermod otusadm -a -G admin && usermod root -a -G admin && usermod vagrant -a -G admin
cp /vagrant/login.sh /usr/local/bin/login.sh
chmod +x /usr/local/bin/login.sh

cat /vagrant/sshd > /etc/pam.d/sshd
