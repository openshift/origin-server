%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Utility scripts for the OpenShift Origin node
Name:          openshift-origin-node-util
Version: 1.16.0
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

cp -p bin/oo-* %{buildroot}%{_sbindir}/
rm %{buildroot}%{_sbindir}/oo-snapshot
rm %{buildroot}%{_sbindir}/oo-restore
rm %{buildroot}%{_sbindir}/oo-binary-deploy
rm %{buildroot}%{_sbindir}/oo-gear-registry
rm %{buildroot}%{_sbindir}/oo-config-eval
cp -p bin/rhc-* %{buildroot}%{_bindir}/
cp -p bin/oo-snapshot %{buildroot}%{_bindir}/
cp -p bin/oo-restore %{buildroot}%{_bindir}/
cp -p bin/oo-binary-deploy %{buildroot}%{_bindir}/
cp -p bin/oo-gear-registry %{buildroot}%{_bindir}/
cp -p bin/oo-config-eval %{buildroot}%{_bindir}/
cp -p bin/unidle_gear.sh %{buildroot}%{_bindir}/

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


%if %{with_systemd}
mkdir -p %{buildroot}/etc/systemd/system
mv services/openshift-gears.service %{buildroot}/etc/systemd/system/openshift-gears.service
%else
mkdir -p %{buildroot}%{_initddir}
cp -p init.d/openshift-gears %{buildroot}%{_initddir}/
%endif

%post
/sbin/restorecon /usr/sbin/oo-restorer* || :
%if %{with_systemd}
%systemd_post openshift-gears.service

%preun
%systemd_preun openshift-gears.service

%postun
%systemd_postun_with_restart openshift-gears.service
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
%attr(0750,-,apache) %{_sbindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_sbindir}/oo-httpd-singular
%attr(0750,-,-) %{_sbindir}/oo-su
%attr(0750,-,-) %{_sbindir}/oo-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-repair-node
%attr(0755,-,-) %{_bindir}/rhc-list-ports
%attr(0755,-,-) %{_bindir}/oo-snapshot
%attr(0755,-,-) %{_bindir}/oo-restore
%attr(0755,-,-) %{_bindir}/oo-binary-deploy
%attr(0755,-,-) %{_bindir}/unidle_gear.sh
%attr(0755,-,-) %{_bindir}/oo-config-eval
%attr(0755,-,-) %{_bindir}/oo-gear-registry

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
* Fri Oct 04 2013 Adam Miller <admiller@redhat.com> 1.15.5-1
- Merge pull request #3758 from mfojtik/bugzilla/998337
  (dmcphers+openshiftbot@redhat.com)
- Bug 1013653 - Fix oo-su command so it is not duplicating the getpwnam call
  (mfojtik@redhat.com)
