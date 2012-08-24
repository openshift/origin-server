#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

# Run pre-dump dumps
for cmd in `awk 'BEGIN { for (a in ENVIRON) if (a ~ /_DUMP$/) print ENVIRON[a] }'`
do
    echo "Running extra dump: $(/bin/basename $cmd)" 1>&2
    $cmd
done

# stop
stop_app.sh 1>&2

# Run tar, saving to stdout
cd ~
cd ..
echo "Creating and sending tar.gz" 1>&2

cart_type=$(basename $(dirname $OPENSHIFT_GEAR_CTL_SCRIPT))
/bin/tar --ignore-failed-read -czf - \
        --exclude=./$OPENSHIFT_GEAR_UUID/.tmp \
        --exclude=./$OPENSHIFT_GEAR_UUID/.ssh \
        --exclude=./$OPENSHIFT_GEAR_UUID/.sandbox \
        --exclude=./$OPENSHIFT_GEAR_UUID/$cart_type/${OPENSHIFT_GEAR_NAME}_ctl.sh \
        --exclude=./$OPENSHIFT_GEAR_UUID/$cart_type/conf.d/stickshift.conf \
        --exclude=./$OPENSHIFT_GEAR_UUID/$cart_type/run/httpd.pid \
        --exclude=./$OPENSHIFT_GEAR_UUID/haproxy-\*/run/stats \
        --exclude=./$OPENSHIFT_GEAR_UUID/app-root/runtime/.state \
        --exclude=./$OPENSHIFT_GEAR_UUID/app-root/data/.bash_history \
        ./$OPENSHIFT_GEAR_UUID

# Cleanup
for cmd in `awk 'BEGIN { for (a in ENVIRON) if (a ~ /_DUMP_CLEANUP$/) print ENVIRON[a] }'`
do
    echo "Running extra cleanup: $(/bin/basename $cmd)" 1>&2
    $cmd
done


# start_app
start_app.sh 1>&2
