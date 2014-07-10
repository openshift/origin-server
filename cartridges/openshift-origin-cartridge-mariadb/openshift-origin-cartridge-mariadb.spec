%global cartridgedir %{_libexecdir}/openshift/cartridges/mariadb

Summary:       Provides embedded mariadb support
Name:          openshift-origin-cartridge-mariadb
Version:       1.16.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mariadb-server
Requires:      mariadb-devel

# For RHEL6 install mysql55 from SCL
%if 0%{?rhel}
Requires:      mariadb55
Requires:      mariadb55-mariadb-devel
%endif

Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides mariadb cartridge support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jul 10 2014 Adam Miller <admiller@redhat.com> 1.16.1-1
- bump necessary spec versions for Origin v4 (admiller@redhat.com)
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)
- Merge pull request #5256 from mfojtik/bugzilla/1086807
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086807 - Advertise $PATH for scaled SCL based cartridges
  (mfojtik@redhat.com)
- Bug 1103367: Increasing timeout of the stop action in the MySQL cartridge
  (jhadvig@redhat.com)
- Bump cartridge versions for STG cut (vvitek@redhat.com)
- Bug 1092635 - Assume zero-byte dump file is quota error and report
  (jhonce@redhat.com)
- Remove newlines from env ERBs (ironcladlou@gmail.com)
- Bug 1090708 - Removing newlines from _LOG_DIR.erb templates
  (bleanhar@redhat.com)
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Revert "Updated cartridges to stop after post_restore" (bparees@redhat.com)
- Merge pull request #5063 from bparees/config_mysql_table_cache
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)
- MySQL table_open_cache size unusually small (bparees@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)
- Remove unused teardowns (dmcphers@redhat.com)
- Updated cartridges to stop after post_restore (mfojtik@redhat.com)
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- Update mariadb cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)
- Bug 1066945 - Fixing urls (dmcphers@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Bump up cartridge versions (bparees@redhat.com)
- Merge pull request #4510 from andrewklau/patch-1
  (dmcphers+openshiftbot@redhat.com)
- Removed the redundant moving of manifest.yml (andrew@andrewklau.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)
- Fix quotation for --password in mariadb cartridge control file
  (andrew.lau@ready2order.com.au)
- Attempt #2 to add MariaDB 5.5 support to RHEL from SCL based on recent MySQL
  Patch (andrew.lau@ready2order.com.au)
- Attempt to add MariaDB 5.5 support through SCL based on recent MySQL commit
  (andrew.lau@ready2order.com.au)
- Attempt to add MariaDB 5.5 support through SCL based on recent MySQL commit
  (andrew.lau@ready2order.com.au)
- Bump cartridge versions for 2.0.35 (pmorie@gmail.com)
- Bump cartridge versions (fotios@redhat.com)
- Fix mariadb tests. (mrunalp@gmail.com)
- MariaDB update based on MySQL cart changes (kraman@gmail.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)
- Bug 980515 - Remove extraneous Conflicts element (jhonce@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)
- Updated cartridges and scripts for phpmyadmin-4 (mfojtik@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)
- Cartridge - Clean up manifests (jhonce@redhat.com)
- Various cleanup (dmcphers@redhat.com)
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
