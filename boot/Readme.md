<h1>Работа с загрузчиком</h1>

1.	Включить отображение меню Grub.<br>
2.	Попасть в систему без пароля несколькими способами.<br>
3.	Установить систему с LVM, после чего переименовать VG.<br>

Vagrant mirror: https://vagrant.elab.pro<br>
Box: elabpro/redos-7<br>

<h3>Предисловие:</h3>
<p>
Изначально собирался делать другую домашку, и решил попробовать Ред ОС 7, благо он оказался в репозитроии elab.
После поднятия бокса с удивлением обнаружил, что после запуска ВМ вагрант не может авторизоваться в системе.
Попробовал войти в консоли, и обнаружил, что вообще не могу попасть в систему ни под каким пользоватем.
В итоге пришлось приступать к выполнению задания по работе с загрузчиком.
</p>

<p>
  Были испробованы разные варианты входа в систему.<br>
  Меню загрузчика отображается изначально.<br>
  Консоль восстановления предлагает авторизоваться, соответственно, мимо.<br>
  Если в строку загрузки, начинающуюся с linux, вставить single, мы попадаем в однопользовательский режим, и нам предлагается ввести пароль root.<br>
  Убеждаемся, что пароль установлен, и нам не известен.<br>
  Ставим в конце строки init=/bin/bash. Здесь можно также опцию ro сразу поменять на rw, чтобы не перемонтировать файловую систему.<br>
  После загрузки меняем пароль командой <b>passwd</b>.<br>
  Дальше вышел конфуз. Если просто перезагрузиться, новый пароль не применяется. Пока разобрался, проделал другой вариант восстановления через загрузочный диск RedOS 7.3.<br>
  Оказалось, что нужно выполнить команду для selinux:<br>
  <code>#touch /.autorelabel *</code><br>
  Только после этого надо перезагружаться.<br>
</p>

<p>
  Вариант загрузки с диска восстановления в этом плане проще.<br>
  Подключаем диск и выбираем загрузку с него.<br>
  При загрузки выбираем консоль восстановления с монтированием ФС в режиме записи.<br>
  Далее: #chroot /sysroot и #passwd <br>
  Выходим из chroot командой exit и перезагружаемся.<br>
</p>

<h3>Переименование VG</h3>
<p>Cмотрим, что у нас имеется.</p>
<code>
# vgs <br>
VG       #PV #LV #SN Attr   VSize   VFree <br>
ro_redos   1   2   0 wz--n- <19,00g    0 <br>
</code>

Переименовываем volume group ro_redos: <br>
<code># vgrename ro_redosg vg_redos</code> <br>

Далее в /etc/fstab меняем вхождения /dev/mapper/ro_redos-root на /dev/mapper/vg_redos-root. <br>
В файле переменных загрузчика /etc/default/grub заменяем вхождения ro_redos на vg_redos <br>

После этого reboot и в меню загрузчика аналогично заменил в выбираемой строке ro_redos на vg_redos  <br>
Далее, когда система загрузилась, осталось реконфигурироваться загрузчик: <br>
<code># grub2-mkconfig</code> <br>
После этого система грузится сама с переименованным Volume Group.<br>


