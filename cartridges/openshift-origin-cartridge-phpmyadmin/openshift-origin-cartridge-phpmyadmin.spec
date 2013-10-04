%global cartridgedir %{_libexecdir}/openshift/cartridges/phpmyadmin

Summary:       phpMyAdmin support for OpenShift
Name:          openshift-origin-cartridge-phpmyadmin
Version: 1.16.0
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      phpMyAdmin < 5.0
Requires:      httpd
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-phpmyadmin-3.4

%description
Provides phpMyAdmin cartridge support. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%if 0%{?fedora}%{?rhel} <= 6
rm -rf %{buildroot}%{cartridgedir}/versions/3.5
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
rm -rf %{buildroot}%{cartridgedir}/versions/3.4
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%post
test -f %{_sysconfdir}/phpMyAdmin/config.inc.php && mv %{_sysconfdir}/phpMyAdmin/config.inc.php{,.orig.$(date +%F)} || rm -f %{_sysconfdir}/phpMyAdmin/config.inc.php
ln -sf %{cartridgedir}/versions/shared/phpMyAdmin/config.inc.php %{_sysconfdir}/phpMyAdmin/config.inc.php

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge remote-tracking branch 'origin/master' into origin_ui_72_membership
  (ccoleman@redhat.com)
- remove admin_tool as a category (rchopra@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.4-1
- Merge pull request #3629 from VojtechVitek/phpmyadmin_lock
  (dmcphers+openshiftbot@redhat.com)
- fix phpmyadmin locking mechanism (vvitek@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Merge pull request #3620 from ironcladlou/dev/cart-version-bumps
  (dmcphers+openshiftbot@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)
- Fix Apache PassEnv config files (vvitek@redhat.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- simplify phpmyadmin requires (dmcphers@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Card origin_runtime_228 - Update PHP My Admin cartridge (mfojtik@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Merge pull request #3455 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- <cartridge versions> origin_runtime_219, Fix up Display-Name: field in
  manifests https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-
  versions (jolamb@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- <cart version> origin_runtime_219, Update carts and manifests with new
  versions, handle version change in upgrade code
  https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-versions
  (jolamb@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)
- Fail gracefully when 'mysql' is not present (asari.ruby@gmail.com)
- Bug 989863 (asari.ruby@gmail.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Bug 982738 (dmcphers@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Check cartridge configure order dependency in the broker (rpenta@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Merge pull request #2899 from VojtechVitek/bz974899_phpmyadmin_config_2
  (dmcphers+openshiftbot@redhat.com)
- Bug 975700 - check the httpd pid file for corruption and attempt to fix it.
  (rmillner@redhat.com)
- fix phpMyAdmin config file (vvitek@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Add version check around DefaultRuntimeDir directive as it is available only
  on apache 2.4+ (kraman@gmail.com)
- Relax phpmyadmin version check (kraman@gmail.com)
- Update phpmyadmin cartridge for F19 version (kraman@gmail.com)
- Fix stop for httpd-based carts. (mrunalp@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- Bug 966319 - Gear needs to write to httpd configuration (jhonce@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- Bug 962662 (dmcphers@redhat.com)
- Bug 965537 - Dynamically build PassEnv httpd configuration
  (jhonce@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- Move folder creation back to setup (dmcphers@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Special file processing (fotios@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.6-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Bug 951337 (dmcphers@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Thu Apr 11 2013 Dan McPherson <dmcphers@redhat.com> 1.7.5-1
- 

* Thu Apr 11 2013 Dan McPherson <dmcphers@redhat.com> 1.7.4-1
- new package built with tito

* Thu Apr 11 2013 Dan McPherson <dmcphers@redhat.com> 1.7.3-1
- new package built with tito

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)
