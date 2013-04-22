#!/bin/bash

source /etc/openshift/node.conf
source $CARTRIDGE_BASE_PATH/abstract/info/lib/util


function print_temporary_unidled_msg() {
    cat 2>&1  <<ZEOF
    ***  This gear has been temporarily unidled. To keep it active, access
    ***  your app @ http://$OPENSHIFT_GEAR_DNS/

ZEOF

}

#
#  main():  Check if app is idle and if so temporarily unidle it.
#
if test_app_state "idle"; then
    #  Temporarily unidle the app.
    curl $OPENSHIFT_GEAR_DNS > /dev/null 2>&1

    #  Print temporarily unidled message if asked for.
    [ -z "$1" ]  ||  print_temporary_unidled_msg
fi

