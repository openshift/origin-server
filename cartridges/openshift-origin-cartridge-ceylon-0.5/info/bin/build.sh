#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="ceylon-0.5"

# Run user build
user_build.sh
