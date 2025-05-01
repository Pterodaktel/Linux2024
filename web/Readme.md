<h1>Развертывание веб приложения</h1>
<p>Развернем стенд nginx + php-fpm (wordpress) + python (django) + js(node.js) с деплоем через docker-compose</p>

<p>
  Vagrant mirror: https://vagrant.elab.pro<br>
  Vagrant box: ubuntu/20.04<br>
  Ansible playbook: web.yml
</p>

<p>Порты виртуальной машины (8081-8083) проброшены на хост. На каждом порту в браузере должно открываться отдельное приложение.</p>

<h3>Проверка приложения PHP/Wordpress</h3>
<img src="img/wp.png" alt="" align="center"><br>
<h3>Проверка приложения Python/Django</h3>
<img src="img/django.png" alt="" align="center"><br>
<h3>Проверка приложения Node.js</h3>
<img src="img/node.png" alt="" align="center"><br>
