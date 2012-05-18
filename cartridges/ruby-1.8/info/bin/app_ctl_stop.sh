#!/bin/bash

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/configuration/etc/conf

# Stop the app
src_user_hook pre_stop_${CARTRIDGE_TYPE}
httpd_pid=`cat ${OPENSHIFT_RUN_DIR}httpd.pid 2> /dev/null`
/usr/sbin/httpd -C "Include ${OPENSHIFT_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
for i in {1..20}
do
    if `ps --pid $httpd_pid > /dev/null 2>&1` || `pgrep Passenger.* > /dev/null 2>&1`
    then
        if [ $i -gt 4 ]
        then
            if `ps --pid $httpd_pid > /dev/null 2>&1`
            then
                if [ $i -gt 16 ]
                then
                    /bin/kill -9 $httpd_pid
                fi
            elif `pgrep Passenger.* > /dev/null 2>&1`
            then
                pkill -9 Passenger.*
                break
            fi
        fi
        echo "Waiting for stop to finish"
        sleep .5
    else
        break
    fi
done
run_user_hook post_stop_${CARTRIDGE_TYPE}
