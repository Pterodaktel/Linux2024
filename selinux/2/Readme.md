<h1>2.	Обеспечение работоспособности приложения при включенном SELinux</h1>

<p>
    Код стенда: https://github.com/Nickmob/vagrant_selinux_dns_problems.git<br>
Vagrant box: Almalinux/9<br>
 Версия бокса: 9.5.20241203    
</p>

<h3>На клиенте:</h3>
<p>Тестовый запрос к серверу:</p>
<pre>
$ dig @192.168.50.10 ns01.dns.lab

; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 ns01.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 34213
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 75afca5a776970f401000000678bdf4f7f669a6e24134bf0 (good)
;; QUESTION SECTION:
;ns01.dns.lab.                  IN      A

;; ANSWER SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 6 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sat Jan 18 17:05:19 UTC 2025
;; MSG SIZE  rcvd: 85
</pre>

<p>Попробуем внести изменения в зону:</p>
<pre>
$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
</pre>
<p>Попытка не удалась: update failed: SERVFAIL</p>


<h3>На сервере:</h3>

<p>Посмотрим лог на предмет ошибок SELinux для bind</p>
<code># journalctl -t setroubleshoot -u named.service</code>
<pre>....
Jan 19 12:10:47 ns01 setroubleshoot[3684]: SELinux is preventing /usr/sbin/named from write access on the directory dynamic. For complete SELinux messages run: sealert -l a6a1da5f-e866-4203-8e08-eb2aa2d5e53c
Jan 19 12:10:47 ns01 setroubleshoot[3684]: SELinux is preventing /usr/sbin/named from write access on the directory dynamic.

                                           *****  Plugin catchall (100. confidence) suggests   **************************

                                           If you believe that named should be allowed write access on the dynamic directory by default.
                                           Then you should report this as a bug.
                                           You can generate a local policy module to allow this access.
                                           Do
                                           allow this access for now by executing:
                                           # ausearch -c 'isc-net-0001' --raw | audit2allow -M my-iscnet0001
                                           # semodule -X 300 -i my-iscnet0001.pp
</pre>
<p>
   Видим, что SELinux не разрешает запись процессу bind в каталог <b>dynamic</b>.<br>
   Сразу предлагается решение в виде создания дополнительного модуля.
</p>
<p>Изучим проблему детальнее.</p>
<code># sealert -l a6a1da5f-e866-4203-8e08-eb2aa2d5e53c</code>
<pre>
SELinux is preventing /usr/sbin/named from write access on the directory dynamic.

*****  Plugin catchall (100. confidence) suggests   **************************

If you believe that named should be allowed write access on the dynamic directory by default.
Then you should report this as a bug.
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
 ausearch -c 'isc-net-0001' --raw | audit2allow -M my-iscnet0001
 semodule -X 300 -i my-iscnet0001.pp


Additional Information:
Source Context                system_u:system_r:named_t:s0
Target Context                unconfined_u:object_r:named_conf_t:s0
Target Objects                dynamic [ dir ]
Source                        isc-net-0001
Source Path                   /usr/sbin/named
Port                          <Unknown>
Host                          ns01
Source RPM Packages           bind-9.16.23-24.el9_5.x86_64
Target RPM Packages
SELinux Policy RPM            selinux-policy-targeted-38.1.45-3.el9_5.noarch
Local Policy RPM              selinux-policy-targeted-38.1.45-3.el9_5.noarch
Selinux Enabled               True
Policy Type                   targeted
Enforcing Mode                Enforcing
Host Name                     ns01
Platform                      Linux ns01 5.14.0-503.15.1.el9_5.x86_64 #1 SMP
                              PREEMPT_DYNAMIC Thu Nov 28 07:25:19 EST 2024
                              x86_64 x86_64
Alert Count                   2
First Seen                    2025-01-18 17:08:14 UTC
Last Seen                     2025-01-19 12:10:47 UTC
Local ID                      a6a1da5f-e866-4203-8e08-eb2aa2d5e53c

Raw Audit Messages
type=AVC msg=audit(1737288647.108:638): avc:  denied  { write } for  pid=796 comm="isc-net-0000" name="dynamic" dev="sda4" ino=50420990 scontext=system_u:system_r:named_t:s0 tcontext=unconfined_u:object_r:named_conf_t:s0 tclass=dir permissive=0


