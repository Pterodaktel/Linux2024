#!/bin/bash
# подобие команды 'ps ax'

CLK_TCK=$(getconf CLK_TCK)

echo "PID	TTY	STAT	TIME	COMMAND"

for DIR in $(ls /proc/ | grep -P [0-9]+ | sort -n)
do
 if [ -f "/proc/$DIR/stat" ]
 then
   STATUS=$(cat "/proc/$DIR/stat" | awk '{print $3 }')
   TIME=`cat "/proc/$DIR/stat" | awk '{secs=($14 + $15) / $CLK_TCK}  { hours=secs/3600 } { mins=(secs/60) % 60 } {printf "%d:%d", hours, mins}'`
 else
  continue
 fi

 TTY=`ls -l "/proc/$DIR/fd/" | awk '/ 0 -> \// { print substr($11, 6, 10) }'`

 if [ -z ${TTY/null/} ]
 then
   TTY='?'
 fi

 if [ -f "/proc/$DIR/cmdline" ]
 then
   CMD=$(tr -d '\0' < "/proc/$DIR/cmdline")
 fi

 if [ -z "$CMD" ]
 then
   CMD=$(cat "/proc/$DIR/stat" | awk '{print $2 }')
 else 
   CMD="'$CMD'"  
 fi
 

 if [ -d "/proc/$DIR" ]
 then
    echo "$DIR	$TTY	$STATUS	$TIME	$CMD"
 fi
done

