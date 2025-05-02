<h1>MySQL Репликация</h1>

<p>
В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp<br>
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
<ul>  
<li>bookmaker</li>
<li>competition</li>
<li>market</li>
<li>odds</li>
<li>outcome</li>
</ul>
Настроить GTID репликацию
</p>

<p>
  Vagrant mirror: https://vagrant.elab.pro<br>
  Vagrant box: ubuntu/22.04<br>
</p>

<h3>Установка Percona Sever 5.7</h3>
<p>На обоих серверах устанавливаем Percona MySQL Sever 5.7 из репозитория Percona</p>
<pre>
apt update
apt install gnupg2 -y
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
percona-release enable-only ps-57
apt install percona-server-server-5.7
</pre>
<p>В конце установки предлагается ввести пароль root сервера MySQL и его подтверждение. Поставим для простоты условный пароль, одинаковый на обоих серверах</p>
Enter root password: rootpass

<p>Поместим файлы конфигурации в каталог /etc/mysql/conf.d</p>
<pre>
systemctl stop mysql
cp /vagrant/conf/conf.d/* /etc/mysql/conf.d
chmod 644 /etc/mysql/conf.d/0*
</pre>

<p>Режим gtid включен в файле 05-binlog.cnf</p>
<pre>
log-slave-updates = On
gtid-mode = On
enforce-gtid-consistency = On
</pre>

<p>Запустим сервер MySQL</p>
<pre>
# systemctl start mysql
# systemctl status mysql
● mysql.service - Percona Server
     Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2025-05-01 19:18:21 MSK; 5min ago
    Process: 6758 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
    Process: 6803 ExecStartPre=/usr/bin/ps_mysqld_helper (code=exited, status=0/SUCCESS)
    Process: 6809 ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS (code=exited, status=0/SUCCESS)
   Main PID: 6811 (mysqld)
      Tasks: 28 (limit: 2323)
     Memory: 179.6M
        CPU: 2.314s
     CGroup: /system.slice/mysql.service
             └─6811 /usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid

May 01 19:18:21 master systemd[1]: Starting Percona Server...
May 01 19:18:21 master systemd[1]: Started Percona Server.
</pre>
<p>Убедившись, что сервер работает, подключамся к консоли MySQL</p>
<pre>
root@master:/etc/mysql/conf.d# mysql mysql -uroot -prootpass
mysql: [Warning] Using a password on the command line interface can be insecure.
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 5
Server version: 5.7.44-48 Percona Server (GPL), Release '48', Revision '497f936a373'

Copyright (c) 2009-2023 Percona LLC and/or its affiliates
Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
</pre>

<p>Чтобы репликация выполнялась успешно, нам необходимо, чтобы сервера имели разные идентификаторы: 1 и 2</p>

<h3>На сервере master</h3>

<pre>
mysql> select @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)
</pre>
<p>Режим gtid должен быть включен. </p>

<pre>
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.00 sec)
</pre>
<p>Создадим БД для теста</p>
<pre>
mysql> CREATE DATABASE bet;
Query OK, 1 row affected (0.01 sec)
</pre>
<p>Восстановим базу из логического бекапа</p>
<pre>
root@master:/etc/mysql/conf.d# mysql -uroot -prootpass -D bet < /vagrant/bet.dmp
mysql: [Warning] Using a password on the command line interface can be insecure.
</pre>

<p>Ознакомимся с составом таблиц</p>

<code>root@master:/etc/mysql/conf.d# mysql bet -uroot -prootpass</code>
<pre>
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)
</pre>

<p>
  Создаем для репликации пользователя repl c паролем !OtusLinux2018 <br>
  И дадим соответствующие права
</p>
<pre>
mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';
Query OK, 0 rows affected (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';
Query OK, 0 rows affected, 1 warning (0.00 sec)
</pre>

<p>Далее нам нужно создать логический архив базы данных для переноса на сервер slave</p>
<pre>
root@master:/vagrant# mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -prootpass > master.sql
mysqldump: [Warning] Using a password on the command line interface can be insecure.
Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events.
</pre>



<h3>На сервере slave</h3>
<p>
  В файле /etc/mysql/conf.d/05-binlog.cnf исключим из репликации ненужные таблицы: 
</p>
<pre>
replicate-ignore-table=bet.events_on_demand
replicate-ignore-table=bet.v_same_event
</pre>

<p>В файле /etc/mysql/conf.d/01-base.cnf меняем идентификатор сервера server-id=2</p>
<pre>
root@slave:/etc/mysql/conf.d# mysql mysql -uroot -prootpass
mysql> select @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.00 sec)
</pre>



<p>Восстановим БД из созданного архива</p>
<pre>
mysql> SOURCE /vagrant/master.sql

Query OK, 0 rows affected (0.00 sec)
.......
Query OK, 0 rows affected (0.00 sec)
</pre>
<p>Мы видим, что база создана:</p>
<pre>  
mysql> SHOW DATABASES LIKE 'bet';
+----------------+
| Database (bet) |
+----------------+
| bet            |
+----------------+
1 row in set (0.00 sec)
</pre>
<p>Состав таблиц:</p>
<pre>
mysql> USE bet;
Database changed
mysql> SHOW TABLES;
+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
5 rows in set (0.00 sec)
</pre>

<p>Включаем репликацию с master:</p>
<pre>
mysql> CHANGE MASTER TO MASTER_HOST = "192.168.11.150", MASTER_PORT = 3306,
MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2018", MASTER_AUTO_POSITION = 1;
Query OK, 0 rows affected, 2 warnings (0.01 sec)

mysql> START SLAVE;
Query OK, 0 rows affected (0.00 sec)
</pre>

<p>Смотрим состояние репликации:</p>
<pre>
mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000001
          Read_Master_Log_Pos: 119308
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 414
        Relay_Master_Log_File: mysql-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 119308
              Relay_Log_Space: 621
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: e483b3af-26a7-11f0-8cbf-0244a4144581
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set: e483b3af-26a7-11f0-8cbf-0244a4144581:1-38
                Auto_Position: 1
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
</pre>


<h3>На сервере master</h3>
<p>Вносим изменения в таблицу bookmaker</p>
<code>root@master:/home/vagrant# mysql bet -uroot -prootpass</code>
<pre>
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.01 sec)
</pre>
<pre>
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
</pre>

<p>Посмотрим на наше изменение в binary log:</p>
<code># mysqlbinlog /var/lib/mysql/mysql-bin.000001</code>
<pre>
SET @@SESSION.GTID_NEXT= 'e483b3af-26a7-11f0-8cbf-0244a4144581:39'/*!*/;
# at 119373
#250501 20:55:53 server id 1  end_log_pos 119446 CRC32 0xb3005762       Query   thread_id=8     exec_time=0     error_code=0
SET TIMESTAMP=1746122153/*!*/;
BEGIN
/*!*/;
# at 119446
#250501 20:55:53 server id 1  end_log_pos 119573 CRC32 0x7bb50f97       Query   thread_id=8     exec_time=0     error_code=0
SET TIMESTAMP=1746122153/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 119573
#250501 20:55:53 server id 1  end_log_pos 119604 CRC32 0x177b770c       Xid = 670
COMMIT/*!*/;
</pre>

