#!/usr/bin/bash
#cat /vagrant/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
timedatectl set-timezone Europe/Moscow 

# Установка необходимых пакетов
apt update
apt install -y dpkg-dev build-essential zlib1g-dev libpcre3 libpcre3-dev unzip gnupg2 cmake

# Добавить репозиторий nginx
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
| tee /etc/apt/sources.list.d/nginx.list

echo 'deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu/ noble nginx' >> /etc/apt/sources.list.d/nginx.list

# получить исходники nginx
apt update
apt source nginx

# получить исходники модуля brotli
mkdir /home/vagrant/nginx-1.27.3/debian/modules
cd /home/vagrant/nginx-1.27.3/debian/modules
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
cd ngx_brotli/deps/brotli
mkdir out && cd out
# компиляция 
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..

cmake --build . --config Release --target brotlienc

#cd ../../../..
# установка отсутствующих библиотек
apt install -y libssl-dev libpcre2-dev quilt debhelper

# сборка пакета
cd /home/vagrant/nginx-1.27.3
#./configure --add-module=/home/vagrant/nginx-1.27.3/debian/modules/ngx_brotli
#rm -r /home/vagrant/nginx-1.27.3/objs
cat /vagrant/rules > /home/vagrant/nginx-1.27.3/debian/rules
dpkg-buildpackage -b
# Фиксация версии пакета
apt-mark hold nginx
# установка созданного пакета
cd ..
apt install -y ./nginx_1.27.3-1~noble_amd64.deb --allow-change-held-packages

# установка по для создания репозитория
apt install -y aptly rng-tools
# настройки aptly
cat /vagrant/aptly.conf > /etc/aptly.conf

# создание репозитория
aptly repo create -comment="Nginx with brotli" -component="main" -distribution="noble" test
aptly repo add test /home/vagrant/nginx_1.27.3-1~noble_amd64.deb

# создание цифровой подписи
rngd -r /dev/urandom
#gpg --default-new-key-algo rsa4096 --gen-key --keyring pubring
cat /vagrant/gpg.batch > gpg.batch
gpg --default-new-key-algo rsa4096 --batch --gen-key gpg.batch
# публикация репозитория
aptly publish repo test filesystem:pubtest:test
# экспорт публичного ключа в репозиторий
gpg --export --armor > /var/www/aptly/test/pubtest.asc

# настройки хоста
cat /vagrant/default.conf > /etc/nginx/conf.d/default.conf

# запуск веб-сервера
systemctl start nginx
#systemctl enable nginx
