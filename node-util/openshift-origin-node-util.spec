%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Utility scripts for the OpenShift Origin node
Name:          openshift-origin-node-util
Version: 1.13.4
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
rm %{buildroot}%{_sbindir}/oo-config-eval
cp -p bin/rhc-* %{buildroot}%{_bindir}/
cp -p bin/oo-snapshot %{buildroot}%{_bindir}/
cp -p bin/oo-restore %{buildroot}%{_bindir}/
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
%attr(0755,-,-) %{_bindir}/unidle_gear.sh
%attr(0755,-,-) %{_bindir}/oo-config-eval

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

