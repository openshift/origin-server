%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Utility scripts for the OpenShift Origin node
Name:          openshift-origin-node-util
Version: 1.20.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      oddjob
Requires:      rng-tools
Requires:      rubygem-openshift-origin-node
Requires:      httpd
Requires:      php >= 5.3.2
Requires:      lsof
%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch

%description
This package contains a set of utility scripts for a OpenShift node.
They must be run on a OpenShift node instance.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_sbindir}
mkdir -p %{buildroot}%{_bindir}

cp -p sbin/* %{buildroot}%{_sbindir}/
cp -p bin/*  %{buildroot}%{_bindir}/

%if 0%{?fedora} >= 18
  mv %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.4 %{buildroot}%{_sbindir}/oo-httpd-singular
  rm %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.3
%else
  mv %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.3 %{buildroot}%{_sbindir}/oo-httpd-singular
  rm %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.4
%endif

mkdir -p %{buildroot}/%{_sysconfdir}/httpd/conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/dbus-1/system.d/
mkdir -p %{buildroot}/%{_localstatedir}/www/html/
mkdir -p %{buildroot}%{_mandir}/man8/

cp -p conf/oddjob/openshift-restorer.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp -p conf/oddjob/oddjobd-restorer.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp -p www/html/restorer.php %{buildroot}/%{_localstatedir}/www/html/
cp -p www/html/health.txt %{buildroot}/%{_localstatedir}/www/html/

cp -p man8/*.8 %{buildroot}%{_mandir}/man8/

mkdir -p %{buildroot}%{_initddir}
mv init.d/openshift-watchman %{buildroot}%{_initddir}/

mkdir -p %{buildroot}/%{_sysconfdir}/openshift/watchman/plugins.d/
cp -pr conf/watchman/* %{buildroot}/%{_sysconfdir}/openshift/watchman

%if %{with_systemd}
mkdir -p %{buildroot}/etc/systemd/system
mv services/openshift-gears.service %{buildroot}/etc/systemd/system/openshift-gears.service
mv services/openshift-watchman.service %{buildroot}/etc/systemd/system/openshift-watchman.service
%else
cp -p init.d/openshift-gears %{buildroot}%{_initddir}/
%endif

%post
/sbin/restorecon /usr/sbin/oo-restorer* || :

%if %{with_systemd}
%systemd_post openshift-gears.service
%systemd_post openshift-watchman.service

%preun
%systemd_preun openshift-gears.service
%systemd_preun openshift-watchman.service

%postun
%systemd_postun_with_restart openshift-gears.service
%systemd_postun_with_restart openshift-watchman.service
%%else
%postun
/etc/init.d/openshift-watchman restart
%endif

%files
%doc LICENSE
%doc README-Idler.md

%attr(0750,-,-) %{_sbindir}/oo-accept-node
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-gears
%attr(0750,-,-) %{_sbindir}/oo-auto-idler
%attr(0750,-,-) %{_sbindir}/oo-idler-stats
%attr(0750,-,-) %{_sbindir}/oo-init-quota
%attr(0750,-,-) %{_sbindir}/oo-last-access
%attr(0750,-,-) %{_sbindir}/oo-list-access
%attr(0750,-,-) %{_sbindir}/oo-restorecon
%attr(0750,-,-) %{_sbindir}/oo-restorer
%attr(0750,-,-) %{_sbindir}/oo-admin-gear
%attr(0750,-,apache) %{_sbindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_sbindir}/oo-httpd-singular
%attr(0750,-,-) %{_sbindir}/oo-su
%attr(0750,-,-) %{_sbindir}/oo-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-repair-node
%attr(0750,-,-) %{_sbindir}/oo-watchman
%attr(0750,-,-) %{_initddir}/openshift-watchman
%attr(0755,-,-) %{_bindir}/rhc-list-ports
%attr(0755,-,-) %{_bindir}/oo-snapshot
%attr(0755,-,-) %{_bindir}/oo-restore
%attr(0755,-,-) %{_bindir}/oo-binary-deploy
%attr(0755,-,-) %{_bindir}/unidle_gear.sh
%attr(0755,-,-) %{_bindir}/oo-config-eval
%attr(0755,-,-) %{_bindir}/oo-gear-registry
%attr(0755,-,-) %{_sysconfdir}/openshift/watchman/plugins.d
%attr(0744,-,-) %{_sysconfdir}/openshift/watchman/plugins.d/*

%{_mandir}/man8/oo-accept-node.8.gz
%{_mandir}/man8/oo-admin-ctl-gears.8.gz
%{_mandir}/man8/oo-auto-idler.8.gz
%{_mandir}/man8/oo-idler-stats.8.gz
%{_mandir}/man8/oo-init-quota.8.gz
%{_mandir}/man8/oo-last-access.8.gz
%{_mandir}/man8/oo-list-access.8.gz
%{_mandir}/man8/oo-restorecon.8.gz
%{_mandir}/man8/oo-restorer.8.gz
%{_mandir}/man8/oo-restorer-wrapper.sh.8.gz
%{_mandir}/man8/rhc-list-ports.8.gz
%{_mandir}/man8/oo-httpd-singular.8.gz
%{_mandir}/man8/oo-admin-cartridge.8.gz
%{_mandir}/man8/oo-su.8.gz
%{_mandir}/man8/oo-cartridge.8.gz
%{_mandir}/man8/oo-watchman.8.gz

%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/oddjobd.conf.d/oddjobd-restorer.conf
%attr(0644,-,-) %config(noreplace) %{_sysconfdir}/dbus-1/system.d/openshift-restorer.conf

%{_localstatedir}/www/html/restorer.php
%{_localstatedir}/www/html/health.txt

%if %{with_systemd}
%attr(0755,-,-) /etc/systemd/system/openshift-gears.service
%else
%attr(0755,-,-) %{_initddir}/openshift-gears
%endif

%changelog
* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Bug 1063278 - kill user processes before user (lsm5@redhat.com)
- Merge pull request #4704 from lsm5/oo-admin-gear
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4717 from jwhonce/bug/1063172
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4715 from jwhonce/bug/1062573
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063172 - Watchman pid and log files world writable (jhonce@redhat.com)
- Merge pull request #4710 from jwhonce/bug/1063142
  (dmcphers+openshiftbot@redhat.com)
- Bug 1062573 -  abused gear will not be throttled (jhonce@redhat.com)
- Bug 1063142 - Ignore .stop_lock on gear operations (jhonce@redhat.com)
- Bug 1062768 (lsm5@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Bug 1057018 - More accurate message on time mismatch (dmcphers@redhat.com)
- origin_node_185 - Refactor oo-admin-ctl-gears (jhonce@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- origin_node_324 (lsm5@redhat.com)
- Merge pull request #4602 from jhadvig/mongo_update
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - Improve Watchman performance (jhonce@redhat.com)
- Bug 1054449 - Watchman support for chkconfig (jhonce@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)
- Merge pull request #4640 from jwhonce/bug/1018342
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4635 from jwhonce/bug/1057734
  (dmcphers+openshiftbot@redhat.com)
- Bug 1018342 - Stop restore/throttle flapping (jhonce@redhat.com)
- Bug 1057734 - Protect against divide by zero (jhonce@redhat.com)
- Merge pull request #4624 from ironcladlou/dev/syslog
  (dmcphers+openshiftbot@redhat.com)
- Platform logging enhancements (ironcladlou@gmail.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- Bug 1059804 - Watchman support for UTF-8 (jhonce@redhat.com)
- Merge pull request #4620 from jwhonce/bug/1058889
  (dmcphers+openshiftbot@redhat.com)
- Bug 1058889 - Return expected exit code on status operation
  (jhonce@redhat.com)
- Merge pull request #4611 from jwhonce/stage
  (dmcphers+openshiftbot@redhat.com)
- Revert "Merge pull request #4488 from lsm5/new-node_conf" (jhonce@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- Bug 998337 (dmcphers@redhat.com)
- Bug 1034110 (dmcphers@redhat.com)
- Merge pull request #4530 from danmcp/bug1034110
  (dmcphers+openshiftbot@redhat.com)
- Bug 1034110 (dmcphers@redhat.com)
- Bug 998337 (dmcphers@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.18.5-1
- Merge pull request #4488 from lsm5/new-node_conf
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4503 from jwhonce/bug/1054512
  (dmcphers+openshiftbot@redhat.com)
- Bug 1054512 - Verify gear home directory ownership in oo-accept-node
  (jhonce@redhat.com)
- Bug 1054449 - Watchman support for chkconfig (jhonce@redhat.com)
- Merge pull request #4495 from jwhonce/wip/watchman
  (dmcphers+openshiftbot@redhat.com)
- Card origin_node_374 - Port Watchman to Origin (jhonce@redhat.com)
- correct if else syntax (lsm5@redhat.com)
- check for old node conf vars if newer undefined (lsm5@redhat.com)
- check for PROXY_MIN_PORT_NUM if PORT_BEGIN undefined (lsm5@redhat.com)
- correct if else syntax (lsm5@redhat.com)
- check for old and new port num variables (lsm5@redhat.com)
- add PORT_BEGIN parameter to oo-accept-node (lsm5@redhat.com)
- Card origin_node_374 - Port Watchman to Origin (jhonce@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Card origin_node_374 - Port Watchman to Origin (jhonce@redhat.com)
- Card origin_node_374 - Port Watchman to Origin Bug 1053423 - Restore
  OPENSHIFT_GEAR_DNS check to watchman Bug 1053397 - Fix encoding error reading
  spec file Bug 1053422 - Fix state vs. stop_lock check (jhonce@redhat.com)