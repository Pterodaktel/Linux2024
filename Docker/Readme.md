<h1>Docker</h1>
<h3>Цель домашнего задания</h3>
<p>Разобраться с основами docker, с образом, эко системой docker в целом</p>

<h3>Описание домашнего задания</h3>
<p>
1.	Установите Docker на хост машину https://docs.docker.com/engine/install/ubuntu/<br>
2.	Установите Docker Compose - как плагин, или как отдельное приложение<br>
3.	Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)<br>
4.	Определите разницу между контейнером и образом<br>
5.	Вывод опишите в домашнем задании.<br>
6.	Ответьте на вопрос: Можно ли в контейнере собрать ядро?
</p>
<p>
Сначала за основу был взят образ nginx:alpine, в котором была заменена стандартная страница. такой вариант работает корректнее и запускается намного проще.<br>
Но поскольку было "свой кастомный на базе alpine", попробовал простенький вариант на основе alpine:latest.<br>  
Собранный образ доступен по ссылке: https://hub.docker.com/repository/docker/pterodaktel25/alpine_with_nginx/
</p>
<p>Образ - это дистрибутив (исходник), на основе которого можно построить контейнер.<br>
  Контейнер - изолированная выполняемая среда в ОС, созданная на основе образа.</p>
<p>Ядро в контейнере собрать можно.</p>
