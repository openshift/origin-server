%global cartridgedir %{_libexecdir}/openshift/cartridges/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/php
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/php

Name:          openshift-origin-cartridge-php
Version: 1.35.2
Release:       1%{?dist}
Summary:       Php cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
%if 0%{?fedora}%{?rhel} <= 6
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      php54
Requires:      php54-php
Requires:      php54-php-pear
%endif
%if 0%{?fedora} >= 19
Requires:      php >= 5.5
Requires:      php < 5.6
%endif
Requires:      php
Requires:      php-pear
Provides:      openshift-origin-cartridge-php-5.3 = 2.0.0
Obsoletes:     openshift-origin-cartridge-php-5.3 <= 1.99.9
BuildArch:     noarch


%description
PHP cartridge for openshift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{httpdconfdir}

%files
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/env
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}


%changelog
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.35.2-1
- Bumping cartridge versions (abhgupta@redhat.com)

* Thu Sep 17 2015 Unknown name 1.35.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.34.2-1
- Bug 1138522 - Ensure performance.conf is processed after httpd_nolog.conf
  (tiwillia@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.34.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Wed Jul 01 2015 Wesley Hearn <whearn@redhat.com> 1.33.3-1
- Merge pull request #6186 from jhadvig/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6185 from jhadvig/php_apc
  (dmcphers+openshiftbot@redhat.com)
- Bump cartridge versions for Sprint 64 (j.hadvig@gmail.com)
- BZ1225327: Setting apc.stat on by default (j.hadvig@gmail.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.33.2-1
- Merge pull request #6180 from bparees/phplimits
  (dmcphers+openshiftbot@redhat.com)
- Missing the default value of ServerLimit and MaxClients in httpd.conf for php
  cartridge (bparees@redhat.com)
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)

* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Wed Apr 08 2015 Wesley Hearn <whearn@redhat.com> 1.32.2-1
- Bump cartridge versions for 2.0.60 (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)
- Updates PHP Composer, updates Help-Topics (jacoblucky@gmail.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.31.4-1
- Bump cartridge versions for Sprint 58 (maszulik@redhat.com)

* Tue Feb 24 2015 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bug 1193193 - Fixed apc.shm_size values for php-5.4 (maszulik@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- updating links for developer resources in initial pages for cartridges
  (cdaley@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.30.3-1
- Bumping cartridge versions (j.hadvig@gmail.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.30.2-1
- Change the style more readable (nakayamakenjiro@gmail.com)
- Fix of bz1176491 (nakayamakenjiro@gmail.com)
- Fix bug 1173796 (vvitek@redhat.com)
- Change PHP 5.4 APC+OPCache memory comsumption formula (vvitek@redhat.com)
- Remove extra unused file (vvitek@redhat.com)
- Fix bug 1173796 (vvitek@redhat.com)
- Refactor PHP enable_modules to support Zend Extensions (vvitek@redhat.com)
- Move Xdebug enabling/disabling logic to enable_modules (vvitek@redhat.com)
- Remove duplicate call to pre_start_httpd_config (vvitek@redhat.com)
- Fix PHP 5.4 Zend OPCache default gear memory consumption (vvitek@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- Merge pull request #6002 from VojtechVitek/enable_zend_opcache
  (dmcphers+openshiftbot@redhat.com)
- Make sure to disable OPCache for PHP 5.3 (vvitek@redhat.com)
- Replace OPENSHIFT_PHP_OPCACHE_MEMORY_CONSUMPTION and tiny changes
  (nakayamakenjiro@gmail.com)
- Fixed zend opcache template (nakayamakenjiro@gmail.com)
- Add zend opcache template to enable it (nakayamakenjiro@gmail.com)
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Bump cartridge versions for Sprint 49 (maszulik@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- BZ1047469 - PHP cart pear downgrade enhancement: exit when it's failed
  (bvarga@redhat.com)
- BZ1047469 - PHP cart: fixes pear package upgrade and downgrade messages
  (bvarga@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- bump cart versions for sprint 48 (bparees@redhat.com)

* Tue Jul 29 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Bug 1094007 - PHP cart: update pear.php.net channel when install
  (bvarga@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- php migration hotfix (vvitek@redhat.com)
- Bug 1112216 - Match specific php module filename (vvitek@redhat.com)
- Fix php upgrade for 0.0.17 - bug 1111115 (vvitek@redhat.com)
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.26.6-1
- Merge pull request #5533 from pmorie/latest_versions (admiller@redhat.com)
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)
- Fix Composer - bug 1110268 (vvitek@redhat.com)
- Merge pull request #5523 from jhadvig/status
  (dmcphers+openshiftbot@redhat.com)
- Making apache server-status optional with a marker (jhadvig@redhat.com)
- Merge pull request #5525 from pmorie/upgrade
  (dmcphers+openshiftbot@redhat.com)
- Fix php upgrade for 0.0.17 (pmorie@gmail.com)

* Wed Jun 18 2014 Adam Miller <admiller@redhat.com> 1.26.5-1
- Dereference variable name in $modvar for comparison (jolamb@redhat.com)
- Remove extra conditions from APC module (vvitek@redhat.com)
- Fix PHP migration (vvitek@redhat.com)
- Refactor enable_php_modules; remove extra ENV VARs (vvitek@redhat.com)
- Bug 1108017: Load .ini modules on php setup (jhadvig@redhat.com)

* Fri Jun 13 2014 Adam Miller <admiller@redhat.com> 1.26.4-1
- Merge pull request #5500 from VojtechVitek/composer
  (dmcphers+openshiftbot@redhat.com)
- Add Composer, the PHP dependency manager (vvitek@redhat.com)

* Wed Jun 11 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Merge pull request #5484 from VojtechVitek/bug_1104228
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1104228 - missing php-5.4 scl in PATH (vvitek@redhat.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Merge pull request #5307 from dobbymoodge/test_php_env_scan
  (dmcphers+openshiftbot@redhat.com)
- php cart: dynamic, controllable php.d seeding (jolamb@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Merge pull request #5286 from bparees/bug_1088230
  (dmcphers+openshiftbot@redhat.com)
- rename locked-memcache.ini to locked-memcached.ini for consistency
  (bparees@redhat.com)
- Bug 1088230 - Fix php-pecl-memcache extension (vvitek@redhat.com)
- Merge pull request #5283 from bparees/latest_versions (dmcphers@redhat.com)
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)
- Fix PHP migration (vvitek@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Merge pull request #5205 from danmcp/master (dmcphers@redhat.com)
- Removing file listed twice warnings (dmcphers@redhat.com)
- php cartridge: fix php-mcrypt module ini filename (jolamb@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Force httpd into its own pgroup (ironcladlou@gmail.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- Fix PHP 5.4 apc.stat logic (vvitek@redhat.com)
- PHP - Development/Production mode (vvitek@redhat.com)
- PHP APC configurable per gear size / env var (vvitek@redhat.com)
- PHP - Remove duplicated files on gears & Leverage use of usr/ shared dir
  (vvitek@redhat.com)
- Enable mcrypt for PHP 5.4 (vvitek@redhat.com)
- Copy PHP extensions INI files to the cartridge code for maintainability
  (vvitek@redhat.com)
- Make restarts resilient to missing/corrupt pidfiles (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Merge pull request #5061 from ironcladlou/graceful-shutdown
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5056 from VojtechVitek/bug_1079780
  (dmcphers+openshiftbot@redhat.com)
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)
- Merge pull request #5046 from VojtechVitek/bug_1039849
  (dmcphers+openshiftbot@redhat.com)
- Replace the client_message with echo (vvitek@redhat.com)
- Fix PHP MySQL default socket (vvitek@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Remove unused teardowns (dmcphers@redhat.com)
- Make dep handling consistent (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- supress pear info warnings (vvitek@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- fix bash regexp in upgrade scripts (vvitek@redhat.com)
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- fix php upgrade version (vvitek@redhat.com)
- fix php erb processing bug (vvitek@redhat.com)
- PHP - DocumentRoot logic (optional php/ dir, simplify template repo)
  (vvitek@redhat.com)
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Merge pull request #4729 from tdawson/2014-02/tdawson/fix-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4372 from maxamillion/admiller/no_defaulttype_apache24
  (dmcphers+openshiftbot@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)
- This directive throws a deprecation warning in apache 2.4
  (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4502 from sosiouxme/custom-cart-confs
  (dmcphers+openshiftbot@redhat.com)
- <php cart> enable providing custom gear server confs (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- fix php-cli include_path; config cleanup (vvitek@redhat.com)
- fix php cart PEAR builds (vvitek@redhat.com)
- php control script cleanup (vvitek@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- Modify PHP stop() to skip httpd stop when the process is already dead
  (hripps@redhat.com)