<h3>На сервере slave</h3>
<p>Убеждаемся, что внесенные изменения отразились в реплике:</p>
<pre>
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
</pre>

<p>Записи из binlog:</p>

<code># mysqlbinlog /var/lib/mysql/mysql-bin.000002</code>
<pre>
#250501 20:55:53 server id 1  end_log_pos 219 CRC32 0x04c31985  GTID    last_committed=0        sequence_number=1       rbr_only=no
SET @@SESSION.GTID_NEXT= 'e483b3af-26a7-11f0-8cbf-0244a4144581:39'/*!*/;
# at 219
#250501 20:55:53 server id 1  end_log_pos 292 CRC32 0x58419ec4  Query   thread_id=8     exec_time=0     error_code=0
SET TIMESTAMP=1746122153/*!*/;
SET @@session.pseudo_thread_id=8/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=1077936128/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C utf8 *//*!*/;
SET @@session.character_set_client=33,@@session.collation_connection=33,@@session.collation_server=8/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
BEGIN
/*!*/;
# at 292
#250501 20:55:53 server id 1  end_log_pos 419 CRC32 0x17c748ba  Query   thread_id=8     exec_time=0     error_code=0
use `bet`/*!*/;
SET TIMESTAMP=1746122153/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 419
#250501 20:55:53 server id 1  end_log_pos 450 CRC32 0x79cbaf88  Xid = 375
COMMIT/*!*/;
</pre>
