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

Конспект действий на сервере:

Открыть порт керберос:
#ufw allow from any to any port 88
Установка демона синхронизации времени (можно было оставить на совести Virtualbox)
#apt-get install chrony -y
#systemctl start chronyd

Настройка разрешения имен:
#echo "192.168.11.10 nfss.nfsnet.local nfss" >> /etc/hosts
#echo "192.168.11.11 nfsc.nfsnet.local nfsc" >> /etc/hosts

Необходимые пакеты MIT Kerberos:
#apt-get install krb5-kdc krb5-admin-server krb5-user -y

Создадим новый realm Kerberos "NFSNET.LOCAL"
#krb5_newrealm

Создание принципала администратора
#kadmin.local addprinc adminuser/admin

#systemctl restart krb5-admin-server
#systemctl enable krb5-kdc krb5-admin-server

Создание принципалов с ключами для машин сервера и клиента:
#kadmin.local -q "addprinc -randkey nfs/nfss.nfsnet.local"
#kadmin.local -q "addprinc -randkey nfs/nfsc.nfsnet.local"

Экспорт ключа сервера в локальную таблицу keytab:
#kadmin.local -q "ktadd nfs/nfss.nfsnet.local"

