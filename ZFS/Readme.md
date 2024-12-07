<h1>Практика ZFS</h1>

1. Определить алгоритм с наилучшим сжатием:<br>
    • Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);<br>
    • создать 4 файловых системы на каждой применить свой алгоритм сжатия;<br>
    • для сжатия использовать либо текстовый файл, либо группу файлов.<br>
<br>
2. Определить настройки пула.<br>
    С помощью команды zfs import собрать pool ZFS.<br>
    Командами zfs определить настройки:<br>
    - размер хранилища;<br>
    - тип pool;<br>
    - значение recordsize;<br>
    - какое сжатие используется;<br>
    - какая контрольная сумма используется.<br>
<br>
3. Работа со снапшотами:<br>
    • скопировать файл из удаленной директории;<br>
    • восстановить файл локально. zfs receive;<br>
    • найти зашифрованное сообщение в файле secret_message.<br>
<br>
<p>
   Подготовка стенда (bento/ubuntu-24.04): Vagrantfile   
</p>    
<p> 
   Создание и заполнение необходимыми файлами c помощью Ansible: zfs.yml
</p>

<h3>Из консоли:</h3>

1. Определить алгоритм с наилучшим сжатием<br>
<br>
<code># zfs get all | grep compression </code>
otus             compression           zle                       local<br>
otus/hometask2   compression           zle                       inherited from otus<br>
otus/test        compression           zle                       inherited from otus<br>
otus1            compression           lzjb                      local<br>
otus2            compression           lz4                       local<br>
otus3            compression           gzip-9                    local<br>
otus4            compression           zle                       local<br>
<br>

<code># zfs get all | grep compressratio | grep -v ref </code>
otus1            compressratio         1.81x                     -<br>
otus2            compressratio         2.23x                     -<br>
otus3            compressratio         3.65x                     -<br>
otus4            compressratio         1.00x                     -<br>
<br>
Для скачанного файла алгоритм gzip-9 наиболее эффективен по сжатию.<br>
<br>

2. Определить настройки пула.<br>
<br>
<code># zfs get available otus</code>
NAME  PROPERTY   VALUE  SOURCE<br>
otus  available  347M   -<br>
<br>
Размер 347Мб<br>
<br>
<code># zfs get readonly otus</code>
<br>
NAME  PROPERTY  VALUE   SOURCE<br>
otus  readonly  off     default<br>
<br>
Чтение/зпись<br>
<br>
<code># zfs get recordsize otus</code>
NAME  PROPERTY    VALUE    SOURCE<br>
otus  recordsize  128K     local<br>
<br>
recordsize: 128Кб<br>
<br>
<code># zfs get compression otus</code>
NAME  PROPERTY     VALUE           SOURCE<br>
otus  compression  zle             local<br>
<br>
Компрессия: zle<br>
<br>
<code># zfs get checksum otus</code>
NAME  PROPERTY  VALUE      SOURCE<br>
otus  checksum  sha256     local<br>
<br>
Алгоритм контрольной суммы: sha256<br>
<br>

3. Работа со снапшотом, поиск сообщения от преподавателя<br>
<code># find /otus/test -name "secret_message"</code>
/otus/test/task1/file_mess/secret_message<br>
<br>
<code># cat /otus/test/task1/file_mess/secret_message</code><br>
https://otus.ru/lessons/linux-hl/<br>
<br>
Получаем текст ссылки на курс.<br>
