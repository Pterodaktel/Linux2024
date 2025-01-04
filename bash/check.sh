#!/bin/bash

# Скрипт анализа логов Apache
# для запуска раз в час с помощью cron: 0 * * * *
# Ограничение: скрипт должен запускаться в 0 минут (как указано выше)

# настраеваемые переменные:
# путь к access.log
LOG_FILE=/var/log/httpd/access_log
# путь к error.log
ERROR_LOG=/var/log/httpd/error_log
# количество (топ) наиболее частых вхождений
LIMIT=10
# кому посылать e-mail
MAIL_TO=$USER

# временный файл с текстом письма, блокирующий повторный запуск
LOCK_FILE=./check.out

# защита от повторного запуска
if [ -f "$LOCK_FILE" ]
then
  echo "Скрипт уже запущен"
  exit 1
fi

# направим в файл свой поток вывода
exec 3> $LOCK_FILE

# сформируем подстроку поиска по предыдущему часу
LANG_CURRENT=$LANG
LANG=en_EN
DATE_PATTERN=`date -d "1 hour ago" +%d/%b/%Y:%H`
LANG=$LANG_CURRENT

echo "Обрабатываемый файл: $LOG_FILE"
echo "Период c `date -d \"1 hour ago\" +%H:%S` до `date +%H:%S`" >&3

echo "IP адреса (топ $LIMIT):" >&3
grep $DATE_PATTERN $LOG_FILE | awk '{print $1}' |sort |uniq -c |sort -nr |tail -n $LIMIT | awk '{print $2 " - "  $1}' >&3

echo "Запрашиваемые адреса URL (топ $LIMIT):" >&3
grep $DATE_PATTERN $LOG_FILE | awk '{print $7}' |sort |uniq -c |sort -nr |tail -n $LIMIT | awk '{print $2 " - " $1}' >&3

echo "Коды ответа:" >&3
grep $DATE_PATTERN $LOG_FILE | awk '{print $9}' |sort |uniq -c  | awk '{print $2 " - " $1}' >&3

echo "Обрабатываемый файл: $ERROR_LOG"
echo "Ошибки веб-сервера/приложения c момента последнего запуска:" >&3
AFTER_START_NO=`cat -n $ERROR_LOG | awk '/resuming normal operations/ { wanted=$1 } END  { print wanted + 1 }'`
sed -n "$AFTER_START_NO,$"p $ERROR_LOG |grep error >&3
# это если под ошибками веб-сервера понимать response-коды, отличные от 2хх в access.log
#awk '$9<200||$9>299 {print $9}' $LOG_FILE | sort -u >&3

# освободить поток вывода
exec 3>&-
# отправка письма
mail -s 'Статистика лога Apache' -E $MAIL_TO < $LOCK_FILE
# удаление блокировки
rm -f $LOCK_FILE
