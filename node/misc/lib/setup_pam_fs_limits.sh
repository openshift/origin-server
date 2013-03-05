#!/bin/bash
#
# Sets up the PAM filesystem and quota limits for an OpenShift gear
#


#
# Add a PAM limit set to the user
#
# IN: username
# IN: limits_order
# IN: limits_nproc
#

LIMITSVARS="core data fsize memlock nofile rss stack cpu nproc as maxlogins priority locks sigpending msgqueue nice rprio"

function set_pam_limits {
    USERNAME=$1
    #assume these come from sourced config file into environment
    #LIMITS_ORDER=${2:-$limits_order}
    #LIMITS_NPROC=${3:-$limits_nproc}

    LIMITSFILE=/etc/security/limits.d/${limits_order}-${USERNAME}.conf

    if [ -z "${NOOP}" ]
    then
	cat <<EOF > ${LIMITSFILE}
# PAM process limits for guest $USERNAME
# see limits.conf(5) for details
#Each line describes a limit for a user in the form:
#
#<domain> <type> <item> <value>
EOF
    else
	echo "cat <<EOF > ${LIMITSFILE}
# PAM process limits for guest $USERNAME
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


#
# Return the mount point of the file system for a given path
#
function get_mountpoint() {
    df -P $1 2>/dev/null | tail -1 | awk '{ print $6 }'
}

# Are quotas enabled on the specified directory?
function quotas_enabled {
    # DIR=$1
    QUOTA_ROOT=`get_mountpoint $1`
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
    if quotas_enabled $GEAR_BASE_DIR
    then
        setquota --always-resolve $1 0 $2 0 $3 `get_mountpoint $GEAR_BASE_DIR`
    else
        echo "WARNING: quotas not enabled on $GEAR_BASE_DIR" >&2
    fi
}

# ============================================================================
#                                 MAIN
# ============================================================================

# Load defaults and node configuration
source /etc/openshift/node.conf


# defaults
limits_order=84
limits_nproc=100
quota_files=1000
# a block = 1Kbytes: 1k * 1024 * 128
quota_blocks=`expr 1024 \* 128` # 128MB

# Load system configuration
source /etc/openshift/resource_limits.conf


# Allow the command line to override quota and limits
username=$1
quota_blocks_custom=$2
quota_files_custom=$3
nproc_custom=$4

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
