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
