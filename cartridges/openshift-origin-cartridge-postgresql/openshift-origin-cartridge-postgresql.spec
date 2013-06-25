%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 0.4.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      postgresql < 9
%endif
%if 0%{?fedora} >= 19
Requires:      postgresql >= 9.2
Requires:      postgresql < 9.3
%endif
Requires:      postgresql-server
Requires:      postgresql-libs
Requires:      postgresql-devel
Requires:      postgresql-contrib
Requires:      postgresql-ip4r
Requires:      postgresql-jdbc
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
Requires:      %{?scl:%scl_prefix}rubygem-pg
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
%__rm -rf %{buildroot}%{cartridgedir}/versions/9.2
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
%__rm -rf %{buildroot}%{cartridgedir}/versions/8.4
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%__rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
