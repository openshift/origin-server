#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

/bin/rm -f  $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz
exit 0
