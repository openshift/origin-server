#!/bin/bash

cartridge_type="ruby-1.8"
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cart_instance_dir=$OPENSHIFT_HOMEDIR/ruby-1.8

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/configuration/etc/conf

# Stop the app
src_user_hook pre_stop_${CARTRIDGE_TYPE}
app_userid=`id -u`
httpd_pid=`cat ${cart_instance_dir}/run/httpd.pid 2> /dev/null`
/usr/sbin/httpd -C "Include ${cart_instance_dir}/conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
for i in {1..20}
do
    if `ps --pid $httpd_pid > /dev/null 2>&1`  ||  \
       `pgrep -u $app_userid Passenger.* > /dev/null 2>&1`
    then
        if [ $i -gt 4 ]
        then
            if `ps --pid $httpd_pid > /dev/null 2>&1`
            then
                if [ $i -gt 16 ]
                then
                    /bin/kill -9 $httpd_pid
                fi
            elif `pgrep -u $app_userid Passenger.* > /dev/null 2>&1`
            then
                pkill -9 -u $app_userid Passenger.*
                break
            fi
        fi
        echo "Waiting for stop to finish"
        sleep .5
    else
        break
    fi
done
run_user_hook post_stop_${cartridge_type}
