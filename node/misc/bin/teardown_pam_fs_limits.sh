#!/bin/bash
#
# Tear down the PAM filesystem and quota limits for an OpenShift gear
#

#
# Add a PAM limit set to the user
#
# IN: username
# IN: limits_order
#

function remove_pam_limits {
    USERNAME=$1
    LIMITS_ORDER=${2:-$limits_order}

    LIMITSFILE=/etc/security/limits.d/${LIMITS_ORDER}-${USERNAME}.conf

    ${NOOP} rm -f ${LIMITSFILE}
}


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

# Remove filesystem quota limits for the user
function remove_fs_quotas {
    USERNAME=$1
    if quotas_enabled $GEAR_BASE_DIR
    then
        setquota --always-resolve $1 0 0 0 0 `get_mountpoint $GEAR_BASE_DIR`
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

# Load system configuration
source /etc/openshift/resource_limits.conf

username=$1
remove_fs_quotas $username
remove_pam_limits $username
