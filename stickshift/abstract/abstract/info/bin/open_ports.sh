#!/bin/bash

uuid=$1
new_port_request=$2 # This is the offset used 1-5

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

NTABLE="rhc-user-table"             # Switchyard for app UID tables
function uid_to_portbegin {
  echo $(($(($(($1-$GEAR_MIN_UID))*$PROXY_PORTS_PER_GEAR))+$PROXY_MIN_PORT_NUM))
}

function uid_to_portend {
  pbegin=`uid_to_portbegin $1`
  echo $(( $pbegin + $PROXY_PORTS_PER_GEAR - 1 ))
}

function public_port_check()
{
    user_uid=`id -u $1`
    port_request=$2
    start_port=$(uid_to_portbegin $user_uid)
    end_port=$(uid_to_portend $user_uid)

    if [ "$start_port" -gt "$port_request" ] || [ "$port_request" -gt "$end_port" ]
    then
        echo "Requested port $port_request is outside the allowed range" 1>&2
        echo "Must be between $start_port and $end_port" 1>&2
        exit 5
    fi

    echo $port_request
}

# return pid of socat if it is running
function pid_of_socat()
{

    uuid=$2
    port_request=$( echo $1 | awk -F':' '{ print $1 }')
    proxy_port=$( public_port_check $uuid $port_request )
    app_addr=$( echo $1 | awk -F':' '{ print $2 }')
    app_port=$( echo $1 | awk -F':' '{ print $3 }')
    host_addr=$(/usr/bin/facter ipaddress)

    pid=$(pgrep -f "socat.*$proxy_port.*$host_addr.*$app_addr:$app_port.*")
    echo $pid
}

function start_socat()
{
    #port_uri format = "PORTID:INTERNALIP:INTERNALPORT or 1:127.0.5.2:8080 and 2:127.0.5.3:8080"

    port_uri=$1
    uuid=$2

    port_request=$( echo $port_uri | awk -F':' '{ print $1 }')
    proxy_port=$( public_port_check $uuid $port_request )
    app_addr=$( echo $port_uri | awk -F':' '{ print $2 }')
    app_port=$( echo $port_uri | awk -F':' '{ print $3 }')
    host_addr=$(/usr/bin/facter ipaddress)

    # Check to see if it's running
    pid=$(pid_of_socat $port_uri $uuid)
    if [ ! -z $pid ]
    then
        echo "Killing $pid" 1>&2
        kill -9 $pid
        # Add a wait for death here instead of this hack
        sleep .3
    fi
    sleep 1
    /usr/bin/socat -d -lmlocal2 TCP4-LISTEN:${proxy_port},bind=${host_addr},reuseaddr,fork,su=nobody TCP:${app_addr}:${app_port},bind=${app_addr} &
}


for port_file in `/bin/ls ${GEAR_BASE_DIR}/${uuid}/.env/*_PUB_PORT`
do
    source "$port_file"
done

for port_uri in `awk 'BEGIN { for (a in ENVIRON) if (a ~ /_PUB_PORT$/) print ENVIRON[a] }'`
do
    proxy_port_offset=$( echo $port_uri | awk -F':' '{ print $1 }')
    if [ ! -z $new_port_request ] && [ $proxy_port_offset == $new_port_request ]
    then
        start_socat $port_uri $uuid
    elif [ -z $new_port_request ]
    then
        start_socat $port_uri $uuid
    fi
done
