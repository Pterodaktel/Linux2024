<h1>Развертывание веб приложения</h1>
<p>Развернем стенд nginx + php-fpm (wordpress) + python (django) + js(node.js) с деплоем через docker-compose</p>

<p>
  Vagrant mirror: https://vagrant.elab.pro<br>
  Vagrant box: ubuntu/20.04<br>
  Ansible playbook: web.yml
</p>

<p>
  Порты виртуальной машины (8081-8083) проброшены на хост. На каждом порту в браузере должно открываться отдельное приложение.<br>
  В качестве фронтенда выступает контейнер c nginx 1.22.
  </p>

<p>
  На порту 8083 будет доступен Wordpress 6.01 - докер-контейнер wordpress:6.0.1-php8.0-fpm-alpine.<br>
  В качестве сервера БД контейнер mysql:8.0.0 (с последней версией были проблемы)
</p>

<p>
  На порту 8082 открывается приложение типа "Hello world!" на node.js.<br>
  Контейнер: node:16.13.2-alpine3.15
</p>

<p>
  На порту 8081 - приложение Python/Django, доставившее наибольшее количество проблем.<br>
  Через Dockerfile собирается отдельный образ с зависимостями на основе контейнера: python:3.8.3.<br>
  В контейнере app запускается backend с помощью Python WSGI HTTP-сервера Green Unicorn.<br>
  В Dockerfile было добавлено автоматическое обновление pip.<br>
  Чтобы Django стал открываться по сети нужно разрешить все строкой ALLOWED_HOSTS = ['*'] в файле settings.py
</p>

<h3>Проверка приложения PHP-FPM/Wordpress</h3>
<img src="img/wp.png" alt="" align="center"><br>
<h3>Проверка приложения Python/Django</h3>
<img src="img/django.png" alt="" align="center"><br>
<h3>Проверка приложения Node.js</h3>
<img src="img/node.png" alt="" align="center"><br>
