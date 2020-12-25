#!/bin/bash

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
EXECUTABLE=${DIR}/realmd
LOGPATH=${DIR}/../log/latest

crashcount=0

case $1 in
    start )
        screen -dmS classic-realm $PWD/$0 detached
        echo "Realm daemon started"
    ;;
    stop )
        screen -X -S classic-realm quit
        echo "Realm deamon stopped"
    ;;
    detached )
        while :
        do
                echo `date` >> ${LOGPATH}/realm-crash.log
                cd ${DIR};
                cmd="./realmd"
                $cmd
                status=$?
                echo "Status after downtime is: $status"
                mv ${LOGPATH}/Realm.log ${LOGPATH}/Realm$(date +%F-%H:%M).log && touch ${LOGPATH}/Realm.log
                if [ "$status" == "2" ]; then
                   echo `date` ", Realm daemon restarted."
                elif [ "$status" == "0" ]; then
                   echo "date" ", Realm daemon shut down."
                   exit 0
                else
                   mv ${LOGPATH}/realm-crash.log ${LOGPATH}/realm-crash$(date +%F-%H:%M).log && touch ${LOGPATH}/realm-crash.log
                   echo "date" ", MaNGOS daemon crashed."
                   ((crashcount=crashcount+1))
                   if [ "$crashcount" -gt 50 ]; then
                      exit 0
                   fi
                fi
        done
        ;;
esac