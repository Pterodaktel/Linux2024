<h1>Аутентификация пользователей. Работа с PAM</h1>
<p>Запретить всем пользователям кроме группы admin логин по ssh в выходные (суббота и воскресенье). <br>
* дать конкретному пользователю права работать с докером и возможность перезапускать докер сервис</p>

Vagrant mirror: https://vagrant.elab.pro<br>
Vagrant box: ubuntu/22.04

<p>Сщзданы пользователи otus и otusadm. Второй добавлен в созданную группу admin</p>
<p>Скрипт проверки помещен в /usr/local/bin/login.sh</p>
<p>В файл /etc/pam.d/sshd добавлен строчка <code>auth required pam_exec.so debug /usr/local/bin/login.sh</code></p>

<p>Результат проверки:</p>
<code>tail /var/log/auth.log</code>
<pre>
Feb  9 18:03:37 pam sshd[1748]: pam_exec(sshd:auth): /usr/local/bin/login.sh failed: exit code 1
Feb  9 18:03:40 pam sshd[1748]: Failed password for otus from 192.168.11.50 port 36138 ssh2
Feb  9 18:03:43 pam sshd[1748]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=192.168.11.50  user=otus
Feb  9 18:03:46 pam sshd[1748]: Failed password for otus from 192.168.11.50 port 36138 ssh2
Feb  9 18:03:47 pam sshd[1748]: Connection closed by authenticating user otus 192.168.11.50 port 36138 [preauth]
Feb  9 18:04:12 pam sshd[1799]: pam_exec(sshd:auth): Calling /usr/local/bin/login.sh ...
Feb  9 18:04:12 pam sshd[1787]: Accepted password for otusadm from 192.168.11.50 port 43324 ssh2
Feb  9 18:04:12 pam sshd[1787]: pam_unix(sshd:session): session opened for user otusadm(uid=1002) by (uid=0)
Feb  9 18:04:12 pam systemd-logind[640]: New session 16 of user otusadm.
Feb  9 18:04:12 pam systemd: pam_unix(systemd-user:session): session opened for user otusadm(uid=1002) by (uid=0)
</pre>

<h3>* Права на работу с docker</h3>
<p>Для наделения пользователя правами работы с docker достаточно добавить этого пользователя в группу docker.<br>
  Необходимые политики создаются при установке docker.
  Для пробы добавим пользователя otusadm в группу docker.
</p>

<pre>
usermod -aG docker otusadm
newgrp docker
</pre>

<p>Проверяем:</p>

<code>$ systemctl restart docker</code>
<pre>
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to start 'docker.service'.
Multiple identities can be used for authentication:
 1.  Ubuntu (ubuntu)
 2.  otusadm
 3.  ,,, (vagrant)
Choose identity to authenticate as (1-3): 2
Password:
==== AUTHENTICATION COMPLETE ===
</pre>
