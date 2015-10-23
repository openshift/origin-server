%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Utility scripts for the OpenShift Origin node
Name:          openshift-origin-node-util
Version: 1.38.5
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      oddjob
Requires:      rng-tools
Requires:      rubygem-openshift-origin-node
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      httpd
Requires:      php >= 5.3.2
Requires:      lsof
Requires:      shadow-utils
%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch

# Needed for custom openshift policy. Bug 1024531
BuildRequires: selinux-policy >= 3.7.19-231
Requires:      selinux-policy-targeted >= 3.7.19-231
Requires:      policycoreutils-python
Requires:      policycoreutils


%description
This package contains a set of utility scripts for a OpenShift node.
They must be run on a OpenShift node instance.

%prep
%setup -q

%build
# Needed for custom openshift policy  Bug 1024531
pushd selinux >/dev/null
make -f /usr/share/selinux/devel/Makefile
bzip2 -9 openshift.pp
popd >/dev/null


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_sbindir}
mkdir -p %{buildroot}%{_bindir}

# Needed for custom openshift policy. Bug 1024531
mkdir -p %{buildroot}%{_datadir}/selinux/packages
mkdir -p %{buildroot}%{_datadir}/selinux/include/services

install -m 644 selinux/openshift.pp.bz2 %{buildroot}%{_datadir}/selinux/packages/openshift.pp.bz2
install -m 644 selinux/openshift.if     %{buildroot}%{_datadir}/selinux/include/services/openshift.if

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

%clean
rm -rf %{buildroot}

%post
# Needed for custom openshift policy. Bug 1024531
/usr/sbin/semodule -i %{_datadir}/selinux/packages/openshift.pp.bz2 || :

