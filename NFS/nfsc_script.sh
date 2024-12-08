#!/usr/bin/bash
# install coomon nfs client lib
apt-get install nfs-common -y
# make target dir 
mkdir /mnt/nfs
# update fstab for using NFS v3 for automunt network share
echo "192.168.11.10:/srv/share/ /mnt/nfs nfs vers=3,_netdev,auto 0 0" >> /etc/fstab
# mount for the fist time
mount.nfs -o vers=3 192.168.11.10:/srv/share /mnt/nfs
# correct timezone
timedatectl set-timezone Europe/Moscow

#cat /vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
#cat /vagrant/id_ed25519.pub >> /root/.ssh/authorized_keys

#apt-get install chrony krb5-user -y
#systemctl start chronyd
#echo "192.168.11.11 nfsc.nfsnet.local nfsc" >> /etc/hosts
#echo "192.168.11.10 nfss.nfsnet.local nfss" >> /etc/hosts
#modprobe rpcsec_gss_krb5