type=SYSCALL msg=audit(1737288647.108:638): arch=x86_64 syscall=openat success=no exit=EACCES a0=ffffff9c a1=7fc52ab6f050 a2=241 a3=1b6 items=0 ppid=1 pid=796 auid=4294967295 uid=25 gid=25 euid=25 suid=25 fsuid=25 egid=25 sgid=25 fsgid=25 tty=(none) ses=4294967295 comm=isc-net-0000 exe=/usr/sbin/named subj=system_u:system_r:named_t:s0 key=(null)

Hash: isc-net-0001,named_t,named_conf_t,dir,write
</pre>

<code># grep 1737220094.862:569 /var/log/audit/audit.log | audit2why</code>
<pre>
type=AVC msg=audit(1737220094.862:569): avc:  denied  { write } for  pid=829 comm="isc-net-0001" name="dynamic" dev="sda4" ino=50420990 scontext=system_u:system_r:named_t:s0 tcontext=unconfined_u:object_r:named_conf_t:s0 tclass=dir permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
</pre>


<p>Посмотрим конфигурацию bind для обновляемой ранее зоны</p>
<code># less /etc/named.conf</code>
<pre>
...
// labs ddns zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        allow-update { key "zonetransfer.key"; };
        file "/etc/named/dynamic/named.ddns.lab.view1";
    };
...
</pre>

<p>Мы видим, что зона расположена в каталоге /etc/named/dynamic. Посмотрим метки в какталоге /etc/named/</p>

<pre># ls -laZ /etc/named
total 28
drw-rwx---.  3 root named system_u:object_r:named_conf_t:s0      121 Jan 18 16:45 .
drwxr-xr-x. 87 root root  system_u:object_r:etc_t:s0            8192 Jan 18 16:53 ..
drw-rwx---.  2 root named unconfined_u:object_r:named_conf_t:s0   56 Jan 18 16:45 dynamic
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      805 Jan 18 16:45 named.50.168.192.rev
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      628 Jan 18 16:45 named.dns.lab
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      626 Jan 18 16:45 named.dns.lab.view1
-rw-rw----.  1 root named system_u:object_r:named_conf_t:s0      676 Jan 18 16:45 named.newdns.lab
</pre>

<p>
    Мы видим, что файлы в этом каталоге промаркированы типом named_conf_t.<br>
    Но, пользователь метки для каталога dynamic отличается. <br>
    Посмотрим метки каталога /var/named<br>
</p>

<code># ll -Z /var/named</code>
<pre>total 16
drwxrwx---. 2 named named system_u:object_r:named_cache_t:s0   23 Jan 18 16:45 data
drwxrwx---. 2 named named system_u:object_r:named_cache_t:s0   94 Jan 18 16:46 dynamic
-rw-r-----. 1 root  named system_u:object_r:named_conf_t:s0  2112 Oct  3 05:26 named.ca
-rw-r-----. 1 root  named system_u:object_r:named_zone_t:s0   152 Oct  3 05:26 named.empty
-rw-r-----. 1 root  named system_u:object_r:named_zone_t:s0   152 Oct  3 05:26 named.localhost
-rw-r-----. 1 root  named system_u:object_r:named_zone_t:s0   168 Oct  3 05:26 named.loopback
drwxrwx---. 2 named named system_u:object_r:named_cache_t:s0    6 Oct  3 05:25 slaves
</pre>

<p>
    Файл зоны localhost здесь имеет тип named_zone_t.<br>
    Также здесь присутствует свой каталог dynamic с меткой named_cache_t.
</p>

