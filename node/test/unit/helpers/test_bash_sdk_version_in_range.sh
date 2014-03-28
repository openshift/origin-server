#!/bin/bash -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/../../../misc/usr/lib/cartridge_sdk/bash/sdk 

if version_in_range $1 $2 $3; then
  echo PASS
else
  echo FAIL
fi
