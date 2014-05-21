%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Utility scripts for the OpenShift Origin node
Name:          openshift-origin-node-util
Version: 1.24.2
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
mkdir -p %{buildroot}/%{_sysconfdir}/sysconfig


cp -p conf/oddjob/openshift-restorer.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp -p conf/oddjob/oddjobd-restorer.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp -p www/html/restorer.php %{buildroot}/%{_localstatedir}/www/html/
cp -p www/html/health.txt %{buildroot}/%{_localstatedir}/www/html/
cp -p conf/sysconfig/watchman %{buildroot}/%{_sysconfdir}/sysconfig

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
%attr(0755,-,-) %{_sysconfdir}/openshift/watchman/plugins.d/
%attr(0744,-,-) %{_sysconfdir}/openshift/watchman/plugins.d/*

%{_mandir}/man8/oo-accept-node.8.gz
%{_mandir}/man8/oo-admin-gear.8.gz
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
%attr(0644,-,-) %config(noreplace) %{_sysconfdir}/sysconfig/watchman

%{_localstatedir}/www/html/restorer.php
%{_localstatedir}/www/html/health.txt

%if %{with_systemd}
%attr(0755,-,-) /etc/systemd/system/openshift-gears.service
%else
%attr(0755,-,-) %{_initddir}/openshift-gears
%endif

%changelog
* Wed May 21 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Merge pull request #5434 from jwhonce/bug/1099772
  (dmcphers+openshiftbot@redhat.com)
- Bug 1099772 - Add message for unidle on secondary gear (jhonce@redhat.com)
- Add OOM_CHECK_PERIOD to oo-watchman man page (agrimm@redhat.com)
- Remove an incorrect comment line in oom_plugin (agrimm@redhat.com)
- Introduce oom plugin and disable syslog plugin (agrimm@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- Bug 1097959 - Add THROTTLER_CHECK_PERIOD to detune Throttler
  (jhonce@redhat.com)
- support cygwin in jenkins client shell command detect application platform in
  jenkins client and use it to determine if builder should be scalable update
  bash sdk with function to determine node platform (florind@uhurusoftware.com)
- oo-accept-node: Advise user re: missing user quota (jolamb@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Bug 1091433 - Add setting to detune GearStatePlugin (jhonce@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.23.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.6-1
- Bug 1088620 - Add check to oo-accept-node for empty
  OPENSHIFT_PRIMARY_CARTRIDGE_DIR (jhonce@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.22.5-1
- Bug 1061926 - Use lock file to prevent race between idle/unidle
  (jhonce@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.22.4-1
- Bug 1087755 - node.conf#TRAFFIC_CONTROL_ENABLED defaults to true
  (jhonce@redhat.com)
- Bug 1086104 - improve the setting of TC_CHECK in oo-accept-node
  (bleanhar@redhat.com)
- Bug 1083730 - Move node-web-proxy logs to /var/log/openshift/node
  (jhonce@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.22.3-1
- BZ1086104 - oo-accept-node needs to read tc setting from node.conf
  (calfonso@redhat.com)
- Bug 1086854 - Add timeout when locking operations (jhonce@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Merge pull request #5200 from ncdc/metrics (dmcphers+openshiftbot@redhat.com)
- Metrics - code review changes (andy.goldstein@gmail.com)
- Metrics (andy.goldstein@gmail.com)
- Metrics work (teddythetwig@gmail.com)
- Make metrics plugin delay configurable (ironcladlou@gmail.com)
- Metrics work (teddythetwig@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Bug 1081249 - Refactor SELinux module to be SelinuxContext singleton
  (jhonce@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.21.7-1
- Bug 1080374 - Failing to remove .../limits.d/*-<uuid>.conf
  (jhonce@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.21.6-1
- Merge pull request #5051 from jwhonce/bug/1076640
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Bug 1076640 - Attempt to clean up using FQDN (jhonce@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Merge pull request #5037 from jwhonce/bug/1079261
  (dmcphers+openshiftbot@redhat.com)
- Bug 1079261 - Update to support new cgroup mounts (jhonce@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Node Platform - Add more checks for gear structure (jhonce@redhat.com)
- fix bz1076722 - routes.json may have frontend extensions to fqdn
  (rchopra@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Bug 1077510 1077513 1077587 - Cleanup man page and logging
  (jhonce@redhat.com)
- Card origin_node_39 - Introduce GearStatePlugin (jhonce@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.21.2-1
- Bug 1074627 - Removed unnecessary output (jhonce@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1076008 - Fix pgrep regex usage (jhonce@redhat.com)
- Merge pull request #4944 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1074627 - Improve error handling and make more robust (jhonce@redhat.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Merge pull request #4930 from jwhonce/bug/1071105
  (dmcphers+openshiftbot@redhat.com)
- Bug 1071105 - On validation just print commit timestamp (jhonce@redhat.com)
- Bug 1070719 - Prevent openshift-watchman from running twice
  (jhonce@redhat.com)
- Merge pull request #4900 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix missing variable error (rchopra@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- re-fix oo-auto-idler. bz1072472. all gears will never be idled by the script.
  man page changes (rchopra@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- fix bz1072472 - oo-last-access will be run within oo-auto-idler first and any
  errors related to gears not found will block the operation
  (rchopra@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4869 from jwhonce/bug/1071500
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4868 from jwhonce/bug/1070719
  (dmcphers+openshiftbot@redhat.com)
- Bug 1071500 - Prepend /sbin to ip command (jhonce@redhat.com)
- Bug 1070719 - On restart, wait for stop before starting (jhonce@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Fixing typos (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Card origin_node_39 - Fix spec file for disabled plugin (jhonce@redhat.com)
- Card origin_node_39 - Disable GearStatePlugin (jhonce@redhat.com)
- Card origin_node_39 - Fix unit test (jhonce@redhat.com)
- Card origin_node_39 - Introduce GearStatePlugin (jhonce@redhat.com)
- Merge pull request #4807 from jwhonce/bug/1067345
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4776 from jwhonce/origin_node_39
  (dmcphers+openshiftbot@redhat.com)
- Bug 1067345 - Make *all commands honor stop_lock (jhonce@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)
- Card origin_node_39 - Have Watchman attempt honor state of gear
  (jhonce@redhat.com)

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
