#!/bin/bash

source /etc/stickshift/stickshift-node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

# Run pre-dump dumps
for db in $(get_attached_databases)
do
    dump_cmd=${CARTRIDGE_BASE_PATH}/${db}/info/bin/dump.sh
    echo "Running extra dump for $db" 1>&2
    $dump_cmd
done

# stop
stop_app.sh 1>&2

# Run tar, saving to stdout
cd ~
cd ..
echo "Creating and sending tar.gz" 1>&2

/bin/tar --ignore-failed-read -czf - \
        --exclude=./$OPENSHIFT_GEAR_UUID/.tmp \
        --exclude=./$OPENSHIFT_GEAR_UUID/.ssh \
        --exclude=./$OPENSHIFT_GEAR_UUID/.sandbox \
        --exclude=./$OPENSHIFT_GEAR_UUID/*/conf.d/stickshift.conf \
        --exclude=./$OPENSHIFT_GEAR_UUID/*/run/httpd.pid \
        --exclude=./$OPENSHIFT_GEAR_UUID/haproxy-\*/run/stats \
        --exclude=./$OPENSHIFT_GEAR_UUID/app-root/runtime/.state \
        --exclude=./$OPENSHIFT_GEAR_UUID/app-root/data/.bash_history \
        ./$OPENSHIFT_GEAR_UUID

# Cleanup
for db in $(get_attached_databases)
do
    cleanup_cmd=${CARTRIDGE_BASE_PATH}/${db}/info/bin/cleanup.sh
    echo "Running extra cleanup for $db" 1>&2
    $cleanup_cmd
done


# start_app
start_app.sh 1>&2
