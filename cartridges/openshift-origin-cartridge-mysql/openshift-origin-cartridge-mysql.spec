%global cartridgedir %{_libexecdir}/openshift/cartridges/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 1.19.6
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mysql-server
Requires:      mysql-devel
Requires:      mysql-connector-java

# For RHEL6 install mysql55 from SCL
%if 0%{?rhel}
Requires:      mysql55
Requires:      mysql55-mysql-devel
%endif

Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-mysql-5.1

%description
Provides mysql cartridge support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/mysql_context.rhel %{buildroot}%{cartridgedir}/lib/mysql_context
%endif

%if 0%{?fedora} > 18
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/mysql_context.fedora %{buildroot}%{cartridgedir}/lib/mysql_context
%endif

# Remove what left
%__rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*
%__rm %{buildroot}%{cartridgedir}/lib/mysql_context.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4459 from mfojtik/bugzilla/1045342
  (dmcphers+openshiftbot@redhat.com)
- Bug 1045342 - Fix the $MYSQL_VERSION env var is missing for mysql-5.1
  (mfojtik@redhat.com)
- Bug 1051651 - Added more verbose error reporting when MySQL fail to start
  (mfojtik@redhat.com)
- Removed double-slash from my.conf.erb (mfojtik@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Merge pull request #4395 from andrewklau/master
  (dmcphers+openshiftbot@redhat.com)
- Fix quotation for --password in mysql cartridge control file
  (mfojtik@redhat.com)
- mysql cartridge was using a postgresql variable
  (andrew.lau@ready2order.com.au)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- adding OPENSHIFT_MYSQL_TIMEZONE env variable (jhadvig@redhat.com)

* Fri Dec 20 2013 Adam Miller <admiller@redhat.com> 1.19.3-1
- Bug 1044840 (dmcphers@redhat.com)

* Thu Dec 12 2013 Adam Miller <admiller@redhat.com> 1.19.2-1
- Bug 1040065 - Disabled OPENSHIFT_MYSQL_PATH_ELEMENT via SCL
  (mfojtik@redhat.com)
- Be more verbose when MySQL fail to start (mfojtik@redhat.com)
- Card online_cartridge_85 - Add Mysql 5.5 support through SCL
  (mfojtik@redhat.com)

* Wed Dec 04 2013 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 37 (admiller@redhat.com)

* Thu Nov 14 2013 Adam Miller <admiller@redhat.com> 1.18.2-1
- Bumping cartridge versions for 2.0.36 (pmorie@gmail.com)

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 1.18.1-1
- add max connections to tunables (dmcphers@redhat.com)
- bump_minor_versions for sprint 36 (admiller@redhat.com)

* Thu Oct 31 2013 Adam Miller <admiller@redhat.com> 1.17.2-1
- Bug 1025204 (dmcphers@redhat.com)
- Bump cartridge versions for 2.0.35 (pmorie@gmail.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.17.1-1
- Bail out on upgrade in a more shell-friendly way (asari.ruby@gmail.com)
- Use oo-erb instead of erb (asari.ruby@gmail.com)
- Double up memory limits for embedded MySQL cart (asari.ruby@gmail.com)
- Bump MyISAM memory parameters (asari.ruby@gmail.com)
- Bump up memory for standalone cartridges (asari.ruby@gmail.com)
- Guard against removing innoDB logs (asari.ruby@gmail.com)
- Ensure Drupal gears can migrate (asari.ruby@gmail.com)
- Tune MySQL parameters via OPENSHIFT_GEAR_MEMORY_MB (asari.ruby@gmail.com)
- Bump cartridge versions (fotios@redhat.com)
- Bug 1017642: Wait for mysql to start before accesing during restore
  (ironcladlou@gmail.com)
- bump_minor_versions for sprint 35 (admiller@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- Initial checkin of iptables port proxy script. (mrunalp@gmail.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Bug 980515 - Remove extraneous Conflicts element (jhonce@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 0.8.4-1
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 0.8.3-1
- Merge pull request #3599 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1002894 (dmcphers@redhat.com)
- Bug 1002893 - Added mysql-connector-java dependency to mysql cartridge
  (mfojtik@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- Bug 1000167 (dmcphers@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- Updated cartridges and scripts for phpmyadmin-4 (mfojtik@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.7.4-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Merge pull request #3379 from pmorie/bugs/997593
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Fix bug 997593 (pmorie@gmail.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- Cartridge - Clean up manifests (jhonce@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.6.4-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.6.3-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 982738 (dmcphers@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Fix bug 981622 (pmorie@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 0.4.3-1
- Bug 970914 - Mysql big data snapshot restore failed (fotios@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Bug 971296: Display mysql environment variables rather than IPs during
  install (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Merge pull request #2596 from fotioslindiakos/Bug960707
  (dmcphers+openshiftbot@redhat.com)
- Bug960707: MySQL snapshot and restore across applications (fotios@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Bug 962662 (dmcphers@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.3.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- Merge pull request #2246 from ironcladlou/bz/955538
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2241 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2239 from jwhonce/wip/raw_envvar
  (dmcphers+openshiftbot@redhat.com)
- Bug 955538: Don't fail on error in mysql control (ironcladlou@gmail.com)
- Fix bug 956018 - communicate database name to broker for v2 mysql
  (pmorie@gmail.com)
- WIP Cartridge Refactor - cleanup in cartridges (jhonce@redhat.com)
- Bug 956667 - Updated MySQL v2 cart to install with oo-admin-cartridge in
  %%post (jdetiber@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- implementing install and post-install (dmcphers@redhat.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Merge pull request #2161 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Move v2 mysql setup invocation marker to gear data directory
  (pmorie@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.1.7-1
- Fix bug 927850 (pmorie@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.1.6-1
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1968 from pmorie/dev/v2_mysql (dmcphers@redhat.com)
- Add mysql v2 snapshot/restore tests (pmorie@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Add v2 mysql snapshot (pmorie@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Correct mysqld setup and control status. (pmorie@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Dan McPherson <dmcphers@redhat.com> 0.0.5-1
- 

* Wed Mar 20 2013 Adam Miller <admiller@redhat.com> 0.0.4-1
- new package built with tito

* Wed Mar 20 2013 Paul Morie <pmorie@gmail.com> 0.0.3-1
- new package built with tito

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.2-1
- WIP: mysql v2 (pmorie@gmail.com)

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.1-1
- new package built with tito

