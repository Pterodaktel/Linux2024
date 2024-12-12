<H1>NFS: Развернуть сервер с NFS и подключить на клиенте сетевую директорию</H1>
<ul>
<li>vagrant up должен поднимать 2 виртуалки: сервер и клиент;</li>
<li>на сервере должна быть настроена директория для отдачи по NFS;</li>
<li>на клиенте она должна автоматически монтироваться при старте (fstab или autofs);</li>
<li>в сетевой директории должна быть папка upload с правами на запись;</li>
<li>требования для NFS: NFS версии 3.</li>
<li>*Настроить аутентификацию через KERBEROS (NFSv4)</li>
</ul>
<p>Доп. задание выполняется по желанию.</p>

<p>Подготовка стенда (bento/ubuntu-24.04): Vagrantfile </p>
<p>
  В provision сервера и клиента включены bash-скрипты nfss_script.sh и nfsс_script.sh соответственно.
  При поднятии виртуальных машин на клиенте монтируется каталог с сервера по протоколу NFS 3.
  В конце указанных скриптов в комментариях - конспект команд выполнения дополнительного задания.
  Некоторые выполнялись интерактивно.
</p>

<h2>Дополнительное задание</h2>

<h3>Примерный конспект действий на сервере:</h3>
<br>
Расшариваем каталог:<br>
<code>
#mkdir -p /srv/kshare/upload<br>
#chown nobody:nogroup /srv/kshare/upload<br>
#chmod 0777 /srv/kshare/upload<br>
#echo "/srv/kshare *(rw,sync,no_subtree_check,sec=krb5p)" >> /etc/exports<br>
</code><br>
<br>
Открыть порт керберос:<br>
<code>#ufw allow from any to any port 88</code><br>
Установка демона синхронизации времени (можно было оставить на совести Virtualbox)<br>
<code>#apt-get install chrony -y<br>
#systemctl start chronyd<br></code>
<br>
Настройка разрешения имен:<br>
<code>#echo "192.168.11.10 nfss.nfsnet.local nfss" >> /etc/hosts<br>
#echo "192.168.11.11 nfsc.nfsnet.local nfsc" >> /etc/hosts</code><br>
<br>
#modprobe rpcsec_gss_krb5<br>
Необходимые пакеты MIT Kerberos:<br>
<code>#apt-get install krb5-kdc krb5-admin-server krb5-user -y<br></code>
<br>
Создадим новый realm Kerberos "NFSNET.LOCAL"<br>
<code>#krb5_newrealm<br></code>
<br>
Создание принципала администратора<br>
<code>#kadmin.local addprinc adminuser/admin<br>
#echo "*/admin *" >> /etc/krb5kdc/kadm5.acl</code><br>
<code>#systemctl restart krb5-admin-server<br>
#systemctl enable krb5-kdc krb5-admin-server<br></code>
<br>
Создание принципалов с ключами для машин сервера и клиента:<br>
<code>#kadmin.local -q "addprinc -randkey nfs/nfss.nfsnet.local"<br>
#kadmin.local -q "addprinc -randkey nfs/nfsc.nfsnet.local"<br></code>
<br>
Экспорт ключа сервера в локальную таблицу keytab:<br>
<code>#kadmin.local -q "ktadd nfs/nfss.nfsnet.local"<br></code>
<br>
В /etc/nfs.conf в [gssd] указываем preferred-realm=NFSNET.LOCAL<br>
<br>

<h3>Примерный конспект действий на клиенте:</h3>
<code>
#apt-get install chrony krb5-user -y<br>
#systemctl start chronyd<br>
#echo "192.168.11.11 nfsc.nfsnet.local nfsc" >> /etc/hosts<br>
#echo "192.168.11.10 nfss.nfsnet.local nfss" >> /etc/hosts<br>
#modprobe rpcsec_gss_krb5<br>
#kadmin -p adminuser/admin -q "ktadd nfs/nfsc.nfsnet.local"<br></code>
<br>
<br>
<code>#mount.nfs4 nfss.nfsnet.local:/srv/kshare /mnt/knfs</code><br>

<br>
<code>#nfsstat -m<br>
/mnt/knfs from nfss.nfsnet.local:/srv/kshare<br>
 Flags: rw,relatime,vers=4.2,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=krb5p,clientaddr=192.168.11.11,local_lock=none,addr=192.168.11.10
</code>
<br>
