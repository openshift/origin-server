#!/bin/bash
# Creates an openshift user
#
# IN: username
#     SSH RSA public key
#
# 1) create a local user account: username, home directory
# 2) enable login via SSH using RSA key: trap user
# 3) Place limits on user: number of processes

#
#
# default values
#
source /etc/openshift/node.conf
DEFAULT_OPENSHIFT_SKEL_DIR=$GEAR_SKEL_DIR

# defaults
limits_order=84
limits_nproc=100
quota_files=1000
# a block = 1Kbytes: 1k * 1024 * 128
quota_blocks=`expr 1024 \* 128` # 128MB

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

# Find the filesystem which holds a user's home directory
function home_filesystem {
    df -P ${openshift_dir} | tail -1 | cut -d' ' -f1
}

#
# Add a PAM limit set to the user
#
# IN: username
# IN: limits_order
# IN: limits_nproc
#

LIMITSVARS="core data fsize memlock nofile rss stack cpu nproc as maxlogins priority locks sigpending msgqueue nice rprio"

# TODO: check if file already exists
function set_pam_limits {
    USERNAME=$1
    #assume these come from sourced config file into environment
    #LIMITS_ORDER=${2:-$limits_order}
    #LIMITS_NPROC=${3:-$limits_nproc}

    LIMITSFILE=/etc/security/limits.d/${limits_order}-${USERNAME}.conf

    if [ -z "${NOOP}" ]
    then
	cat <<EOF > ${LIMITSFILE}
# PAM process limits for guest $customer_id
# see limits.conf(5) for details
#Each line describes a limit for a user in the form:
#
#<domain> <type> <item> <value>
EOF
    else
	echo "cat <<EOF > ${LIMITSFILE}
# PAM process limits for guest $customer_id
# see limits.conf(5) for details
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
${USERNAME}     hard    nproc   ${LIMITS_NPROC}
EOF"

    fi

    for KEY in $LIMITSVARS
    do
	VALUE=`eval echo \\$limits_$KEY`
	if [ -n "$VALUE" ]
	then
	    if [ -z "${NOOP}" ]
        then
		    echo "${USERNAME} hard $KEY $VALUE" >> ${LIMITSFILE}
        else
		    echo "echo \"${USERNAME} hard $KEY $VALUE\" >> ${LIMITSFILE}"
	    fi
	fi
    done

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

function get_mount_options() {
    mount | grep " $1 " | sed -e 's/^.*(// ; s/).*$// ' | sort -u
    #cat /etc/fstab | tr -s ' ' | grep $1 | awk '{print $4;}'
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

#
# Set a user's inode and block quotas on the home file system
# usage: set_fs_quota <username> <inodes> <blocks>
function set_fs_quotas {
    # USERNAME=$1
    # QUOTA_BLOCKS=${2:-$quota_blocks}
    # QUOTA_FILES=${3:-$quota_files}

    # get the user home directory
    # get the quota mount point
    if quotas_configured
    then
        if quotas_enabled $openshift_dir
        then
            setquota $1 0 $2 0 $3 `get_quota_root $openshift_dir`
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
quota_blocks_custom=$2
quota_files_custom=$3
nproc_custom=$4
initialize
if [ -n "$quota_blocks_custom" ] && [ $quota_blocks_custom -gt $quota_blocks ]
then
    quota_blocks=$quota_blocks_custom
fi
if [ -n "$quota_files_custom" ] && [ $quota_files_custom -gt $quota_files ]
then
    quota_files=$quota_files_custom
fi
if [ -n "$nproc_custom" ] && [ $nproc_custom -le $limits_nproc ]
then
    limits_nproc=$nproc_custom
fi
set_pam_limits $username
set_fs_quotas $username $quota_blocks $quota_files
