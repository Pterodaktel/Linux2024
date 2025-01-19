<h1>Практика c SELinux</h1>

<h2>Часть 1. Запустить Nginx на нестандартном порту 3-мя разными способами:</h2>
<ul>
<li>переключатели setsebool;</li>
<li>добавление нестандартного порта в имеющийся тип;</li>
<li>формирование и установка модуля SELinux.</li>
</ul>

<p>Vagrant box: Almalinux/9</p>

<code># systemctl status nginx</code>
<pre>     
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Sat 2025-01-18 12:03:11 UTC; 19min ago
   Duration: 3min 1.940s
    Process: 6486 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6487 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 11ms

Jan 18 12:03:11 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 18 12:03:11 selinux nginx[6487]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 18 12:03:11 selinux nginx[6487]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Jan 18 12:03:11 selinux nginx[6487]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jan 18 12:03:11 selinux systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Jan 18 12:03:11 selinux systemd[1]: nginx.service: Failed with result 'exit-code'.
Jan 18 12:03:11 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
</pre>


<p>Мы видим, что nginx не запустился с привязкой к порту 4881 из-за отсутствия разрешений: "bind() to 0.0.0.0:4881 failed (13: Permission denied)" </p>

Проверяем, что в ОС отключен файервол:<br>  
<code># systemctl status firewalld</code><br> 
Unit firewalld.service could not be found.
<br> 
Проверяем файл конфигурации nginx:<br> 
<code># nginx -t</code>
<pre>nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful</pre>

Проверяем, включен ли selinux:<br>
<code># getenforce</code><br>
Enforcing<br>

Пытаемся найти проблему в audit.log по номеру порта: <br>
<code># grep 4881 /var/log/audit/audit.log</code><br>
type=AVC msg=audit(1737200191.043:694): avc:  denied  { name_bind } for  pid=6027 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
<br>

Передаем интересующую строку audit2why (используя метку времени для поиска):<br>
<code># grep 1737200191.043:694 /var/log/audit/audit.log | audit2why</code>
<pre>
type=AVC msg=audit(1737200191.043:694): avc:  denied  { name_bind } for  pid=6027 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
</pre>
Выполняем предложенное решение:
<pre># setsebool -P nis_enabled 1 
# systemctl start nginx</pre>

Можно проверить работоспособность с помощью lynx:<br>
<code>lynx http://localhost:4881</code>
<br>
Вернем все на место:
<pre>
# setsebool -P nis_enabled 0
# systemctl start nginx
</pre>     

<h3>Разрешение в SELinux работы nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:</h3>

Смотрим, что разрешено:<br>
<code># semanage port -l | grep http</code>
<pre>
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
</pre>
Нас интересует третья строка с http_port_t. Добавим порт 4881:<br>
<code># semanage port -a -t http_port_t -p tcp 4881</code>

Проверяем:<br>
<code># semanage port -l | grep "^http_port_t" </code>
<pre>http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000</pre>

<pre>
# systemctl start nginx
# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2025-01-18 12:58:17 UTC; 1min 49s ago
    Process: 6647 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6648 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6649 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6650 (nginx)
      Tasks: 3 (limit: 12012)
     Memory: 2.9M
        CPU: 23ms
     CGroup: /system.slice/nginx.service
             ├─6650 "nginx: master process /usr/sbin/nginx"
             ├─6651 "nginx: worker process"
             └─6652 "nginx: worker process"

Jan 18 12:58:17 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 18 12:58:17 selinux nginx[6648]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 18 12:58:17 selinux nginx[6648]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 18 12:58:17 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
</pre>
<br>
Снова уберем разрешенный порт:
<pre>
# semanage port -d -t http_port_t -p tcp 4881
# systemctl stop nginx
</pre>

<h3>Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:</h3>
<pre>
# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
</pre>
Посмотрим на сформированные файлы:
<pre># ls
nginx.pp  nginx.te
</pre>
Применим сформированный модуль:<br>
<code># semodule -i nginx.pp</code>
<br>
<code># systemctl start nginx</code>
Все снова работает.<br>

Находим установленный модуль:<br>
<code># semodule -l |grep nginx</code><br>
nginx<br>

Удалим наш модуль:
<pre># semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
</pre>
