<h1>LDAP. Централизованная авторизация и аутентификация</h1>

<ul>
  <li>Установить FreeIPA</li>
  <li>Написать Ansible-playbook для конфигурации клиента</li>
  <li>* Настроить аутентификацию по SSH-ключам</li>
  <li>** Firewall должен быть включен на сервере и на клиенте</li>
</ul>


<p>
Vagrant box: almalinux/8<br>
Ansible playbook для настройки клиентов: clients.yml 
</p>

<p>Запуск скрипта установки сервера Free IPA на сервере.</p>
<code>root@ipa vagrant]# ipa-server-install</code>
<pre>
The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the IPA Server.
Version 4.9.13

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the NTP client (chronyd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure SID generation
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

Do you want to configure integrated DNS (BIND)? [no]: no

Enter the fully qualified domain name of the computer
on which you're setting up server software. Using the form
<hostname>.<domainname>
Example: master.example.com


Server host name [ipa.otus.lan]:

The domain name has been determined based on the host name.

Please confirm the domain name [otus.lan]:

The kerberos protocol requires a Realm name to be defined.
This is typically the domain name converted to uppercase.

Please provide a realm name [OTUS.LAN]:
Certain directory server operations require an administrative user.
This user is referred to as the Directory Manager and has full access
to the Directory for system management tasks and will be added to the
instance of directory server created for IPA.
The password must be at least 8 characters long.

Directory Manager password:
</pre>
Вводим пароль администратора каталога: otusmgmt
<pre>
The IPA server requires an administrative user, named 'admin'.
This user is a regular system account used for IPA server administration.

IPA admin password:
</pre>
Вводим пароль администратора admin: otusadmin
<pre>
Invalid IP address 127.0.1.1 for ipa.otus.lan: cannot use loopback IP address 127.0.1.1
Trust is configured but no NetBIOS domain name found, setting it now.
Enter the NetBIOS name for the IPA domain.
Only up to 15 uppercase ASCII letters, digits and dashes are allowed.
Example: EXAMPLE.


NetBIOS domain name [OTUS]:

Do you want to configure chrony with NTP server or pool address? [no]: no

The IPA Master Server will be configured with:
Hostname:       ipa.otus.lan
IP address(es): 192.168.11.10
Domain name:    otus.lan
Realm name:     OTUS.LAN

The CA will be configured with:
Subject DN:   CN=Certificate Authority,O=OTUS.LAN
Subject base: O=OTUS.LAN
Chaining:     self-signed

Continue to configure the system with these values? [no]: yes
</pre>
...
<pre>
This program will set up IPA client.
Version 4.9.13

Using existing certificate '/etc/ipa/ca.crt'.
Client hostname: ipa.otus.lan
Realm: OTUS.LAN
DNS Domain: otus.lan
IPA Server: ipa.otus.lan
BaseDN: dc=otus,dc=lan

Configured /etc/sssd/sssd.conf
Systemwide CA database updated.
Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub
Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub
Could not update DNS SSHFP records.
SSSD enabled
Configured /etc/openldap/ldap.conf
Configured /etc/ssh/ssh_config
Configured /etc/ssh/sshd_config
Configuring otus.lan as NIS domain.
Client configuration complete.
The ipa-client-install command was successful

Invalid IP address fe80::a00:27ff:fe4c:bd69 for ipa.otus.lan.: cannot use link-local IP address fe80::a00:27ff:fe4c:bd69
Invalid IP address fe80::a00:27ff:fe23:923d for ipa.otus.lan.: cannot use link-local IP address fe80::a00:27ff:fe23:923d
Invalid IP address fe80::a00:27ff:fe4c:bd69 for ipa.otus.lan.: cannot use link-local IP address fe80::a00:27ff:fe4c:bd69
Invalid IP address fe80::a00:27ff:fe23:923d for ipa.otus.lan.: cannot use link-local IP address fe80::a00:27ff:fe23:923d
Please add records in this file to your DNS system: /tmp/ipa.system.records.22_wn6_c.db
==============================================================================
Setup complete

Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                UDP Ports:
                  * 88, 464: kerberos
                  * 123: ntp

        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
The ipa-server-install command was successful
</pre>

<p>Проверим получение тикета для admin</p>
<pre>
[root@ipa vagrant]# kinit admin
Password for admin@OTUS.LAN:
[root@ipa vagrant]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
04/20/2025 12:23:09  04/21/2025 12:15:07  krbtgt/OTUS.LAN@OTUS.LAN

[root@ipa vagrant]# kdestroy
</pre>


<h3>На клиентах</h3>
<p>Также получим билет Kerberos для admin</p>
<pre>
[root@client1 vagrant]# kinit admin
Password for admin@OTUS.LAN:
[root@client1 vagrant]# klist
Ticket cache: KCM:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
04/20/2025 14:21:01  04/21/2025 13:35:11  krbtgt/OTUS.LAN@OTUS.LAN
</pre>

<p>Пробуем добавить нового пользователя otus-user в командной строке:</p>
<code>[root@client1 vagrant]# ipa user-add otus-user --first=Otus --last=User --password</code>
<pre>
Password:
Enter Password again to verify:
----------------------
Added user "otus-user"
----------------------
  User login: otus-user
  First name: Otus
  Last name: User
  Full name: Otus User
  Display name: Otus User
  Initials: OU
  Home directory: /home/otus-user
  GECOS: Otus User
  Login shell: /bin/sh
  Principal name: otus-user@OTUS.LAN
  Principal alias: otus-user@OTUS.LAN
  User password expiration: 20250420112256Z
  Email address: otus-user@otus.lan
  UID: 1376600003
  GID: 1376600003
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
</pre>

<p>На клиенте client2 получаем тикет созданного пользователя</p>
<code>[root@client2 vagrant]# kinit otus-user</code>
<pre>
Password for otus-user@OTUS.LAN:
Password expired.  You must change it now.
Enter new password:

[root@client2 vagrant]# klist
Ticket cache: KCM:0
Default principal: otus-user@OTUS.LAN

Valid starting       Expires              Service principal
04/20/2025 14:25:49  04/21/2025 13:29:45  krbtgt/OTUS.LAN@OTUS.LAN
</pre>