/sbin/restorecon /usr/sbin/oo-restorer* || :
/sbin/restorecon /usr/bin/oo-lists-ports || :

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
%attr(0750,-,-) %{_sbindir}/oo-gear-firewall
%attr(0750,-,apache) %{_sbindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_sbindir}/oo-httpd-singular
%attr(0750,-,-) %{_sbindir}/oo-su
%attr(0750,-,-) %{_sbindir}/oo-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-repair-node
%attr(0750,-,-) %{_sbindir}/oo-admin-regenerate-gear-metadata
%attr(0750,-,-) %{_sbindir}/oo-watchman
%attr(0750,-,-) %{_sbindir}/oo-admin-geartop
%attr(0750,-,-) %{_initddir}/openshift-watchman
%attr(0755,-,-) %{_bindir}/rhc-list-ports
%attr(0755,-,-) %{_bindir}/oo-snapshot
%attr(0755,-,-) %{_bindir}/oo-restore
%attr(0755,-,-) %{_bindir}/oo-binary-deploy
%attr(0755,-,-) %{_bindir}/unidle_gear.sh
%attr(0755,-,-) %{_bindir}/oo-config-eval
%attr(0755,-,-) %{_bindir}/oo-gear-registry
%attr(0755,-,-) %{_bindir}/oo-lists-ports
%attr(0755,-,-) %{_sysconfdir}/openshift/watchman/plugins.d/
%attr(0744,-,-) %{_sysconfdir}/openshift/watchman/plugins.d/*

# Needed for custom openshift policy. Bug 1024531
%attr(0644,-,-) %{_datadir}/selinux/packages/openshift.pp.bz2
%{_datadir}/selinux/include/services/openshift.if

%{_mandir}/man8/oo-accept-node.8.gz
%{_mandir}/man8/oo-admin-gear.8.gz
%{_mandir}/man8/oo-admin-geartop.8.gz
%{_mandir}/man8/oo-gear-firewall.8.gz
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
%{_mandir}/man8/oo-admin-repair-node.8.gz
%{_mandir}/man8/oo-admin-regenerate-gear-metadata.8.gz

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
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.38.5-1
- Merge pull request #6284 from Miciah/bug-1260204-2
  (dmcphers+openshiftbot@redhat.com)
- oo-last-access: Fix failure if no last access file (miciah.masters@gmail.com)
- oo-watchman.8: "with it's" -> "with its" (miciah.masters@gmail.com)

* Tue Oct 20 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.4-1
- Merge pull request #6276 from thrasher-redhat/master
  (dmcphers+openshiftbot@redhat.com)
- oo-auto-idler man page: updates man page to be consistent with functionality
  (rthrashe@redhat.com)

* Thu Oct 15 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.3-1
- oo-restorecon: run it on the gear's top level dir (pep@redhat.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.2-1
- Fix verbose option for oo-restorecon man page (nakayamakenjiro@gmail.com)
- oo-accept-node Report errors if selinux contexts on $GEAR_BASE_DIR are
  incorrect (tiwillia@redhat.com)

* Thu Sep 17 2015 Unknown name 1.38.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.37.3-1
- Bug 1260204 - Only write newer timestamps to last_access files
  (agrimm@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.37.2-1
- oo-accept-node: Parse manifest with Manifest class (miciah.masters@gmail.com)
- oo-accept-node: honor application names starting with 0 (mmahut@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.37.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.36.3-1
- Merge pull request #6170 from tiwillia/bz1230911
  (dmcphers+openshiftbot@redhat.com)
- Bug 1031796 - Install missing man pages (jhonce@redhat.com)
- Validate gear frontend configurations for vhost plugin (tiwillia@redhat.com)
- Merge pull request #6173 from jwhonce/bug/1232907
  (dmcphers+openshiftbot@redhat.com)
- Bug 1130488 - Capture StandardError not Exception (jhonce@redhat.com)
- Bug 1232907 - Only unidle on start by user (jhonce@redhat.com)
- Merge pull request #6167 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6166 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1187841 (dmcphers@redhat.com)
- Use gear uuid instead of login name to describe arg (dmcphers@redhat.com)
- Merge pull request #6165 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Fixes 1140552 and 1140558 (dmcphers@redhat.com)
- Bug 1140486 (dmcphers@redhat.com)
- Merge pull request #6087 from getupcloud/patch-2
  (dmcphers+openshiftbot@redhat.com)
- oo-init-quota: Ignore commented lines in /etc/fstab (tiwillia@redhat.com)
- Watchman retry delay delta is in seconds (getup@getupcloud.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 1.36.2-1
- Bug 1136425 Bug link https://bugzilla.redhat.com/show_bug.cgi?id=1136425
  Disable password aging for gear users (tiwillia@redhat.com)

* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.36.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Tue Apr 07 2015 Wesley Hearn <whearn@redhat.com> 1.35.2-1
- Bug 1207486 - stop_lock gears have status of "started" (bleanhar@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.35.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)
- oo-admin-ctl-gears: removing a white space (mmahut@redhat.com)
- node-util: add oo-admin-geartop (sdodson@redhat.com)

* Tue Feb 24 2015 Adam Miller <admiller@redhat.com> 1.34.4-1
- Bug 1190856 - Allow Operator to stop gear with .stop_lock (jhonce@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.34.3-1
- Merge pull request #6080 from dobbymoodge/watchman_BZ1134686
  (dmcphers+openshiftbot@redhat.com)
- Avoid skipping jenkins builders in gear ps list (jolamb@redhat.com)

* Thu Feb 19 2015 Adam Miller <admiller@redhat.com> 1.34.2-1
- Fixing typos (dmcphers@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.34.1-1
- Handle all encodings during regex comparisons (ironcladlou@gmail.com)
- Allow gear prioritization in startall/stopall (agrimm@redhat.com)
- Merge pull request #6010 from a13m/bz1171289-master
  (dmcphers+openshiftbot@redhat.com)
- Fix tests for OOMPlugin (agrimm@redhat.com)
- Merge pull request #5986 from detiber/bz1165719
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)
- Bug 1171289 - background pkill command in OOMPlugin (agrimm@redhat.com)
- Bug 1165719 - oo-accept-node incorrectly using manifests from cart repository
  (jdetiber@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.33.3-1
- Merge pull request #6017 from a13m/bz1173180-m
  (dmcphers+openshiftbot@redhat.com)
- Bug 1173180 - Check for frontend directory existence before calling rm_r
  (agrimm@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.33.2-1
- Merge pull request #6018 from sosiouxme/bz1172548-oo-last-access
  (dmcphers+openshiftbot@redhat.com)
- oo-last-access: fix gear UUID detection (lmeyer@redhat.com)
- oo-last-access: rename "app" to "gear" (lmeyer@redhat.com)
- restorer.php: allow predictable UUIDs to be restored too (lmeyer@redhat.com)
- Bug 1172323 - Only remove unreferenced empty directories from the frontend
  configuration (rpenta@redhat.com)
- Revert "Bug 1169306: Clean up standalone db gear http conf in watchman."
  (admiller@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Tue Dec 02 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Bug 1169306: Clean up standalone db gear http conf in watchman.
  (mrunalp@gmail.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)
- Use absolute path to apachectl (agrimm@redhat.com)
- Merge pull request #5767 from sztsian/bz1132299
  (dmcphers+openshiftbot@redhat.com)
- bz1132299 throw runtime error if oo-admin-cartridge failed to install a
  cartridge (sztsian@gmail.com)
- Bug 1163910 - Rename watchman log files (jhonce@redhat.com)
- Bug 1163068 - Update oo-watchman man page (jhonce@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.31.3-1
- Merge pull request #5954 from ncdc/bug/1161072-vhost-multi-ha-app-dns
  (dmcphers+openshiftbot@redhat.com)
- Register app dns vhost for secondary haproxy gears (agoldste@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.31.2-1
- Merge pull request #5910 from a13m/aggressive-oom-kill
  (dmcphers+openshiftbot@redhat.com)
- Fix unit test for oom_plugin (agrimm@redhat.com)
- Don't call unidle prematurely from GearStatePlugin (agoldste@redhat.com)
- Kill out-of-memory gears more aggressively to reduce downtime
  (agrimm@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- Fix calls to config (jhonce@redhat.com)
- Bug 1162096 - Fix oo-admin-gear destroygear (jhonce@redhat.com)
- Merge pull request #5932 from jwhonce/bug/1160752
  (dmcphers+openshiftbot@redhat.com)
- Bug 1160752 - Make Watchman frontend cleanup period configurable
  (jhonce@redhat.com)
- Revert "bz1147054 - use common lockfile" (jhonce@redhat.com)
- Revert "bz1151744 - wrap the wait for reload to finish inside of the
  lockfile" (jhonce@redhat.com)
- Bug 1160752 - Add Watchman plugin to clean up vhost configurations
  (jhonce@redhat.com)
- Bug 1160752 - Make apache-vhost more atomic (jhonce@redhat.com)
- Perf Improvement? (dmcphers@redhat.com)
- Bug 1160770 - consider CNAMEs when checking last access (agrimm@redhat.com)
- node-util: "conflicting TE rule" for openshift.pp (lmeyer@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- bz1151744 - wrap the wait for reload to finish inside of the lockfile
  (rchopra@redhat.com)

* Mon Oct 13 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- node: add oo-gear-firewall tool (lmeyer@redhat.com)

* Wed Oct 01 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Bug 1141922 (lnader@redhat.com)

* Tue Sep 30 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- bz1147054 - use common lockfile (rchopra@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- Watchman filters out haproxy/logshifter (agoldste@redhat.com)
- Bug 1141304 - use full path for pwck (jhonce@redhat.com)
- Fully qualify repquota path usages to avoid PATH lookups
  (ironcladlou@gmail.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.29.5-1
- Merge pull request #5802 from ironcladlou/bz/1140144
  (dmcphers+openshiftbot@redhat.com)
- Increase watchman OOM plugin timeout (ironcladlou@gmail.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.29.4-1
- Bug 1024531 - Update requires for selinux-policy version (jhonce@redhat.com)

* Tue Sep 09 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Bug 1024531 - Add custom openshift policy (jhonce@redhat.com)
- Bug 1024531 - /proc/net provides too much information (jhonce@redhat.com)
- Bug 1101167 - Update man page (jhonce@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1135617 - AVC denied messages when creating new gears
  (bleanhar@redhat.com)
- oo-accept-node: remove check for unused settings (lmeyer@redhat.com)
- Merge pull request #5771 from ironcladlou/bz/1134106
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5761 from brenton/BZ1131031
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5570 from nak3/fix01 (dmcphers+openshiftbot@redhat.com)
- Use portable output format df commands (ironcladlou@gmail.com)
- Bug 1131031 - improving /etc/group, /etc/shadow recovery
  (bleanhar@redhat.com)
- Fix unclear variable name (nakayamakenjiro@gmail.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- re-arrange oo-accept-node to test mod_rewrite stuff only when the plugin is
  present (rchopra@redhat.com)
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.28.4-1
- Merge pull request #5718 from rajatchopra/xfs
  (dmcphers+openshiftbot@redhat.com)
- fix accept-node for vhost vs rewrite plugin presence (rchopra@redhat.com)
- use repquota for xfs - bz1128932 (rchopra@redhat.com)

* Mon Aug 18 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Merge pull request #5713 from
  twiest/dev/twiest/regenerate_gear_metadata_options
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-regenerate-gear-metadata: Changed to using oo_spawn and node cgroup
  libraries. Added --quiet and --no-accept-node options. (twiest@redhat.com)

* Wed Aug 13 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Added oo-admin-regenerate-gear-metadata (twiest@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Bug 1121217 - Symbol leak in Throttler cgroup code (jhonce@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.5-1
- Merge pull request #5670 from rajatchopra/bz_watchman
  (dmcphers+openshiftbot@redhat.com)
- add debug messages to watchman that print memory usage (bz1123935)
  (rchopra@redhat.com)
- fix bz1123935 - patch a sign for tz when missing (rchopra@redhat.com)

* Fri Jul 25 2014 Troy Dawson <tdawson@redhat.com> 1.27.4-1
- Bug 1121864 - Cleanup OPENSHIFT_PRIMARY_CARTRIDGE_DIR (jhonce@redhat.com)
- Bug 1121067 - Updated error messages (jhonce@redhat.com)

* Wed Jul 23 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Merge pull request #5624 from Miciah/bug-1121224-oo-accept-node-handle-non-
  existence-of-slash-sbin-slash-ip (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5623 from Miciah/bug-1121206-oo-accept-node-add-
  check_ext_net_dev_addr (dmcphers+openshiftbot@redhat.com)
- oo-accept-node: Handle non-existence of /sbin/ip (miciah.masters@gmail.com)
- oo-accept-node: Add check_ext_net_dev_addr (miciah.masters@gmail.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Bug 1120463 - Update man pages (jhonce@redhat.com)
- Bug 1119609 - Support vendor in oo-admin-cartridge (jhonce@redhat.com)
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Merge pull request #5545 from a13m/bz1112378
  (dmcphers+openshiftbot@redhat.com)
- Bug 1112378 - Respect OPENSHIFT_CGROUP_SUBSYSTEMS in oo-accept-node
  (agrimm@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Bug 1111077 - Enforce FrontendHttpServer state to match .state file
  (jhonce@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.25.5-1
- Bug 1104902 - Fix several bugs in OOM Plugin app restarts (agrimm@redhat.com)

* Mon Jun 16 2014 Troy Dawson <tdawson@redhat.com> 1.25.4-1
- Merge pull request #5508 from jwhonce/bug/1109324
  (dmcphers+openshiftbot@redhat.com)
- Bug 1109324 - Enable job control in oo-su (jhonce@redhat.com)

* Fri Jun 13 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- oo-accept-node: check_user: use configured quotas (misalunk@redhat.com)

* Wed Jun 11 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- WIP Node Platform - Add tests for OOM Plugin (jhonce@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.24.5-1
- Move cgroup sample timestamp insertion and fix unit test (agrimm@redhat.com)
- Bug 1100518 - Correct throttler's CPU usage math (agrimm@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Merge pull request #5446 from jwhonce/bug/1100648
  (dmcphers+openshiftbot@redhat.com)
- Bug 1100648 - Fixed formatting of man page (jhonce@redhat.com)

* Fri May 23 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Merge pull request #5439 from jwhonce/bug/1100372
  (dmcphers+openshiftbot@redhat.com)
- Bug 1100372 - Add missing spec file dependency (jhonce@redhat.com)
- Bug 1099754 - Set default_command to help (jhonce@redhat.com)

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
