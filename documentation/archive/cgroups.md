# @markup markdown
# @title Control Groups in OpenShift

# Control Groups in OpenShift

Cgroups are used to throttle the use of resources on each OpenShift node. Cgroups are a kernel feature that allow restricting the resource utilization in number of subsystems.  You can read more on that [here](https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Resource_Management_Guide/ch-Subsystems_and_Tunable_Parameters.html).

Cgroups are a kernel feature.  Every process is assigned to a group when the process is created.  Processes can be moved from one group to another. Subsystems are kernel modules that manage different resources.  Each subsystem can have different settings for every group.

## Cgroup Services

The cgroup mechanism uses two services to set the initial group of a new process:

  * The Cgroup Rules Daemon (cgred) assigns new processes to a group using a set of matching rules defined in /etc/cgrules.conf.
  * Pam_cgroup is used to assign shell processes to a cgroup after authentication.

A third service provides the filesystem interface to cgroups:

  * The cgconfig service mounts a virtual filesystem which presents the cgroups and subsystem settings as files within a directory tree.  
  
    Note: On Linux hosts which use systemd as the init process (Fedora >= 15 and RHEL7)
    there is no need of a separate cgconfig service, as cgroups are integrated into the
    systemd process.

## Cgroup Management

Cgroups have two primary control interfaces.  There is a set of command line tools (cgclassify, cgget, cgset) which are used to assign processes to a group, and to read and write the subsystem settings. There is also a filesystem interface which allows cgroup control using only ordinary file read and write operation.  

Openshift uses the command line interface.

## Node Startup

When an OpenShift node starts up, it needs to make sure all user cgroup configurations are applied.

The [openshift-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/init/openshift-cgroups) on RHEL and [openshift-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/services/openshift-cgroups.service) on F19 controls the initialization of the openshift control groups.  The openshift-cgroups service uses the [oo-admin-ctl-cgroups](../node/misc/sbin/oo-admin-ctl-cgroups) script to read the configured default values and start cgroups for each OpenShift user.

The list of users for which cgroups are started is established from ```getent passwd``` and finding any user that has "OpenShift guest" as the User ID Info field in /etc/passwd on the node.

Once the service has looked up the list of OpenShift users, a call to startuser in [oo-admin-ctl-cgroups](../node/misc/sbin/oo-admin-ctl-cgroups) on each user is made.

## User Creation and Deletion

When an OpenShift user is created, their cgroup configuration is applied using the default resource limit
values.  The [unix_user_observer](https://github.com/openshift/origin-server/blob/master/node/lib/openshift-origin-node/plugins/unix_user_observer.rb) is invoked, calling after_unix_user_create, which then makes a call to the [oo-admin-ctl-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/sbin/oo-admin-ctl-cgroups) to 'startuser'. When a user is deleted, their cgroup controlled resources are 'frozen' so they won't be able to start any new processes.  Once the user is removed from a node, the cgroup configuration for that user is removed.  The [unix_user_observer](https://github.com/openshift/origin-server/blob/master/node/lib/openshift-origin-node/plugins/unix_user_observer.rb) once again makes a call to [oo-admin-ctl-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/sbin/oo-admin-ctl-cgroups) to 'stopuser' is made.

## Start and Stop a User Control Group

Default resource limit settings  are configured in ```/etc/openshift/resource_limits.conf``` which is installed by the [rubygem-openshift-origin-node rpm](https://github.com/openshift/origin-server/blob/master/node/rubygem-openshift-origin-node.spec) based upon the [resource_limits](https://github.com/openshift/origin-server/blob/master/node/conf/resource_limits.template) template.

Post cgroup initialization, each OpenShift user has a cgroup configuration, which can be found in the cgroup path under ```/openshift/$USER```.

The [oo-admin-ctl-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/sbin/oo-admin-ctl-cgroups) startuser functionality will apply the default resource limits, and will create a cgroup rule in ```/etc/cgrules.conf``` specific to the new user.

Any time the control group rules are altered, the cgred process needs to be reloaded.  Our tools use ```pkill -USR2``` to reload the cgred.

The [oo-admin-ctl-cgroups](https://github.com/openshift/origin-server/blob/master/node/misc/sbin/oo-admin-ctl-cgroups) stopuser functionality will use cgdelete to remove the cgroup for the user and remove the user rule in ```/etc/cgrules.conf```.


## Optimizations

The configure hook on all cartridges increases the cpu quota as an optimization, allowing the configure hook to finish more quickly.  You'll
notice every cartridge we ship has a configure hook that disables and enables cgroups.  The call to ```disable_cgroups``` in the configure hooks only lifts the ```cpu.cfs_quota_us``` resource restriction, and does not in fact disable all cgroups.  The ```disable_cgroups``` function will set the ```cpu.cfs_quota_us``` to whatever value is in ```cpu.cfs_period_us```.  Once the configure hook is done doing its work, the original setting to ```cpu.cfs_quota_us``` is restored.


## Check the Control Groups Configuration

[oo-accept-node](https://github.com/openshift/origin-server/blob/master/node-util/bin/oo-accept-node) can be used to make sure all
the cgroups are configured properly.  You can also use ```lscgroup cpu,cpuacct,memory,freezer,net_cls:/openshift``` to see what cgroups are
configured.

[cgsnapshot](https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html-single/Resource_Management_Guide/#ex-cgsnapshot-usage)
can be used to see the current current rules the kernel is operating under.

All gear accounts must have a cgroup for each subsystem:

    #search /etc/passwd for gear accounts
    #  verify that /openshift/<acctname> exists for each subsystem

    SUBSYSTEMS="cpu cpuacct freezer memory net_cls"
    for ACCT in $(grep guest /etc/passwd | cut -d: -f1)
    do
      ACCTSS=$(lscgroup | grep /openshift/$ACCT | cut -d: -f1 | tr ",\n" " " | sort)
      for SUBSYSTEM in $SUBSYSTEMS
      do
        if ! echo "$ACCTSS" | grep -q -s "$SUBSYSTEM "
        then
          echo "account $ACCT is missing cgroup subsystem $SUBSYSTEM"
        fi
      done
      test -d /cgroup/all/openshift/${ACCT} || echo "$ACCT is missing cgroup directory"  
    done


All gear accounts must have a cgrules.conf entry:
    
    for ACCTNAME in $(grep guest /etc/passwd | cut -d: -f1)
    do 
      if ! grep -s -q $ACCTNAME /etc/cgrules.conf
      then 
        echo "$ACCTNAME does not have a cgrules.conf entry"
      fi
    done


All gear processes must be assigned to their cgroups:

    For all processes owned by the account UID
      verify that the process is a member of each of the subsystems used by Openshift

You can determine the cgroup of a process with *ps*.
  
  ```ps -o cgroup <pid>```
  
Using this and some clever *sed* operations you can check each user process to be sure it is properly contained.
This is a more exhaustive and complex test:

    #!/bin/sh
    #
    # Check that all user processes are contained by their cgroup
    #
    # This is horribly inefficient.  It uses repeated calls to ps to get different
    # cgroup elements rather than re-using a single call.
    # This is for ease of coding and clarity of reading.
    # Use oo-accept-node or the openshift-cgroups service status in the real world.
    #
    PROCESSES_CHECKED=0
    ACCOUNTS_CHECKED=0
    FAIL=0
    
    # return the cgroups for a process, one per line
    function process_cgroups() {
        # PID=$1
        ps -o cgroup --no-header $1 | sed 's/^[0-9]*:// ; s/,\([0-9]\):/;/g'
    }
    
    # True if the given process is contained by the subsystem in the group path
    function process_is_member() {
        # PID=$1
        # SUBSYSTEM=$2
        # GPATH=$3
        # PROC_CGROUPS=$4
        ACTUAL_PATH=$(echo "$4" | sed -e 's/;/\n/g' | grep -e $2[,:] | cut -d: -f2)
        if [ "$ACTUAL_PATH" != $3 ] ; then
    	return 1
        fi
        return 0
    }
    
    #
    # Is the process a member of the provided group path for all subsystems
    #
    OPENSHIFT_SUBSYSTEMS="cpu cpuacct freezer memory net_cls"
    function process_contained() {
        # PID=$1
        # CGROUP_PATH=$2
        # PROC_CGROUPS=$3
        PROCESSES_CHECKED=$((PROCESSES_CHECKED + 1))
        for SUBSYSTEM in $OPENSHIFT_SUBSYSTEMS ; do
    	if ! process_is_member $1 $SUBSYSTEM $2 "$3" ; then
    	    return 1
    	fi
        done
        return 0
    }
    
    # Check that all processes for an account are contained in the subsystem cgroup
    function account_contained() {
        # ACCOUNT=$1
        ACCOUNTS_CHECKED=$(($ACCOUNTS_CHECKED + 1))
        for PID in $(ps --no-headers -o pid -u $1) ;  do
          PROC_CGROUPS=$(ps -o cgroup --no-header $PID | sed 's/^[0-9]*:// ; s/,\([0-9]\):/;/g')
          if ! process_contained $PID /openshift/$1 "$PROC_CGROUPS" ;then
    	  return 1
          fi
      done
      return 0
    }
    
    # Check that all user processes are contained by their subsystem cgroups
    for ACCOUNT in $(grep 'guest' /etc/passwd | cut -d: -f1) ; do
        if ! account_contained $ACCOUNT ; then
    	echo ERROR: $1 ;  FAIL=$(($FAIL + 1))
        fi
    done
    
    if [ $FAIL -eq 0 ] ; then echo PASS ; else echo FAIL ; fi
    echo accounts: $ACCOUNTS_CHECKED, processes: $PROCESSES_CHECKED