%global cartridgedir %{_libexecdir}/openshift/cartridges/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/php

Name:          openshift-origin-cartridge-php
Version: 1.16.0
Release:       1%{?dist}
Summary:       Php cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      facter
Requires:      rubygem(openshift-origin-node)
%if 0%{?fedora}%{?rhel} <= 6
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 19
Requires:      php >= 5.5
Requires:      php < 5.6
Requires:      httpd > 2.3
Requires:      httpd < 2.5
%endif
Requires:      php
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
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-php-5.3

%description
PHP cartridge for openshift. (Cartridge Format V2)

%prep
%setup -q

%build

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/

%if 0%{?fedora}%{?rhel} <= 6
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 18
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora18 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%files
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md


%changelog
* Thu Oct 03 2013 Adam Miller <admiller@redhat.com> 1.15.3-1
- Fix PHP cartridge to wait upto 5 sec for Apache to start and create a pid
  file before returning. This is needed because Apache 2.4 on F19 does a
  reverse DNS lookup on the server hostname and causes a race condition in
  runtime-cartridge-php.feature testcase. (kraman@gmail.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Add support for cartridge protocol types in manifest (rchopra@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 0.9.3-1
- fix drush dir permissions (vvitek@redhat.com)
- Merge pull request #3620 from ironcladlou/dev/cart-version-bumps
  (dmcphers+openshiftbot@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)
- Fix Apache PassEnv config files (vvitek@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 0.9.2-1
- Merge pull request #3554 from pmorie/bugs/1004899
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1004899: remove legacy subscribes from manifests (pmorie@gmail.com)
- Create a writable directory for Drush settings (vvitek@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.9.1-1
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.8.7-1
- Merge pull request #3455 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.8.6-1
- Merge pull request #3424 from mfojtik/bugzilla/998789 (dmcphers@redhat.com)
- Bug 998789 - Fixed a typo in PHP cartridge control script
  (mfojtik@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 0.8.5-1
- Merge pull request #2984 from VojtechVitek/pear_path
  (dmcphers+openshiftbot@redhat.com)
- Add PEAR bin dir to the PATH variable (vvitek@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 0.8.4-1
- Updated 'restart' operation for all HTTPD based cartridges to use
  'httpd_restart_action' (mfojtik@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 0.8.3-1
- Merge pull request #3342 from VojtechVitek/pear_jenkins
  (dmcphers+openshiftbot@redhat.com)
- fix PEAR on scaled gears & jenkins builder (vvitek@redhat.com)
- Bug 981148 - missing facter dependency for cartridge installation
  (bleanhar@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- Merge pull request #3021 from rvianello/readme_cron (dmcphers@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)
- added a note about the required cron cartridge. (riccardo.vianello@gmail.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.7.5-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.7.4-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Bug 982738 (dmcphers@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- <application.rb> Add feature to carts to handle wildcard ENV variable
  subscriptions (jolamb@redhat.com)
- Remove stale file manifest.yml.fedora from openshift-origin-cartridge-php
  (rpenta@redhat.com)
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)
- Bug 977985 (asari.ruby@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.6.3-1
- Merge pull request #2934 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Moving selinux and libvirt container plugins into seperate gem files Added
  nsjoin which allows joining a running container Temporarily disabled cgroups
  Moved gear dir to /var/lib/openshift/gears for libvirt container Moved shell
  definition into container plugin rather than application container
  (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Bug 975700 - check the httpd pid file for corruption and attempt to fix it.
  (rmillner@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Fix php configuration bugs. (mrunalp@gmail.com)
- Add version check around DefaultRuntimeDir directive as it is available only
  on apache 2.4+ (kraman@gmail.com)
- Update PHP cartridge for F19 version (kraman@gmail.com)
- Eliminate noisy output from php control script (ironcladlou@gmail.com)
- Remove rubygem-builder dep from php cartridges (jdetiber@redhat.com)
- Fix stop for httpd-based carts. (mrunalp@gmail.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.8-1
- Merge pull request #2676 from VojtechVitek/php_control_always_return_0
  (dmcphers+openshiftbot@redhat.com)
- fix php control script to always return 0 (vvitek@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 0.4.7-1
- Merge pull request #2652 from VojtechVitek/php_cartridge_cleanup
  (dmcphers+openshiftbot@redhat.com)
- php v2 cartridge clean-up (vvitek@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- Bug 966963: Remove unnecessary versioned conf files from php cart
  (ironcladlou@gmail.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Bug 962662 (dmcphers@redhat.com)
- Bug 965537 - Dynamically build PassEnv httpd configuration
  (jhonce@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- spec file cleanup (tdawson@redhat.com)
- Merge pull request #2521 from VojtechVitek/bz956962_2
  (dmcphers+openshiftbot@redhat.com)
- Fix PHPRC and php.ini path (vvitek@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Bug 963156 (dmcphers@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)

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
