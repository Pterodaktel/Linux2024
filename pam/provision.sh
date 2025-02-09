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

# docker
apt-get update
apt-get install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
usermod -aG docker otusadm
newgrp docker
