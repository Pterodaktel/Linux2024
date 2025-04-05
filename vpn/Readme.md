<h1>VPN</h1>
<p>
1) Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях<br>
2) Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ
</p>
<p>
Vagrant mirror: https://vagrant.elab.pro<br>
Box: ubuntu/jammy64
</p>

<h2>Часть 1</h2>

<p>
  Стенд в каталоге vpn.<br>
  Ansible playbook: net.yml.
</p>

<h3>Схема сети</h3>

<pre>
server 192.168.11.10                                                    client 192.168.11.20  
  ----------------------------------------------------------------------------------------
  10.10.10.1                                                            10.10.10.2     
</pre>

<p>На сервере запускаем iperf:</p>
<code># iperf3 -s</code>
<pre>
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
</pre>

<h3>OpenVpn туннель с интерфейсом tap</h3>
<p>На клиенте:</p>
<code># iperf3 -c 10.10.10.1 -t 40 -i 5</code>
<pre>
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 34418 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  42.6 MBytes  71.5 Mbits/sec   86    743 KBytes
[  5]   5.00-10.00  sec  50.0 MBytes  83.9 Mbits/sec  828    232 KBytes
[  5]  10.00-15.00  sec   171 MBytes   287 Mbits/sec    0    543 KBytes
[  5]  15.00-20.00  sec   171 MBytes   287 Mbits/sec    2    587 KBytes
[  5]  20.00-25.00  sec   171 MBytes   287 Mbits/sec    0    757 KBytes
[  5]  25.00-30.00  sec   170 MBytes   285 Mbits/sec    0    903 KBytes
[  5]  30.00-35.00  sec  43.8 MBytes  73.4 Mbits/sec  529    530 KBytes
[  5]  35.00-40.00  sec  41.2 MBytes  69.2 Mbits/sec    0    550 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec   861 MBytes   181 Mbits/sec  1445             sender
[  5]   0.00-40.11  sec   858 MBytes   180 Mbits/sec                  receiver

iperf Done.
</pre>


<h3>OpenVpn туннель с интерфейсом tun</h3>
<p>На клиенте:</p>
<code># iperf3 -c 10.10.10.1 -t 40 -i 5</code>
<pre>
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 40834 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec   139 MBytes   232 Mbits/sec  323    428 KBytes
[  5]   5.00-10.00  sec   175 MBytes   293 Mbits/sec    3    470 KBytes
[  5]  10.00-15.00  sec   174 MBytes   291 Mbits/sec    1    505 KBytes
[  5]  15.00-20.00  sec   173 MBytes   291 Mbits/sec   96    523 KBytes
[  5]  20.00-25.00  sec   176 MBytes   295 Mbits/sec    3    577 KBytes
[  5]  25.00-30.00  sec   175 MBytes   293 Mbits/sec    3    600 KBytes
[  5]  30.00-35.00  sec   175 MBytes   293 Mbits/sec    4    600 KBytes
[  5]  35.00-40.00  sec   174 MBytes   293 Mbits/sec    3    630 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.00  sec  1.33 GBytes   285 Mbits/sec  436             sender
[  5]   0.00-40.07  sec  1.33 GBytes   285 Mbits/sec                  receiver

iperf Done.
</pre>

<p>Ожидаемо, соединение через tun интерфейс быстрее. В нашем примере преимущество примерно в полтора раза.</p>

<h2>Часть 2</h2>

<p>
  Стенд в каталоге vpn-ras.<br>
  Ansible playbook: ras.yml.
</p>

<h3>Схема сети</h3>

<pre>
server 192.168.56.10 (стенд)                               client 192.168.56.1 (хост машина)
  ----------------------------------------------------------------------------------------
  10.10.10.1                                                            10.10.10.2     
</pre>

<p>С помощью переменных в плейбуке можно менять параметры openvpn: интерфейс (tun/tap), протокол (tcp/udp) и порт (1207).</p>
<p>После выполнения плейбука в текущем каталоге создается каталог client с файлом конфигурации клиента client.conf и необходимыми сертификатами</p>
<p>Подключение к серверу выполняется командой: <code>openvpn --config client.conf</code> из созданного каталога</p>
Проверка соединения:
<code>ping 10.10.10.1</code><br>
<pre>
  Обмен пакетами с 10.10.10.1 по с 32 байтами данных:
Ответ от 10.10.10.1: число байт=32 время=1мс TTL=64
Ответ от 10.10.10.1: число байт=32 время=2мс TTL=64
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=64
Ответ от 10.10.10.1: число байт=32 время=2мс TTL=64

Статистика Ping для 10.10.10.1:
    Пакетов: отправлено = 4, получено = 4, потеряно = 0
    (0% потерь)
Приблизительное время приема-передачи в мс:
    Минимальное = 0мсек, Максимальное = 2 мсек, Среднее = 1 мсек
</pre>
