<h1>Централизованный сбор логов</h1>

<p>
В вагранте поднимаем 2 машины web и log. 
На web поднимаем nginx.
На log настраиваем центральный лог сервер rsyslog.
Настраиваем аудит, следящий за изменением конфигов нжинкса.
</p>
<p>
Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.  
</p>

<p>Для аудита изменений каталога конфигурации nginx используется правило "-w /etc/nginx/ -p wa -k nginx_configs"<br>
Оно вставляется в файл /etc/audit/rules.d/audit.rules<br>                                                                                                                  
Если нужно временно применить это правило, используется команда "auditctl -w /etc/nginx/ -p wa -k nginx_configs"
</p>

<h3>Проверка</h3>

<code></code># aureport -i -k</code>
<pre>
Key Report
===============================================
# date time key success exe auid event
===============================================
1. 02/22/25 14:03:41 nginx_configs yes /usr/sbin/auditctl unset 47
2. 02/22/25 14:25:22 nginx_configs yes /usr/bin/mc vagrant 100
3. 02/22/25 14:25:25 nginx_configs yes /usr/bin/mc vagrant 101
4. 02/22/25 14:25:25 nginx_configs yes /usr/bin/mc vagrant 102
5. 02/22/25 14:25:25 nginx_configs yes /usr/bin/mc vagrant 103
6. 02/22/25 14:25:25 nginx_configs yes /usr/bin/mc vagrant 104
</pre>


<code># ll /var/log/rsyslog</code>
<pre>
total 20
drwxr-xr-x  5 syslog syslog 4096 Feb 22 13:57 ./
drwxrwxr-x 10 root   syslog 4096 Feb 22 14:21 ../
drwxr-xr-x  2 syslog syslog 4096 Feb 22 14:17 log/
drwxr-xr-x  2 syslog syslog 4096 Feb 22 14:17 other/
drwxr-xr-x  2 syslog syslog 4096 Feb 22 14:11 web/
</pre>

<p>Все логи с машины other отправляются на машину log.</p>
<code># ll /var/log/rsyslog/other</code>
<pre>
total 48
drwxr-xr-x 2 syslog syslog 4096 Feb 22 14:17 ./
drwxr-xr-x 5 syslog syslog 4096 Feb 22 13:57 ../
-rw-r----- 1 syslog adm     286 Feb 22 14:17 CRON.log
-rw-r----- 1 syslog adm     172 Feb 22 13:37 chronyd.log
-rw-r----- 1 syslog adm     353 Feb 22 13:42 dbus-daemon.log
-rw-r----- 1 syslog adm     322 Feb 22 13:37 multipath.log
-rw-r----- 1 syslog adm    1792 Feb 22 13:37 multipathd.log
-rw-r----- 1 syslog adm    1338 Feb 22 14:07 rsyslogd.log
-rw-r----- 1 syslog adm     174 Feb 22 13:37 sshd.log
-rw-r----- 1 syslog adm      81 Feb 22 13:37 sudo.log
-rw-r----- 1 syslog adm     158 Feb 22 13:37 systemd-logind.log
-rw-r----- 1 syslog adm    3841 Feb 22 14:07 systemd.log
</pre>

<code># ll /var/log/rsyslog/web</code>
<pre>
total 76
drwxr-xr-x 2 syslog syslog  4096 Feb 22 14:11 ./
drwxr-xr-x 5 syslog syslog  4096 Feb 22 13:57 ../
-rw-r----- 1 syslog adm    58664 Feb 22 14:18 audit.log
-rw-r----- 1 syslog adm     1157 Feb 22 14:20 nginx_access.log
-rw-r----- 1 syslog adm      208 Feb 22 14:11 nginx_error.log
</pre>

<code># tail /var/log/rsyslog/web/audit.log</code>
<pre>
Feb 22 14:25:25 web audit type=SYSCALL msg=audit(1740223525.615:103): arch=c000003e syscall=257 success=yes exit=16 a0=ffffff9c a1=5594339bb340 a2=241 a3=81a4 items=2 ppid=4615 pid=4617 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=4 comm="mcedit" exe="/usr/bin/mc" subj=unconfined key="nginx_configs"#035ARCH=x86_64 SYSCALL=openat AUID="vagrant" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
Feb 22 14:25:25 web audit type=CWD msg=audit(1740223525.615:103): cwd="/etc/nginx"
Feb 22 14:25:25 web audit type=PATH msg=audit(1740223525.615:103): item=0 name="/etc/nginx/" inode=256406 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 nametype=PARENT cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0#035OUID="root" OGID="root"
Feb 22 14:25:25 web audit type=PATH msg=audit(1740223525.615:103): item=1 name="/etc/nginx/nginx.conf" inode=256415 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0#035OUID="root" OGID="root"
Feb 22 14:25:25 web audit type=PROCTITLE msg=audit(1740223525.615:103): proctitle=2F7573722F62696E2F6D6365646974002F6574632F6E67696E782F6E67696E782E636F6E66
Feb 22 14:25:25 web audit type=SYSCALL msg=audit(1740223525.615:104): arch=c000003e syscall=87 success=yes exit=0 a0=5594339b4590 a1=1209 a2=0 a3=7f265781cac0 items=2 ppid=4615 pid=4617 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=4 comm="mcedit" exe="/usr/bin/mc" subj=unconfined key="nginx_configs"#035ARCH=x86_64 SYSCALL=unlink AUID="vagrant" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
Feb 22 14:25:25 web audit type=CWD msg=audit(1740223525.615:104): cwd="/etc/nginx"
Feb 22 14:25:25 web audit type=PATH msg=audit(1740223525.615:104): item=0 name="/etc/nginx/" inode=256406 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 nametype=PARENT cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0#035OUID="root" OGID="root"
Feb 22 14:25:25 web audit type=PATH msg=audit(1740223525.615:104): item=1 name="/etc/nginx/.#nginx.conf" inode=256870 dev=08:01 mode=0120777 ouid=0 ogid=0 rdev=00:00 nametype=DELETE cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0#035OUID="root" OGID="root"
Feb 22 14:25:25 web audit type=PROCTITLE msg=audit(1740223525.615:104): proctitle=2F7573722F62696E2F6D6365646974002F6574632F6E67696E782F6E67696E782E636F6E66
</pre>
