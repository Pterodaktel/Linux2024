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
