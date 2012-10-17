#!/bin/bash
#
# default values
#

source /etc/openshift/node.conf
DEFAULT_OPENSHIFT_SKEL_DIR=$GEAR_SKEL_DIR

# defaults
limits_order=84

CART_DIR=/usr/libexec/openshift/cartridges

function load_node_conf {
    if [ -f '/etc/openshift/node.conf' ]
    then
        . /etc/openshift/node.conf
    elif [ -f 'node.conf' ]
    then
        . node.conf
    else
        echo "node.conf not found.  Cannot continue" 1>&2
        exit 3
    fi
}

function load_resource_limits_conf {
    if [ -f '/etc/openshift/resource_limits.conf' ]
    then
        . /etc/openshift/resource_limits.conf
    fi
}

function initialize {
    load_node_conf

    load_resource_limits_conf

    if [ -z "$openshift_dir" ]
    then
	      openshift_dir=$GEAR_BASE_DIR
    fi
}

#
# Add a PAM limit set to the user
#
# IN: username
# IN: limits_order
#

LIMITSVARS="core data fsize memlock nofile rss stack cpu nproc as maxlogins priority locks sigpending msgqueue nice rprio"

function remove_pam_limits {
    USERNAME=$1
    LIMITS_ORDER=${2:-$limits_order}

    LIMITSFILE=/etc/security/limits.d/${LIMITS_ORDER}-${USERNAME}.conf

    ${NOOP} rm -f ${LIMITSFILE}
}

# conditions

# ============================================================================
# Quota management
# ============================================================================
#
# We need to be able to find the terminal mount point or device file for
# the filesystem containing the Libra application home directories.
#
# df(1) will present the device and mountpoint when given a file or directory
#
# A terminal mount point is identified when the device is either a UUID or
# a file path in /dev.
#
# If it is not, and the mount options contain 'bind' then search again using
# dirname of the bind "device" path.
#
# repeat until you find a terminal device
#
#function get_filesystem() {
#    # $1=openshift_dir
#    df -P $1 | tail -1 | tr -s ' ' | cut -d' ' -f 1
#}

function get_mountpoint() {
    df -P $1 | tail -1 | tr -s ' ' | cut -d' ' -f 6 | sort -u
}

function get_mount_device() {
    df -P $1 | tail -1 | tr -s ' ' | cut -d' ' -f 1 | sort -u
}

#
# This is not efficient, but it avoids bind mounts
#
function get_terminal_mountpoint() {
    # DIR=$1
    MP=`get_mountpoint $1`
    DEV=`get_mount_device $1`

    while echo $DEV | grep -v -E '^/dev/|LABEL=|UUID=' >/dev/null 2>&1
    do
	MP=`dirname $DEV`
	DEV=`get_mount_device $MP`
    done

    echo $MP
}

#OPENSHIFT_FILESYSTEM=`get_filesystem $openshift_dir`
OPENSHIFT_MOUNTPOINT=`get_terminal_mountpoint $openshift_dir`
QUOTA_FILE=$( echo ${OPENSHIFT_MOUNTPOINT}/aquota.user | tr -s /)

#
# Find the quota mountpoint by searching back from a known path until
# you find aquota.user
#
function get_quota_root() {
    # DIR=$1
    QUOTA_ROOT=$1
    while [ -n "$QUOTA_ROOT" -a ! -f "$QUOTA_ROOT/aquota.user" ]
    do
        if [ "$QUOTA_ROOT" = "/" ]
        then
            QUOTA_ROOT=""
        else
            QUOTA_ROOT=`dirname $QUOTA_ROOT`
        fi
    done
    echo $QUOTA_ROOT
}

#
# Are quotas configured?
# quotaon prints the status of all configured filesystems
# if no filesystems are configured, there is no output
function quotas_configured {
    test -n `quotaon -u -p -a > /dev/null 2>&1`
}

# Are quotas enabled on the specified directory?
function quotas_enabled {
    # DIR=$1
    QUOTA_ROOT=`get_quota_root $1`
    # if you can't find the quota root for the given directory, it's not enabled
    if [ -z "${QUOTA_ROOT}" ]
    then
        return 1
    fi
    quotaon -u -p $QUOTA_ROOT >/dev/null 2>&1
    # quotaon returns the opposite of what you expect
    # 1 = enabled, 0 = not enabled
    if [ $? -eq 0 ]
    then
        return 1
    else
        return 0
    fi
}

# Remove filesystem quota limits for the user
function remove_fs_quotas {
    USERNAME=$1
    if quotas_configured
    then
        if quotas_enabled $openshift_dir
        then
            setquota $1 0 0 0 0 `get_quota_root $openshift_dir`
        else
            echo "WARNING: quotas not enabled on $openshift_dir" >&2
        fi
    else
        echo "WARNING: quotas not configured" >&2
    fi
}

# ============================================================================
#                                 MAIN
# ============================================================================

# get configuration values from openshift configuration files or defaults
username=$1
initialize
remove_fs_quotas $username
remove_pam_limits $username
