<h1>Практика c SELinux</h1>

<h2>Часть 1. Запустить Nginx на нестандартном порту 3-мя разными способами:</h2>
<ul>
<li>переключатели setsebool;</li>
<li>добавление нестандартного порта в имеющийся тип;</li>
<li>формирование и установка модуля SELinux.</li>
</ul>

<p>Vagrant box: Almalinux/9</p>

# systemctl status nginx
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

Проверяем, что в ОС отключен файервол:  
# systemctl status firewalld
Unit firewalld.service could not be found.

Проверяем файл конфигурации nginx:
# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

Проверяем, включен ли selinux:
# getenforce
Enforcing

Пытаемся найти проблему в audit.log по номеру порта: 
# grep 4881 /var/log/audit/audit.log
type=AVC msg=audit(1737200191.043:694): avc:  denied  { name_bind } for  pid=6027 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

Передаем интересующую строку audit2why (используя метку времени для поиска):
# grep 1737200191.043:694 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1737200191.043:694): avc:  denied  { name_bind } for  pid=6027 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1

Выполняем предложенное решение:
# setsebool -P nis_enabled 1
# systemctl start nginx

Можно проверить работоспособность с помощью lynx:
lynx http://localhost:4881

Вернем все на место:
# setsebool -P nis_enabled 0
# systemctl start nginx


Разрешение в SELinux работы nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

Смотрим, что разрешено:
# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

Нас интересует третья строка с http_port_t. Добавим порт 4881:
# semanage port -a -t http_port_t -p tcp 4881

Проверяем:
# semanage port -l | grep "^http_port_t"
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000

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

Снова уберем разрешенный порт:
# semanage port -d -t http_port_t -p tcp 4881
# systemctl stop nginx


Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:

# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

Посмотрим на сформированные файлы:
# ls
nginx.pp  nginx.te

Применим сформированный модуль:
# semodule -i nginx.pp

# systemctl start nginx
Все снова работает.

Находим установленный модуль:
# semodule -l |grep nginx
nginx

Удалим наш модуль:
# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
