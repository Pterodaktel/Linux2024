<h1>PostgreSQL: репликация и backup</h1>
<ol>
<li>Настроить hot_standby репликацию с использованием слотов</li>
<li>Настроить правильное резервное копирование</li>
</ol>

<p>
  Vagrant mirror: https://vagrant.elab.pro<br>
  Vagrant box: ubuntu/jammy64<br>
</p>
<p>Установка сервера postgresql</p>
<pre>
apt install postgresql postgresql-contrib
systemctl start postgresql
</pre>

<h2>Настройка репликаци на хостах node1 и node2</h2>

<h3>На хосте node1:</h3>
<p>Создадим пользователя для репликации</p>
<pre>
root@node1:/home/vagrant# sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (14.17 (Ubuntu 14.17-0ubuntu0.22.04.1))
Type "help" for help.

postgres=#
postgres=# CREATE USER replicator WITH REPLICATION Encrypted PASSWORD 'Otus2022!';
CREATE ROLE
</pre>

<p>Измененим файлы конфигурации и перезапустим postgres</p>

vim /etc/postgresql/14/main/postgresql.conf<br>
vim /etc/postgresql/14/main/pg_hba.conf

<pre>
systemctl restart postgresql
root@node1:/home/vagrant# systemctl status postgresql
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
     Active: active (exited) since Sat 2025-05-03 14:21:11 MSK; 8s ago
    Process: 5685 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
   Main PID: 5685 (code=exited, status=0/SUCCESS)
        CPU: 1ms

May 03 14:21:11 node1 systemd[1]: Starting PostgreSQL RDBMS...
May 03 14:21:11 node1 systemd[1]: Finished PostgreSQL RDBMS.
</pre>

