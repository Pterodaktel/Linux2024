<h1>Systemd</h1>
<p>Vagrant mirror: https://vagrant.elab.pro<br>
Vagrant box: ubuntu/22.04</p>

<nl>
<li>Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).</li>
<li>Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).</li>
<li>Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.</li>
</nl>

