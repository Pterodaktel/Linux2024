#!/usr/bin/bash
# install nfs server
apt-get install nfs-kernel-server -y
#make dir to share
mkdir -p /srv/share/upload
chown nobody:nogroup /srv/share/upload
chmod 0777 /srv/share/upload

# share to client
cat <<EOF >> /etc/exports
/srv/share 192.168.11.11/32(rw,sync,no_subtree_check,root_squash)
EOF
exportfs -r
exportfs -s

# configure and enable firewall
ufw allow proto tcp to any port ssh
ufw allow from any to any port nfs
ufw allow from any to any port 111
ufw allow proto udp from any to any port 49152:65535
ufw enable

# adjust correct timezone
timedatectl set-timezone Europe/Moscow

 
#cat /vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
#cat /vagrant/id_ed25519.pub >> /root/.ssh/authorized_keys

#ufw allow from any to any port 88
#apt-get install chrony -y
#systemctl start chronyd
#echo "192.168.11.10 nfss.nfsnet.local nfss" >> /etc/hosts
#echo "192.168.11.11 nfsc.nfsnet.local nfsc" >> /etc/hosts

#apt-get install krb5-kdc krb5-admin-server krb5-user -y
#krb5_newrealm

## create a key for the NFS server and client:
#kadmin.local -q "addprinc -randkey nfs/nfss.nfsnet.local"
#kadmin.local -q "addprinc -randkey nfs/nfsc.nfsnet.local"
## extract the key into the local keytab:
#kadmin.local -q "ktadd nfs/nfss.nfsnet.local"
#kadmin.local -q "ktadd nfs/nfsc.nfsnet.local"
#modprobe rpcsec_gss_krb5
