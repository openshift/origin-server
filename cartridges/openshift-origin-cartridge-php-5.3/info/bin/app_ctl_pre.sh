#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="php-5.3"

export PHPRC="${OPENSHIFT_HOMEDIR}/$cartridge_type/conf/php.ini"