<h3>На хосте node2:</h3>
<p>Удалим файлы кластера</p>
<pre>
systemctl stop postgresql
rm -Rf /var/lib/postgresql/14/main/*
</pre>
<p>Нужно сделать копию кластера на сервер репликации</p>
<pre>
pg_basebackup -h 192.168.11.11 -U replicator -p 5432 -D /var/lib/postgresql/14/main/ -R -P
Password:
26275/26275 kB (100%), 1/1 tablespace
</pre>
<p>Восстановим права</p>
<code>chown -R postgres:postgres /var/lib/postgresql/14/main/*</code><br>
Также внесем изменения в файл конфигурации:
<pre>
vim /etc/postgresql/14/main/postgresql.conf
systemctl start postgresql
</pre>

<h3>На хосте node1:</h3>

<p>Создадим тестовую базу и убедимся в начале репликации</p>
<pre>
sudo -u postgres psql

postgres=# CREATE DATABASE otus_test;
CREATE DATABASE

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(4 rows)

postgres=#  select * from pg_stat_replication;

 pid  | usesysid |  usename   | application_name |  client_addr  | client_hostname | client_port |         backend_start         | backend_xmin |   state   | sent_lsn  | write_lsn | flush_lsn | replay_lsn | write_lag | flush_lag | replay_lag | sync_priority | sync_state |          reply_time
------+----------+------------+------------------+---------------+-----------------+-------------+-------------------------------+--------------+-----------+-----------+-----------+-----------+------------+-----------+-----------+------------+---------------+------------+-------------------------------
 6376 |    16384 | replicator | 14/main          | 192.168.11.12 |                 |       37816 | 2025-05-03 17:41:27.132155+03 |              | streaming | 0/3000AF0 | 0/3000AF0 | 0/3000AF0 | 0/3000AF0  |           |           |            |             0 | async      | 2025-05-03 17:47:38.083443+03
(1 row)
</pre>

<h3>На хосте node2:</h3>
Убеждаемся в успешной репликации созданной БД: 
<pre>
root@node2:/etc/postgresql/14/main# sudo -u postgres psql
psql (14.17 (Ubuntu 14.17-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# \L
invalid command \L
Try \? for help.
postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(4 rows)

select * from pg_stat_wal_receiver;

pid  |  status   | receive_start_lsn | receive_start_tli | written_lsn | flushed_lsn | received_tli |      last_msg_send_time       |     last_msg_receipt_time     | latest_end_lsn |        latest_end_time        | slot_name |  sender_host  | sender_port |                                                                                                                                      conninfo
------+-----------+-------------------+-------------------+-------------+-------------+--------------+-------------------------------+-------------------------------+----------------+-------------------------------+-----------+---------------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 6283 | streaming | 0/3000000         |                 1 | 0/3000AF0   | 0/3000AF0   |            1 | 2025-05-03 17:45:57.800556+03 | 2025-05-03 17:45:57.799361+03 | 0/3000AF0      | 2025-05-03 17:41:27.141861+03 |           | 192.168.11.11 |        5432 | user=replicator password=******** channel_binding=prefer dbname=replication host=192.168.11.11 port=5432 fallback_application_name=14/main sslmode=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
(1 row)

(END)
</pre>

<h2>Резервное копирование c помощью barman</h2>

<p>На хостах node1 и node2 установим необходимое ПО: <code>apt install barman-cli</code></p>

<p>На хосте barman: <code>apt install barman-cli barman postgresql</code></p>

<h3>На хосте node1:</h3>
<p>Нужно настроить двустороннюю авторизацию по ssh</p>
<pre>
root@node1:/var/lib/postgresql/14/main# su postgres
postgres@node1:~/14/main$ cd

postgres@node1:~$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/var/lib/postgresql/.ssh/id_rsa):
Created directory '/var/lib/postgresql/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /var/lib/postgresql/.ssh/id_rsa
Your public key has been saved in /var/lib/postgresql/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:hHWCDC2H9eysTvoxWnNWq+5glCXQINPB4pPtaWHmAus postgres@node1
The key's randomart image is:
+---[RSA 4096]----+
|  oo=X..o .      |
|  .o=.*= o       |
| . + oo =        |
|. + =  B         |
| o * oo S .      |
|. . =. . . .     |
|.  o  X . .      |
| E   B B .       |
|    o.oo+        |
+----[SHA256]-----+

postgres@node1:~$ cat ~/.ssh/id_rsa.pub
</pre>
<p>Содержимое id_rsa.pub нужно поместить на хост barman в authorized_keys одноименного пользователя</p>

<h3>На хосте barman:</h3>
<p>Продолжение настройки авторизации по ssh:</p>
<pre>
barman@barman:~$ mkdir .ssh
vim /var/lib/barman/.ssh/authorized_keys

root@barman:/var/lib/barman/.ssh# su barman
barman@barman:~/.ssh$ cd
barman@barman:~$ pwd
/var/lib/barman
barman@barman:~$ ssh-leygen -t rsa -b 4096
Command 'ssh-leygen' not found, did you mean:
  command 'ssh-keygen' from deb openssh-client (1:8.9p1-3ubuntu0.11)
Try: apt install <deb name>
barman@barman:~$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/var/lib/barman/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /var/lib/barman/.ssh/id_rsa
Your public key has been saved in /var/lib/barman/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:WpyDeWED2sNYxIct9BV1/OCslf2wye1g+PgzbXvnUSU barman@barman
The key's randomart image is:
+---[RSA 4096]----+
|     +=o  oo...  |
|     *+oo.   .o  |
|    o +o=    oE=.|
|       * +    *.+|
|      o S    = =o|
|       + .  o * +|
|      .      + = |
|            . + B|
|             ..*=|
+----[SHA256]-----+

root@barman:/var/lib/barman/.ssh# cat ./id_rsa.pub
</pre>

<h3>На хосте node1:</h3>
<code>postgres@node1:~/.ssh$ vim /var/lib/postgresql/.ssh/authorized_keys</code>

<p>На сервере node1 cоздадим postgres-пользователя barman. Согласно официальному руководству назначим необходимые права</p>
<pre>
#psql
postgres=# CREATE USER barman WITH REPLICATION Encrypted PASSWORD 'Otus2022!';
CREATE ROLE
postgres=# GRANT EXECUTE ON FUNCTION pg_start_backup(text, boolean, boolean) to barman;
GRANT
postgres=# GRANT EXECUTE ON FUNCTION pg_stop_backup() to barman;
GRANT
postgres=# GRANT EXECUTE ON FUNCTION pg_stop_backup(boolean, boolean) to barman;
GRANT
postgres=# GRANT pg_read_all_settings TO barman;
GRANT ROLE
postgres=# GRANT pg_read_all_stats TO barman;
GRANT ROLE
postgres=# GRANT EXECUTE ON FUNCTION pg_switch_wal() to barman;
GRANT
postgres=# GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) to barman;
GRANT
</pre>
<p>Разрешим доступ пользователю по сети</p>
<pre>
/etc/postgresql/14/main/pg_hba.conf
systemctl restart postgresql
</pre>
Создание тестовой БД с таблицей:
<pre>
postgres=#  CREATE DATABASE otus;
CREATE DATABASE
postgres=# \c otus;
You are now connected to database "otus" as user "postgres".

otus=# CREATE TABLE test (id int, name varchar(30));
CREATE TABLE
otus=# INSERT INTO test VALUES (1, 'alex');
INSERT 0 1
</pre>

<h3>На хосте barman:</h3>

<pre>
barman@barman:~$ vim ~/.pgpass
chmod 600 ~/.pgpass

barman@barman:~$ psql -h 192.168.11.11 -U barman -d postgres
psql (14.17 (Ubuntu 14.17-0ubuntu0.22.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=>

barman@barman:~$ psql -h 192.168.11.11 -U barman -c "IDENTIFY_SYSTEM" replication=1
      systemid       | timeline |  xlogpos  | dbname
---------------------+----------+-----------+--------
 7500169290049856550 |        1 | 0/301A368 |
(1 row)
</pre>


# touch /etc/barman.conf
touch /etc/barman.d/node1.conf

<pre>
barman@barman:/etc$ psql -c 'SELECT version()' -U barman -h 192.168.11.11 postgres
                                                                version
----------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 14.17 (Ubuntu 14.17-0ubuntu0.22.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, 64-bit
(1 row)
</pre>

<pre>
barman@barman:/var/log/barman$ barman switch-wal node1
The WAL file 000000010000000000000003 has been closed on server 'node1'
</pre>
<pre>
barman@barman:/var/log/barman$ barman cron
Starting WAL archiving for server node1
Starting check-backup for backup 20250504T194106 of server node1
</pre>
<pre>
barman@barman:/var/log/barman$ barman backup node1
Starting backup using postgres method for server node1 in /var/lib/barman/node1/base/20250504T194106
Backup start at LSN: 0/4000060 (000000010000000000000004, 00000060)
Starting backup copy via pg_basebackup for 20250504T194106
WARNING: pg_basebackup does not copy the PostgreSQL configuration files that reside outside PGDATA. Please manually backup the following files:
        /etc/postgresql/14/main/postgresql.conf
        /etc/postgresql/14/main/pg_hba.conf
        /etc/postgresql/14/main/pg_ident.conf

Copy done (time: less than one second)
Finalising the backup.
This is the first backup for server node1
WAL segments preceding the current backup have been found:
        000000010000000000000003 from server node1 has been removed
Backup size: 41.8 MiB
Backup end at LSN: 0/6000000 (000000010000000000000005, 00000000)
Backup completed (start time: 2025-05-04 19:41:06.734531, elapsed time: less than one second)
Processing xlog segments from streaming for node1
        000000010000000000000004
WARNING: IMPORTANT: this backup is classified as WAITING_FOR_WALS, meaning that Barman has not received yet all the required WAL files for the backup consistency.
This is a common behaviour in concurrent backup scenarios, and Barman automatically set the backup as DONE once all the required WAL files have been archived.
Hint: execute the backup command with '--wait'
</pre>

<pre>
barman@barman:/var/log/barman$ barman check node1
Server node1:
        PostgreSQL: OK
        superuser or standard user with backup privileges: OK
        PostgreSQL streaming: OK
        wal_level: OK
        replication slot: OK
        directories: OK
        retention policy settings: OK
        backup maximum age: OK (interval provided: 4 days, latest backup age: 1 hour, 4 minutes, 55 seconds)
        backup minimum size: OK (41.8 MiB)
        wal maximum age: OK (no last_wal_maximum_age provided)
        wal size: OK (0 B)
        compression settings: OK
        failed backups: OK (there are 0 failed backups)
        minimum redundancy requirements: OK (have 1 backups, expected at least 1)
        pg_basebackup: OK
        pg_basebackup compatible: OK
        pg_basebackup supports tablespaces mapping: OK
        systemid coherence: OK
        pg_receivexlog: OK
        pg_receivexlog compatible: OK
        receive-wal running: OK
        archiver errors: OK
</pre>


<h3>На хосте node1:</h3>
<pre>
postgres=# \l
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
</pre>

<pre>
postgres=# DROP DATABASE otus;
DROP DATABASE
postgres=# DROP DATABASE otus_test;
DROP DATABASE
</pre>

<h3>На хосте barman:</h3>
<pre>
barman@barman:/var/log/barman$ barman list-backup node1
node1 20250504T194106 - Sun May  4 19:41:07 2025 - Size: 41.8 MiB - WAL Size: 0 B
</pre>

<pre>
barman@barman:/var/log/barman$ barman recover node1 20250504T194106 /var/lib/postgresql/14/main/ --remote-ssh-command "ssh postgres@192.168.11.11"
Starting remote restore for server node1 using backup 20250504T194106
Destination directory: /var/lib/postgresql/14/main/
Remote command: ssh postgres@192.168.11.11
Copying the base backup.
Copying required WAL segments.
Generating archive status files
Identify dangerous settings in destination directory.

WARNING
The following configuration files have not been saved during backup, hence they have not been restored.
You need to manually restore them in order to start the recovered PostgreSQL instance:

    postgresql.conf
    pg_hba.conf
    pg_ident.conf

Recovery completed (start time: 2025-05-04 20:50:12.243793, elapsed time: 4 seconds)

Your PostgreSQL server has been successfully prepared for recovery!
</pre>

<h3>На хосте node1:</h3>

<pre>
root@node1:/etc/postgresql/14/main# systemctl restart  postgresql
root@node1:/etc/postgresql/14/main# su postgres
postgres@node1:/etc/postgresql/14/main$ psql
psql (14.17 (Ubuntu 14.17-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges
-----------+----------+----------+---------+---------+-----------------------
 otus      | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 otus_test | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 postgres  | postgres | UTF8     | C.UTF-8 | C.UTF-8 |
 template0 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
 template1 | postgres | UTF8     | C.UTF-8 | C.UTF-8 | =c/postgres          +
           |          |          |         |         | postgres=CTc/postgres
(5 rows)
</pre>