<p>Посмотрим правила для меток named_conf_t и named_zone_t</p>
<code># sesearch -A -s named_t | grep named_conf_t</code>
<pre>
allow named_t named_conf_t:dir { getattr ioctl lock open read search };
allow named_t named_conf_t:file { getattr ioctl lock open read };
allow named_t named_conf_t:lnk_file { getattr read };
</pre>  
<code># sesearch -A -s named_t | grep named_zone_t</code>
<pre>
allow named_t named_zone_t:dir { add_name create link remove_name rename reparent rmdir setattr unlink watch watch_reads write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:dir { add_name remove_name write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:dir { add_name remove_name write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:dir { add_name remove_name write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:dir { getattr ioctl lock open read search };
allow named_t named_zone_t:file { append create link rename setattr unlink watch watch_reads write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:file { getattr ioctl lock map open read };
allow named_t named_zone_t:lnk_file { append create ioctl link lock rename setattr unlink watch watch_reads write }; [ named_write_master_zones ]:True
allow named_t named_zone_t:lnk_file { getattr read };
</pre>

<p>
   Видим, что каталоги домена named_conf_t доступны только на чтение. Для named_zone_t запись доступна.<br>
   Напрашивается вывод, что домен named_conf_t предназначен для чтения файлов конфигурации, а named_zone_t для управления зонами DNS.
</p>

<p>Назначим метку named_zone_t каталогу /etc/named/dynamic</p>
<code># chcon -R -t named_zone_t /etc/named/dynamic</code>


<h3>На клиенте:</h3>

<pre>
$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
</pre>

<p>Все сработало. Проверим:</p>

<code>$ dig @192.168.50.10 www.ddns.lab</code>
<pre>
; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8938
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6044db8d44d77c7d01000000678d190f756e2a70ee71f719 (good)
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; Query time: 4 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sun Jan 19 15:23:59 UTC 2025
;; MSG SIZE  rcvd: 85
</pre>
<p>
    Все врооде бы ок. Но есть один момент. Все это будет работать до тех пор, пока наш каталог /etc/named/dynamic не окажется вдруг перемаркирован.
    Такую ситуацию следовало бы предусмотреть. По идее, если нам, скажем, лень разбираться в назначениях каталогов, мы могли бы автоматически создать модуль SElinux.
    Посмотрим этот вариант.
</p>
        
<h3>На сервере:</h3>

<code># grep 1737290119.647:647 /var/log/audit/audit.log | audit2allow -M named_module</code><br>
<code># cat ./named_module.te</code>
<pre>
module named_module 1.0;

require {
        type named_conf_t;
        type named_t;
        class dir write;
}

#============= named_t ==============
allow named_t named_conf_t:dir write;
</pre>
<p>
    Судя по тексту сгенерированного модуля, нам предлагается разрешить домену named_t записывать в каталоги с меткой named_conf_t.
    Это представляется не лучшим решением, т.к. мы несколько нарушаем этим модель безопасности дистрибутива.
</p>

<p>
    Если мне не изменяет память, когда-то файлы зон bind хранились в /etc/named/. 
    В какойто момент они "переехали" в /var/named/. Для динамически обновляемых зон служит каталог /var/named/dynamic/.
    Вероятно, кто-то по старой памяти положил этот каталог в /etc.
    Наиболее правильным вариантом представляется перенести файлы нашей зоны туда, где это предусмотрено дистрибутивом.
</p>

<p>Проверим правила для метки интересующего нас каталога.</p>
<code># sesearch -A -s named_t | grep named_cache_t </code>
<pre>
allow named_t named_cache_t:dir { add_name create getattr ioctl link lock open read remove_name rename reparent rmdir search setattr unlink watch watch_reads write };
allow named_t named_cache_t:file { append create getattr ioctl link lock map open read rename setattr unlink watch watch_reads write };
allow named_t named_cache_t:lnk_file { append create getattr ioctl link lock read rename setattr unlink watch watch_reads write };
</pre>

<p>Права на запись есть. Остановим bind.</p>
<code># systemctl stop named</code>

<p>
    После этого в файле /etc/named.conf изменим пути к файлам нашей зоны с /etc/named/dynamic на /var/named/dynamic/.
    Затем перенесем наши файлы, перемаркируем каталог и запустим bind.
</p>
<code># mv /etc/named/dynamic/* /var/named/dynamic</code>
<code>restorecon -R -v /var/named/dynamic</code>
<pre>
Relabeled /var/named/dynamic/named.ddns.lab from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_cache_t:s0
Relabeled /var/named/dynamic/named.ddns.lab.view1 from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_cache_t:s0
Relabeled /var/named/dynamic/named.ddns.lab.view1.jnl from system_u:object_r:named_zone_t:s0 to system_u:object_r:named_cache_t:s0
</pre>
<code># systemctl start named</code>

<h3>На клиенте:</h3>
<p>Убеждаемся, что все работает</p>
<code>$ nsupdate -k /etc/named.zonetransfer.key</code>
<pre>
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.12
> send
> quit
</pre>

<code>$ dig @192.168.50.10 www.ddns.lab</code>
<pre>
; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51932
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: cb9026e733d284da01000000678fe7625f6ae84a8072bfb0 (good)
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.12
www.ddns.lab.           60      IN      A       192.168.50.15

;; Query time: 2 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Tue Jan 21 18:28:50 UTC 2025
;; MSG SIZE  rcvd: 101
</pre>
