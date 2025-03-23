<h1>Фильтрация трафика - iptables</h1>

<ul>
    <li>реализовать knocking port<br>
    centralRouter может попасть на ssh inetrRouter через knock скрипт (пример в материалах).</li>
    <li>добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.<br>
    запустить nginx на centralServer.<br>
    пробросить 80й порт на inetRouter2 8080.<br>
    дефолт в инет оставить через inetRouter</li>.
</ul>

<p>Для открытия ssh порта на inetRouter реализована последовательность tcp портов: 5501 -> 5502 -> 5503. Порты можно менять в переменных KPORT1, KPORT2 и KPORT3 bash скрипта настройки firewall_inetRouter.sh.</p>
<p>
    Для откытия порта с клиента в локальной сети используется комнда:<br>
    <code> # knock 192.168.255.1 5501 5502 5503</code>
    <pre>
Starting Nmap 7.80 ( https://nmap.org ) at 2025-03-23 21:44 MSK
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for _gateway (192.168.255.1)
Host is up (0.00061s latency).

PORT     STATE    SERVICE
5501/tcp filtered fcp-addr-srvr2
MAC Address: 08:00:27:B4:96:27 (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.15 seconds
Starting Nmap 7.80 ( https://nmap.org ) at 2025-03-23 21:44 MSK
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for _gateway (192.168.255.1)
Host is up (0.00069s latency).

PORT     STATE    SERVICE
5502/tcp filtered fcp-srvr-inst1
MAC Address: 08:00:27:B4:96:27 (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.13 seconds
Starting Nmap 7.80 ( https://nmap.org ) at 2025-03-23 21:44 MSK
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for _gateway (192.168.255.1)
Host is up (0.00037s latency).

PORT     STATE    SERVICE
5503/tcp filtered fcp-srvr-inst2
MAC Address: 08:00:27:B4:96:27 (Oracle VirtualBox virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.13 seconds
    </pre>
    <code># ssh 192.168.255.1</code>
    <pre>
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ED25519 key fingerprint is SHA256:Wtk6kYSq+gsQI2x8wtOMz6KYtwTLNHVzu/U/fFH+pfM.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? no    
    </pre>
</p>
