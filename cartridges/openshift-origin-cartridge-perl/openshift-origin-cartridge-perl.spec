%global cartridgedir %{_libexecdir}/openshift/cartridges/perl

Name:          openshift-origin-cartridge-perl
Version:       1.15.1
Release:       1%{?dist}
Summary:       Perl cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      facter
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mod_perl
Requires:      perl-DBD-SQLite
Requires:      perl-DBD-MySQL
Requires:      perl-MongoDB
Requires:      ImageMagick-perl
Requires:      gd-devel
Requires:      perl-App-cpanminus
Requires:      perl-CPAN
Requires:      perl-CPANPLUS
Requires:      rpm-build
Requires:      expat-devel
Requires:      perl-IO-Socket-SSL
Requires:      gdbm-devel

%if 0%{?fedora}%{?rhel} <= 6
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 19
Requires:      httpd > 2.3
Requires:      httpd < 2.5
%endif

Obsoletes: openshift-origin-cartridge-perl-5.10

BuildArch: noarch

%description
Perl cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec


%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%if 0%{?fedora}%{?rhel} <= 6
rm -rf %{buildroot}%{cartridgedir}/versions/5.16
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
rm -rf %{buildroot}%{cartridgedir}/versions/5.10
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 0.9.3-1
- Merge pull request #3620 from ironcladlou/dev/cart-version-bumps
  (dmcphers+openshiftbot@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)
- Fix Apache PassEnv config files (vvitek@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 0.9.2-1
- Fix bug 1004899: remove legacy subscribes from manifests (pmorie@gmail.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.9.1-1
- Bug 1001713 - Set PERL_VERSION number in setup (jhonce@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.8.7-1
- Merge pull request #3456 from tdawson/tdawson/fixmirrorfix/2013-08
  (admiller@redhat.com)
- change mirror.openshift.com to mirror1.ops.rhcloud.com for aws mirroring
  (tdawson@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.8.6-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 0.8.5-1
- fix old mirror url (tdawson@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 0.8.4-1
- Updated 'restart' operation for all HTTPD based cartridges to use
  'httpd_restart_action' (mfojtik@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 0.8.3-1
- Merge pull request #3376 from brenton/BZ986300_BZ981148
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Bug 981148 - missing facter dependency for cartridge installation
  (bleanhar@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- Merge pull request #3021 from rvianello/readme_cron (dmcphers@redhat.com)
- Fix bug 990864: status check for stopped perl app (pmorie@gmail.com)
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
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)
- <perl cart> bug 977914 remove broken symlinks (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- Merge pull request #2958 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
- Bug 977950 - Copying the v1 descriptions back into the v2 versions of the
  cartridge. (rmillner@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 0.5.4-1
- Bug 975700 - check the httpd pid file for corruption and attempt to fix it.
  (rmillner@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Bug 974534 - Add support for CPANMINUS_HOME (jhonce@redhat.com)
- Bug 974534 - Add support for CPANMINUS_HOME (jhonce@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Add version check around DefaultRuntimeDir directive as it is available only
  on apache 2.4+ (kraman@gmail.com)
- Update perl package for F19 versions. (kraman@gmail.com)
- Fix stop for httpd-based carts. (mrunalp@gmail.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- Bug 968340 - Update MIMEMagicFile in conf files (jhonce@redhat.com)

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

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Bug 960880 - PassEnv required for mod_perl (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- fix missing target for cp (rchopra@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2261 from jwhonce/wip/card287
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_287 - Bug fix (jhonce@redhat.com)
- Add health urls to each v2 cartridge. (rmillner@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- WIP Cartridge Refactor - cleanup in cartridges (jhonce@redhat.com)
- fixing tests (dmcphers@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2187 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- install and post setup tests (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.9-1
- Bug 947356 - Add Requires gd-devel (jhonce@redhat.com)
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 0.2.8-1
- Bug 952041 - Add support for tidy to DIY and PHP cartridges
  (jhonce@redhat.com)
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Calling oo-admin-cartridge from a few more v2 cartridges
  (bleanhar@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Merge pull request #1930 from mrunalp/dev/cart_hooks (dmcphers@redhat.com)
- Add hooks for other carts. (mrunalp@gmail.com)
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Add build to V2 Perl Cartridge (jhonce@redhat.com)
- adding all the jenkins jobs (dmcphers@redhat.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- BZ928282: Copy over hidden files under template. (mrunalp@gmail.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Merge pull request #1755 from mrunalp/dev/perl_rhc_app_create_fixes
  (dmcphers@redhat.com)
- Fixes to get rhc app create working for perl. (mrunalp@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- Fix cart names to exclude versions. (mrunalp@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- Fix perl version to 5.10 (dmcphers@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Tue Mar 12 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Fixing tag on master

* Fri Mar 08 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.1-1
- new package built with tito

* Wed Feb 20 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.0-1
- Initial SPEC created
