#!/bin/bash
# Massive Network Game Object Server
# autorestart Script

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
EXECUTABLE=${DIR}/mangosd
LOGPATH=${DIR}/../log/latest

crashcount=0

case $1 in
    start )
        # kill the sreen before restarting.
        $PWD/$0 kill
        screen -dmS classic-mangos $PWD/$0 detached
        echo "MaNGOS daemon started"
    ;;
    stop )
        # Send ctrl+c to mangos to shut down gracefully.
        # This will make mangos restart.
        # Since we kill the realm reconnecting will not be possible.
        screen -X -S classic-mangos stuff $'\003'
        echo "MaNGOS deamon exit gracefully"
    ;;
    kill )
        # This will kill mangos ungracefully
        screen -X -S classic-mangos quit
        echo "MaNGOS deamon stopped"
    ;;  
    detached )
        while :
        do
                echo `date` >> ${LOGPATH}/crash.log
                cd ${DIR};
                cmd="./mangosd"
                $cmd
                status=$?
                echo "Status after downtime is: $status"
                mv ${LOGPATH}/Server.log ${LOGPATH}/Server$(date +%F-%H:%M).log && touch ${LOGPATH}/Server.log
                if [ "$status" == "2" ]; then
                   echo `date` ", MaNGOS daemon restarted."
                elif [ "$status" == "0" ]; then
                   echo "date" ", MaNGOS daemon shut down."
                   exit 0
                else
                   mv ${LOGPATH}/crash.log ${LOGPATH}/crash$(date +%F-%H:%M).log && touch ${LOGPATH}/crash.log
                   echo "date" ", MaNGOS daemon crashed."
                   ((crashcount=crashcount+1))
                   if [ "$crashcount" -gt 50 ]; then
                      exit 0
                   fi
                fi
        done
        ;;
esac