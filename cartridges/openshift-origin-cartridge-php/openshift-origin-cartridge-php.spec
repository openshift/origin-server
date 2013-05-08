%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/php

Name: openshift-origin-cartridge-php
Version: 0.4.1
Release: 1%{?dist}
Summary: Php cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://www.openshift.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
%if 0%{?fedora}%{?rhel} <= 6
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 18
Requires:      php >= 5.4
Requires:      php < 5.5
Requires:      httpd < 2.5
%endif
Requires:      php
Requires:      mod_bw
Requires:      rubygem-builder
Requires:      php-devel
Requires:      php-pdo
Requires:      php-gd
Requires:      php-xml
Requires:      php-mysql
Requires:      php-pecl-mongo
Requires:      php-pgsql
Requires:      php-mbstring
Requires:      php-pear
Requires:      php-imap
Requires:      php-pecl-apc
Requires:      php-mcrypt
Requires:      php-soap
Requires:      php-bcmath
Requires:      php-process
Requires:      php-pecl-imagick
Requires:      php-pecl-xdebug
Requires:      openshift-origin-node-util

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
PHP cartridge for openshift. (Cartridge Format V2)


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
%if 0%{?fedora}%{?rhel} <= 6
mv %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-2.2/* %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/
rm -rf %{buildroot}%{cartridgedir}/versions/5.4
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora
%endif
%if 0%{?fedora} >= 18
mv %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-2.4/* %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/
rm -rf %{buildroot}%{cartridgedir}/versions/5.3
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora %{buildroot}%{cartridgedir}/metadata/manifest.yml
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel
sed -i 's/#DefaultRuntimeDir/DefaultRuntimeDir/g' %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf.d/openshift.conf.erb
%endif
rm -rf %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-*

%clean
rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/php

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/hooks
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- moving templates to usr (dmcphers@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2280 from mrunalp/dev/auto_env_vars
  (dmcphers+openshiftbot@redhat.com)
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2274 from rmillner/v2_misc_fixes
  (dmcphers+openshiftbot@redhat.com)
- Add /health url to php cartridges. (rmillner@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.7-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- Bug 952041 - Add support for tidy to DIY and PHP cartridges
  (jhonce@redhat.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.2.5-1
- Fixing F18 build of PHP v2 cartridge (kraman@gmail.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Merge pull request #2053 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)
- Action hook cleanup and documentation (ironcladlou@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1971 from mrunalp/bugs/949843 (dmcphers@redhat.com)
- Bug 949843: Don't lock the directory to be synced. (mrunalp@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- Merge pull request #1907 from brenton/spec_fixes1
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fixing path to oo-admin-cartridge (bleanhar@redhat.com)
- Add missing links. (mrunalp@gmail.com)
- Fix how erb binary is resolved. Using util/util-scl packages instead of doing
  it dynamically in code. Separating manifest into RHEL and Fedora versions
  instead of using sed to set version. (kraman@gmail.com)
- adding all the jenkins jobs (dmcphers@redhat.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)
- Adding Apache 2.4 and PHP 5.4 support to PHP v2 cartridge Fix Path to erb
  executable (kraman@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 0.1.7-1
- Merge pull request #1821 from jwhonce/wip/threaddump
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Roll out old threaddump support (jhonce@redhat.com)
- Merge pull request #1817 from jwhonce/wip/threaddump (dmcphers@redhat.com)
- Merge pull request #1818 from mrunalp/dev/haproxy_wip (dmcphers@redhat.com)
- WIP Cartridge Refactor - Add PHP support for threaddump (jhonce@redhat.com)
- Merge pull request #1801 from VojtechVitek/php5_standard
  (dmcphers+openshiftbot@redhat.com)
- HAProxy WIP. (mrunalp@gmail.com)
- Fix health_check.php to conform PHP 5 standards (vvitek@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- getting jenkins working (dmcphers@redhat.com)
- Getting jenkins working (dmcphers@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- adding openshift node util (dmcphers@redhat.com)
- implementing builder_cartridge based on cart categories (dmcphers@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Merge pull request #1741 from mrunalp/dev/php_build_wip
  (dmcphers+openshiftbot@redhat.com)
- adding jenkins teardown (dmcphers@redhat.com)
- PHP build wip. (mrunalp@gmail.com)
- Merge pull request #1718 from mrunalp/bugs/php_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Cleanup setup script and remove unused file. (mrunalp@gmail.com)
- jenkins WIP (dmcphers@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- Merge pull request #1690 from danmcp/master (dmcphers@redhat.com)
- Getting jenkins building (dmcphers@redhat.com)
- Fix php cart to work with cart repo changes. (mrunalp@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Fix issue in copying over template. (mrunalp@gmail.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- PHP cart manifest fixup and other cleanup. (mrunalp@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Fixing tito tags on master

* Wed Mar 13 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

* Wed Feb 13 2013 Mrunal Patel
- new package built with tito