- Bug 998337 - Fixed oo-admin-cartridge man page indentation
  (mfojtik@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- node-util: RHBZ#1012830 do not overrite the {min,max}_uid value if not
  defined in facter (mmahut@redhat.com)
- Initial checkin of iptables port proxy script. (mrunalp@gmail.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Bug 1010723 - Only run lscgroup once for check_users (agrimm@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3695 from jwhonce/wip/idle_websockets
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- Bug 1011459 - oo-last-access does not process node-web-proxy/websockets.log
  (jhonce@redhat.com)
- Merge pull request #3687 from mmahut/mmahut/oo_restorecon
  (dmcphers+openshiftbot@redhat.com)
- node-util: extend the oo-restorecon man pages (mmahut@redhat.com)
- RHBZ#1005307 refactor oo-restorecon to accept files as arguments
  (mmahut@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- node-util: RHBZ#1004512 oo-admin-ctl-gears gearstatus show locked status
  (mmahut@redhat.com)
- Report an error if there are no frontend plugins defined.
  (rmillner@redhat.com)
- <oo-accept-node> Fix polyinstantiation sebool detection (jolamb@redhat.com)
- Merge pull request #3502 from rmillner/origin_runtime_245
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- Break out FrontendHttpServer class into plugin modules. (rmillner@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)
- oo-accept-node changes for ruby193-mcollective (bleanhar@redhat.com)
- Adding oo-mco and updating oo-diagnostics to support the SCL'd mcollective
  (bleanhar@redhat.com)

* Wed Sep 11 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- I'm withdrawing this fix.  The deeper issue is that LANG appears to be messed
  up when the script is run and that needs to be diagnosed instead.
  (rmillner@redhat.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Bug 998337 - Added missing man page number (mfojtik@redhat.com)
- Bug 1005421 - the ps command was returning unicode characters, strip them
  out. (rmillner@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Updated cartridges and scripts for phpmyadmin-4 (mfojtik@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- nurture -> analytics (dmcphers@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- <oo-accept-node> Bug 1000174 - oo-accept-node fixes (jdetiber@redhat.com)
- Merge pull request #3428 from mfojtik/bugzilla/998337
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)
- Bug 998337 - Fixed 'untitled' string in some oo commands man pages
  (mfojtik@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.8-1
- Bug 999460 - Trap range error on large, all numeric UUIDs for the test to see
  if the UUID is really a UID. (rmillner@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.7-1
- Merge pull request #3419 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- removing v2 specific logic (dmcphers@redhat.com)
- Bug 998683 - oo-accept-node failed to read manifests from source
  (jhonce@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Merge pull request #3381 from mrunalp/bugs/970939
  (dmcphers+openshiftbot@redhat.com)
- Fix command help. (mrunalp@gmail.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Merge pull request #3335 from Miciah/oo-accept-node-use-Config-class
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3364 from jwhonce/bug/977928
  (dmcphers+openshiftbot@redhat.com)
- Bug 977928 - node-util scripts missing man pages (jhonce@redhat.com)
- Merge pull request #3360 from brenton/BZ997129
  (dmcphers+openshiftbot@redhat.com)
- Bug 997129 - oo-last-access script chokes on /etc/openshift/node.conf with
  only space in configuration line (bleanhar@redhat.com)
- oo-accept-node: Use OpenShift::Config (miciah.masters@gmail.com)
- oo-accept-node: Simplify find_ext_net_dev (miciah.masters@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3352 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3353 from mfojtik/bugzilla/985218
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- remove oo-cart-version Bug 980296 (dmcphers@redhat.com)
- BZ#985218: Display more user-friendly error message when erasing non-existing
  cartridge (mfojtik@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_ui_73_membership_model (ccoleman@redhat.com)
- * Implement a membership model for OpenShift that allows an efficient query
  of user access based on each resource. * Implement scope limitations that
  correspond to specific permissions * Expose membership info via the REST API
  (disableable via config) * Allow multiple domains per user, controlled via a
  configuration flag * Support additional information per domain
  (application_count and gear_counts) to improve usability * Let domains
  support the allowed_gear_sizes option, which limits the gear sizes available
  to apps in that domain * Simplify domain update interactions - redundant
  validation removed, and behavior of responses differs slightly. * Implement
  migration script to enable data (ccoleman@redhat.com)

* Tue Aug 13 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Bug 957442 (dmcphers@redhat.com)

* Fri Aug 09 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Bug 957442 (dmcphers@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Bug 966535 (pmorie@gmail.com)
- Fix bug 971120: add empty gear check for oo-accept-node (pmorie@gmail.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.6-1
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Merge pull request #3224 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 990090 (dmcphers@redhat.com)
- cleanup / fedoraize openshift-origin-node-util.spec (tdawson@redhat.com)
- Merge pull request #3202 from rmillner/misc_bugs
  (dmcphers+openshiftbot@redhat.com)
- Bug 988948 - Enable TC checks. (rmillner@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Origin uses single quotes in config files. (rmillner@redhat.com)
- Separate out libcgroup based functionality and add configurable templates.
  (rmillner@redhat.com)
- Merge pull request #3187 from pmorie/bugs/988949
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 988949: make upgrade checks run exclusively when enabled
  (pmorie@gmail.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Merge pull request #3167 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Workaround for F19 mcollective issue where it goes into inf. loop and 100%%
  cpu usage. Using mcollctive restart instead of mcollective reload.
  (kraman@gmail.com)
- <oo-idler-stats> Bug 977293 - Fix get_app_type for v2 carts
  (jdetiber@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- <oo-auto-idler> add man page (lmeyer@redhat.com)
- Bug 960355 - Fix file permissions. (rmillner@redhat.com)
- Bug 985525: Skip invalid cartridges during recursive installation
  (ironcladlou@gmail.com)
- Add support for upgrade script to be called during cartridge upgrades.
  (pmorie@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.7-1
- Bug 983780 - parse log files separately and compare timestamps on merge
  (rmillner@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.6-1
- Merge pull request #3027 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3023 from rmillner/BZ958355
  (dmcphers+openshiftbot@redhat.com)
- Fix gear env loading by using ApplicationContainer::from_uuid instead of
  ApplicationContainer::new (kraman@gmail.com)
- Bug 982523 - add syslog to oo-admin-ctl-gears (rmillner@redhat.com)
- Merge pull request #3019 from pmorie/bugs/981273
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 981273 (pmorie@gmail.com)

