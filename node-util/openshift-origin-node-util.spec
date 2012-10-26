Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-node-util
Version:        0.0.7
Release:        1%{?dist}

Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       oddjob
Requires:       rng-tools
Requires:       rubygem-openshift-origin-node
Requires:       php >= 5.3.2
Requires:       php < 5.4.0
BuildArch:      noarch

%description
This package contains a set of utility scripts for a node.  They must be
run on a node instance.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
cp bin/oo-* %{buildroot}%{_bindir}/
cp bin/rhc-* %{buildroot}%{_bindir}/

mkdir -p %{buildroot}/%{_sysconfdir}/httpd/conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/dbus-1/system.d/
mkdir -p %{buildroot}/%{_localstatedir}/www/html/

cp conf/oddjob/openshift-restorer.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp conf/oddjob/oddjobd-restorer.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp www/html/restorer.php %{buildroot}/%{_localstatedir}/www/html/

%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}%{_initddir}
cp init.d/openshift-gears %{buildroot}%{_initddir}/
%else
mkdir -p %{buildroot}/etc/systemd/system
mv services/openshift-gears.service %{buildroot}/etc/systemd/system/openshift-gears.service
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0750,-,-) %{_bindir}/oo-accept-node
%attr(0750,-,-) %{_bindir}/oo-admin-ctl-gears
%attr(0750,-,-) %{_bindir}/oo-app-idle
%attr(0750,-,-) %{_bindir}/oo-autoidler
%attr(0750,-,-) %{_bindir}/oo-idler
%attr(0750,-,-) %{_bindir}/oo-idler-stats
%attr(0750,-,-) %{_bindir}/oo-init-quota
%attr(0750,-,-) %{_bindir}/oo-last-access
%attr(0750,-,-) %{_bindir}/oo-list-stale
%attr(0750,-,-) %{_bindir}/oo-restorer
%attr(0750,-,apache) %{_bindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_bindir}/oo-setup-node
%attr(0750,-,-) %{_bindir}/rhc-list-ports

%doc LICENSE
%doc README-Idler.md

%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/oddjobd.conf.d/oddjobd-restorer.conf
%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/dbus-1/system.d/openshift-restorer.conf

%{_localstatedir}/www/html/restorer.php

%if 0%{?fedora}%{?rhel} <= 6
%attr(0750,-,-) %{_initddir}/openshift-gears
%else
%attr(0750,-,-) /etc/systemd/system
%endif

%post
/sbin/restorecon /usr/bin/oo-restorer* || :

%changelog
* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Fix lock file (jhonce@redhat.com)
- Refactor oo-admin-ctl-gears to use lib/util functions (jhonce@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.0.6-1
- Update documentation with expected httpd access log format
  (jhonce@redhat.com)
- Idler requires PHP to restore gear (jhonce@redhat.com)
- fixed single quotes to doubble in oo-admin-ctl-gears GEAR_GECOS subst
  (mlamouri@redhat.com)

* Mon Oct 22 2012 Adam Miller <admiller@redhat.com> 0.0.5-1
- Fixing Origin build scripts (kraman@gmail.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Change libra guest to OpenShift guest (dmcphers@redhat.com)
- Update Idler documentation (jhonce@redhat.com)
- Wrong name transition in pam.d/sshd. (rmillner@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Port auto-Idler to origin-server (jhonce@redhat.com)
- Fixing outstanding cgroups issues Removing hardcoded references to "OpenShift
  guest" and using GEAR_GECOS from node.conf instead (kraman@gmail.com)
- Use internal functions for that. (rmillner@redhat.com)
- setup polyinstantiation. (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Set a password on the mongo admin db so that application and ssh'd users
  cannot access the DB. Misc other fixes (kraman@gmail.com)
- Adding support for quota and pam fs limits (kraman@gmail.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Clean up spec file (jhonce@redhat.com)
- Port oo-init-quota command (jhonce@redhat.com)
- Port admin scripts for on-premise (jhonce@redhat.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- Fixed gear admin script and added systemd and init.d startup scripts
  (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.2-1
- new package built with tito

