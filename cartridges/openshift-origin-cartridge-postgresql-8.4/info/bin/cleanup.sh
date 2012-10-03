#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

/bin/rm -f $OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz
