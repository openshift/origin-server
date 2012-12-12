Control Groups in OpenShift
===========================

Cgroups are used to throttle the use of resources on each OpenShift node.
Cgroups are a kernel feature that allow restricting the resource utilization in
number of subsystems.  You can read more on that
[here](https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Resource_Management_Guide/ch-Subsystems_and_Tunable_Parameters.html).


Node Startup
==========================

When an OpenShift node starts up, it needs to start the cgroups services
(cgconfig and cgred) and make sure all user cgroup configurations are applied.
The cgconfig service is used to set up the cgroups filesystem layout.  The
cgred service is used to start the groups rules engine daemon.

The [openshift-cgroups](../node/misc/init/openshift-cgroups) service controls
the initialization of the openshift control groups.  The openshift-cgroups
service uses the [oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups)
script to read the configured default values and start cgroups for each
OpenShift user.

The list of users for which cgroups are started is established from `getent
passwd` and finding any user that has "OpenShift guest" as the User ID Info
field in /etc/passwd on the node.

Once the service has looked up the list of OpenShift users, a call to startuser
in [oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups) on each user
is made.


User Creation and Deletion
==========================

When an OpenShift user is created, their cgroup configuration is applied using the default resource limit
values.  The
[unix_user_observer](../node/lib/openshift-origin-node/plugins/unix_user_observer.rb)
is invoked, calling after_unix_user_create, which then makes a call to the
[oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups) to 'startuser'.
When a user is deleted, their cgroup controlled resources are 'frozen' so they
won't be able to start any new processes.  Once the user is removed from a
node, the cgroup configuration for that user is removed.  The
[unix_user_observer](../node/lib/openshift-origin-node/plugins/unix_user_observer.rb)
once again makes a call to
[oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups) to 'stopuser' is made.

Start and Stop a User Control Group
===================================
Default resource limit settings  are configured in
/etc/openshift/resource_limits.conf which is installed by the
[rubygem-openshift-origin-node rpm](../node/rubygem-openshift-origin-node.spec)
based upon the [resource_limits](../node/conf/resource_limits.template)
template.

Post cgroup initialization, each OpenShift user has a cgroup configuration,
which can be found under /cgroup/all/openshift/$USER.

The [oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups) startuser functionality will apply the default resource limits, and will create a
cgroup rule in /etc/cgrules.conf specific to the new user.

Any time the control group rules are altered, the cgred process needs to be
reloaded.  Our tools use pkill -USR2 to reload the cgred.

The [oo-admin-ctl-cgroups](../node/misc/bin/oo-admin-ctl-cgroups) stopuser functionality will use cgdelete to remove the cgroup for the user and
remove the user rule in /etc/cgrules.conf.


Optimizations
=============

The configure hook on all cartridges increases the cpu quota as an
optimization, allowing the configure hook to finish more quickly.  You'll
notice every cartridge we ship has a configure hook that disables and enables
cgroups.  The call to disable_cgroups in the configure hooks only lifts the
cpu.cfs_quota_us resource restriction, and does not in fact disable all
cgroups.  The disable_cgroups function will set the cpu.cfs_quota_us to
whatever value is in cpu.cfs_period_us.  Once the configure hook is done doing
its work, the original setting to cpu.cfs_quota_us is restored.


Check the Control Groups Configuration
======================================

[oo-accept-node](../node-util/bin/oo-accept-node) can be used to make sure all
the cgroups are configured properly.  You can also use 'lscgroup
cpu,cpuacct,memory,freezer,net_cls:/openshift' to see what cgroups are
configured.

[cgsnapshot](https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html-single/Resource_Management_Guide/#ex-cgsnapshot-usage)
can be used to see the current current rules the kernel is operating under.

All gear accounts must have a cgroup
  search /etc/passwd for gear accounts
   verify that /cgroup/all/openshift/<acctname> exists, containes correct subsystems

for ACCT in $(grep guest /etc/passwd | cut -d: -f1) ; do test -d /cgroup/all/openshift/${ACCT} || echo "$ACCT is missing cgroup directory"  ; done

All gear accounts must have a cgrules.conf entry:

for ACCTNAME in $(grep guest /etc/passwd | cut -d: -f1) ; do if ! grep $ACCTNAME /etc/cgrules.conf >/dev/null 2>/dev/null ; then echo "$ACCTNAME does not have a cgrules.conf entry" ; fi ; done

All gear processes must be assigned to their cgroup
  For all processes owned by the account UID, verify that the PID is listed in cgroup.procs

for ACCTINFO in $(grep guest /etc/passwd | awk -F: '{print $1":"$3}')
do
  ACCTNAME=$(echo ${ACCTINFO} | cut -d: -f1)
  ACCTPID=$(echo ${ACCTINFO} | cut -d: -f2)
  #
  # get the processes with that PID
  PIDLIST=$(ps --no-headers -o pid -u ${ACCTPID})
  GROUPED=$(cat /cgroup/all/openshift/${ACCTNAME}/cgroup.procs)

  if [ "${PIDLIST}" != "${GROUPED}" ]
  then
    echo "Acct Name: ${ACCTNAME} pid: ${ACCTPID}): bad cgroup containment"
    echo " < = Unconfined   > = not owned by gear"
    diff <(echo $PIDLIST | tr ' ' '\n') <(echo $GROUPED | tr ' ' '\n')
  fi
done
