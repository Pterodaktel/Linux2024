<h1>Сетевые пакеты. VLAN'ы. LACP</h1>
<p>
В Office1 в тестовой подсети появляется сервера с доп интерфейсами и адресами.<br>
В internal сети testLAN:
</p>
<ul>
    <li>testClient1 - 10.10.10.254</li>
    <li>testClient2 - 10.10.10.254</li>
    <li>testServer1- 10.10.10.1</li>
    <li>testServer2- 10.10.10.1</li>
</ul>
<p>
Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2
</p>
<p>
Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов
</p>
