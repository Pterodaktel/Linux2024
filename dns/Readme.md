<h1>Split DNS</h1>

<pre>
   Взять стенд https://github.com/erlong15/vagrant-bind
   
   Добавить еще один сервер client2
   Завести в зоне dns.lab имена:
    - web1 - смотрит на клиент1
    - web2 смотрит на клиент2

    Завести еще одну зону newdns.lab
    Завести в ней запись
    www - смотрит на обоих клиентов

    Настроить split-dns

    - клиент1 - видит обе зоны, но в зоне dns.lab только web1
    - клиент2 видит только dns.lab

    Настроить все без выключения selinux*
</pre>

<p>
Vagrant box: Almalinux/9<br>
Версия бокса: 9.5.20241203<br>
Ansible playbook: dns.yml   
</p>

<p>Чтобы сгенерировать ключи для хостов client и client2 используем утилиту tsig-keygen</p>

<code>[root@ns01 data]# tsig-keygen</code>
<pre>
key "tsig-key" {
        algorithm hmac-sha256;
        secret "mCj1WD7XoOcHYHHCQigGidQ6ABpwtnXVaVECwCyqG6w=";
};
</pre>

<p>При правке конфигурации named можно воспользоваться утилитой named-checkconf, она укажет, в каких строчках есть ошибки.</p>

<code>[root@client etc]# dig @192.168.50.10 ns01.dns.lab</code>
<pre>
; <<>> DiG 9.16.23-RH <<>> @192.168.50.10 ns01.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54135
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 1cafe592e8ddcaca0100000067fbadf2ddbd33eb53d1f4d2 (good)
;; QUESTION SECTION:
;ns01.dns.lab.                  IN      A

;; ANSWER SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 2 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sun Apr 13 15:28:34 MSK 2025
;; MSG SIZE  rcvd: 85
</pre>

<code>root@client etc]# dig @192.168.50.11 ns02.dns.lab</code>
<pre>
; <<>> DiG 9.16.23-RH <<>> @192.168.50.11 ns02.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 13907
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 48500a97528de6130100000067fbae23c239d5d5da6abe74 (good)
;; QUESTION SECTION:
;ns02.dns.lab.                  IN      A

;; ANSWER SECTION:
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 4 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Sun Apr 13 15:29:23 MSK 2025
;; MSG SIZE  rcvd: 85
</pre>

<h3>Проверка на client</h3>
<code>[root@client etc]# ping www.newdns.lab</code>
<pre>
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.011 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.053 ms
</pre>
<code>[root@client etc]# ping web1.dns.lab</code>
<pre>
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.020 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.079 ms
</pre>

<code>[root@client etc]# ping web1.dns.lab</code>
<pre>
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.021 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.048 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.021/0.034/0.048/0.013 ms
 </pre>  
<code>[root@client etc]# ping web2.dns.lab</code>
<pre>
ping: web2.dns.lab: Name or service not known
</pre>

<p>
На хосте мы видим, что client видит обе зоны (dns.lab и newdns.lab), однако информацию о хосте web2.dns.lab он получить не может. <br>
Убеждаемся, что тот же результат получен при отключенном первичном сервере ns01 в /etc/resolv.conf   
</p>

<h3>Проверка на client2</h3>

<code>[root@client2 etc]# ping www.newdns.lab</code>
<pre>
ping: www.newdns.lab: Name or service not known
</pre>
<code>[root@client2 etc]# ping web1.dns.lab</code>
<pre>
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=1.70 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=1.70 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.696/1.699/1.703/0.003 ms
</pre>

[root@client2 etc]# ping web2.dns.lab</code>
<pre>
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.026 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.056 ms
^C
--- web2.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.026/0.041/0.056/0.015 ms
</pre>

<p>
Здесь client2 видит всю зону dns.lab и не видит зону newdns.lab.<br>
Убеждаемся, что тот же результат получен при отключенном первичном сервере ns01 в /etc/resolv.conf 
</p>
