%if 0%{?fedora}%{?rhel} <= 6
    %global scl postgresql92
    %global scl_prefix postgresql92-
    %global scl_ruby ruby193
    %global scl_prefix_ruby ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 1.16.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?rhel} <=6
Requires:      postgresql-ip4r
Requires:      postgresql-jdbc
%endif
%if 0%{?fedora}%{?rhel} <= 6
Requires:      postgresql < 9
# PostgreSQL 9.2 with SCL
Requires:      %{scl}
Requires:      %{?scl:%scl_prefix}postgresql-server
Requires:      %{?scl:%scl_prefix}postgresql-libs
Requires:      %{?scl:%scl_prefix}postgresql-devel
Requires:      %{?scl:%scl_prefix}postgresql-contrib
Requires:      %{?scl:%scl_prefix}postgresql-plperl
Requires:      %{?scl:%scl_prefix}postgresql-plpython
Requires:      %{?scl:%scl_prefix}postgresql-pltcl
Requires:      postgresql92-postgis
%endif
%if 0%{?fedora} >= 19
Requires:      postgresql >= 9.2
Requires:      postgresql < 9.3
Requires:      postgis >= 2
%endif
Requires:      postgresql-server
Requires:      postgresql-libs
Requires:      postgresql-devel
Requires:      postgresql-contrib
Requires:      postgresql-plperl
Requires:      postgresql-plpython
Requires:      postgresql-pltcl
Requires:      PyGreSQL
Requires:      perl-Class-DBI-Pg
Requires:      perl-DBD-Pg
Requires:      perl-DateTime-Format-Pg
Requires:      php-pear-MDB2-Driver-pgsql
Requires:      php-pgsql
Requires:      gdal
Requires:      postgis
Requires:      python-psycopg2
Requires:      %{?scl_ruby:%scl_prefix_ruby}rubygem-pg
Requires:      rhdb-utils
Requires:      uuid-pgsql
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-postgresql-8.4

%description
Provides PostgreSQL cartridge support to OpenShift. (Cartridge Format V2)


%prep
%setup -q


%build
%__rm %{name}.spec


%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/util.rhel %{buildroot}%{cartridgedir}/lib/util
%__rm %{buildroot}%{cartridgedir}/lib/util.f19
%endif
%if 0%{?fedora} == 19
%__rm -rf %{buildroot}%{cartridgedir}/versions/8.4
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/util.f19 %{buildroot}%{cartridgedir}/lib/util
%__rm %{buildroot}%{cartridgedir}/lib/util.rhel
%endif
%__rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- Initial checkin of iptables port proxy script. (mrunalp@gmail.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3710 from jwhonce/bug/981780
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 981780 - Fail reload if database is not running (jhonce@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Bug 980515 - Remove extraneous Conflicts element (jhonce@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bump up PostgreSQL memory parameters (asari.ruby@gmail.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.6.6-1
- Merge pull request #3455 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.6.5-1
- move update config to setup (dmcphers@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 0.6.4-1
- Adjust interval before considering auto scale down (dmcphers@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 0.6.3-1
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- Cartridge - Clean up manifests (jhonce@redhat.com)
- Install PostGIS 2.x (asari.ruby@gmail.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.5.6-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.5.5-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.5.4-1
- Bug 982738 (dmcphers@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Fix bug 981584 (pmorie@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bug 984811 (asari.ruby@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.4.7-1
- Bug 983190 (asari.ruby@gmail.com)
- Merge pull request #3052 from
  BanzaiMan/dev/hasari/f19_postgres_cart_version_sync
  (dmcphers+openshiftbot@redhat.com)
- Sync F19 cart version with that of RHEL (asari.ruby@gmail.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- Merge pull request #3042 from BanzaiMan/dev/hasari/bz981528
  (dmcphers+openshiftbot@redhat.com)
- Bug 981528 (asari.ruby@gmail.com)
- Bug 979740 - Fix Postgres cartridge using $HOME (fotios@redhat.com)
- Bug 981528 (asari.ruby@gmail.com)

* Tue Jul 09 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Revert "No need for Ruby SCL here." (asari.ruby@gmail.com)
- Bug 982377 (asari.ruby@gmail.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Document $OPENSHIFT_POSTGRESQL_VERSION (asari.ruby@gmail.com)
- Get postgres running again (dmcphers@redhat.com)
- Bug 981528 (asari.ruby@gmail.com)

* Wed Jul 03 2013 Adam Miller <admiller@redhat.com> 0.4.3-1
- Make more SDK calls (asari.ruby@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- Conflicts: is obsolete. (asari.ruby@gmail.com)
- There is no Group-Overrides needed (asari.ruby@gmail.com)
- Match up "Provides" with what's overridden (asari.ruby@gmail.com)
- No need for Ruby SCL here. (asari.ruby@gmail.com)
- Update $OPENSHIFT_POSTGRES_VERSION for existing cartridges
  (asari.ruby@gmail.com)
- Card online_runtime_157 (asari.ruby@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Update postgresql cartridge for F19 version (kraman@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 0.2.7-1
- Bug 962657: Return db info to client during postgres install
  (ironcladlou@gmail.com)
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Merge pull request #2596 from fotioslindiakos/Bug960707
  (dmcphers+openshiftbot@redhat.com)
- Fix test case in extended postgres tests (fotios@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Bug 962662 (dmcphers@redhat.com)
- Merge pull request #2569 from fotioslindiakos/Bug965105
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2562 from fotioslindiakos/Bug964116
  (dmcphers+openshiftbot@redhat.com)
- Bug 965105: Cannot delete application (fotios@redhat.com)
- Bug 964116: Postgres failed to restore snapshot (fotios@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.2.3-1
- Merge pull request #2515 from fotioslindiakos/postgres_v2
  (dmcphers+openshiftbot@redhat.com)
- spec file cleanup (tdawson@redhat.com)
- Make scaled postgres connection info use hostname instead of IP
  (fotios@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Bug 959123: Unable to restore Postgres snapshot to new application
  (fotios@redhat.com)
- Bug 959123: Suppress output from psql command during start/stop
  (fotios@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Switching v2 to be the default (dmcphers@redhat.com)
- Properly restore Postgres database to new application (fotios@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Bug 959123: Fix Postgresql snapshot restore (fotios@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Special file processing (fotios@redhat.com)
- Validate cartridge and vendor names under certain conditions
  (asari.ruby@gmail.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- <postgres> add %%post to put in cartridge registry on installation
  (lmeyer@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Bug 955973 (dmcphers@redhat.com)
- Postgres V2 fixes (fotios@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.0.8-1
- Postgres V2 snapshot/restore (fotios@redhat.com)

* Fri Apr 12 2013 Dan McPherson <dmcphers@redhat.com> 0.0.7-1
- 

* Fri Apr 12 2013 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- new package built with tito

* Fri Apr 12 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.5-1
- Automatic commit of package [openshift-origin-cartridge-postgresql] release
  [0.0.4-1]. (fotios@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-postgresql] release
  [0.0.2-1]. (fotios@redhat.com)
- Initial commit (fotios@redhat.com)

* Fri Apr 12 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.4-1
- Fixed license and vendor (fotios@redhat.com)

* Fri Apr 12 2013 Fotios Lindiakos <fotios@redhat.com>
- Fixed license and vendor (fotios@redhat.com)

* Fri Apr 12 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.2-1
- Initial v2 commit 

* Wed Apr 03 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.1-1
- Initial V2 Package
