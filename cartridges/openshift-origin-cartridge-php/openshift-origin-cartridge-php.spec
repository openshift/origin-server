%global cartridgedir %{_libexecdir}/openshift/cartridges/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/php
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/php

Name:          openshift-origin-cartridge-php
Version: 1.24.2
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
