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

