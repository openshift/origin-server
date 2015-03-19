%if 0%{?fedora}%{?rhel} <= 6
    %global scl postgresql92
    %global scl_prefix postgresql92-
    %global scl_ruby ruby193
    %global scl_prefix_ruby ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 1.33.1
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
Requires:      %{?scl:%scl_prefix}postgis
Requires:      %{?scl:%scl_prefix}pgRouting
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
Requires:      proj-nad
Provides:      openshift-origin-cartridge-postgresql-8.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-postgresql-8.4 <= 1.99.9
BuildArch:     noarch

%description
Provides PostgreSQL cartridge support to OpenShift. (Cartridge Format V2)


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
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/env
%{cartridgedir}/lib
%{cartridgedir}/metadata
%{cartridgedir}/template
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.32.4-1
- Bump cartridge versions for Sprint 58 (maszulik@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.32.3-1
- updating links for developer resources in initial pages for cartridges
  (cdaley@redhat.com)

* Tue Feb 17 2015 Adam Miller <admiller@redhat.com> 1.32.2-1
- Bug 1191181 - Added checking server certs existence when turning on SSL.
  (maszulik@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- Bug 1185031 - allow enabling of execution statistics (maszulik@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- Remove max_prepared_transactions validation check (nakayamakenjiro@gmail.com)
- Add else end for setting max_prepared_transactions
  (nakayamakenjiro@gmail.com)
- Fix bz1181916 (nakayamakenjiro@gmail.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Merge pull request #5949 from VojtechVitek/upgrade_scrips
  (dmcphers+openshiftbot@redhat.com)
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)

* Thu Oct 09 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Bug 1150736 - Add timestamp to postgresql logs (mfojtik@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1139280 - Allow postgresql upgrade to pass when data/ was erased by user
  (mfojtik@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Bump cartridge versions for Sprint 49 (maszulik@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Bug 1123587 - Updated postgresql-8.2 to support
  OPENSHIFT_POSTGRESQL_DATESTYLE (mfojtik@redhat.com)
- Bug 1123587 - Added OPENSHIFT_POSTGRESQL_DATESTYLE env var
  (mfojtik@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.5-1
- bump cart versions for sprint 48 (bparees@redhat.com)

* Mon Jul 28 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Bug 1123587 - Added OPENSHIFT_POSTGRESQL_LOCALE environment variable
  (mfojtik@redhat.com)

* Wed Jul 23 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Merge pull request #5635 from bparees/postgres_ssl
  (dmcphers+openshiftbot@redhat.com)
- Openshift overwrites postgresql.conf during restart, destroying SSL
  configuration (bparees@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- fix bad reference to mysql in postgres cart (bparees@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- Bug 1086807 - Advertise $PATH for scaled SCL based cartridges
  (mfojtik@redhat.com)
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.5-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 1.24.4-1
- Bug 1092635 - Assume zero-byte dump file is quota error and report
  (jhonce@redhat.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Sanity check security and improve pg_hba.conf in Postgres cartridge
  (bparees@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Merge pull request #5283 from bparees/latest_versions (dmcphers@redhat.com)
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)
- "postgresql/data/pg_log/postgresql-Mon.log" should not exist on gear
  (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Merge pull request #5144 from bparees/psql_migrate_restart
  (dmcphers+openshiftbot@redhat.com)
- Revert "Updated cartridges to stop after post_restore" (bparees@redhat.com)
- fix is_running check to properly treat empty pidfile as not running
  (bparees@redhat.com)
- Bug 1082937 - Check if the PID is non-empty for postgresql cartridge
  (mfojtik@redhat.com)
- Postgresql still can be accessed via DB driver after postgresql stop for
  jboss app (bparees@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5079 from bparees/postgres_wrong_log
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Postgresql log still goes to old path after migration (bparees@redhat.com)
- Empty postgres.pid file is still existing in gear after stop
  (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)
- Card origin_cartridge_157 - Add support for setting MAX_CONNECTION and
  SHARED_BUFFERS (mfojtik@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Updated cartridges to stop after post_restore (mfojtik@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Update postgresql cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1066945 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Bump up cartridge versions (bparees@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4494 from mfojtik/bugzilla/1053113
  (dmcphers+openshiftbot@redhat.com)
- Bug 1053113 - Make sure postgresql is running vacuum (mfojtik@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Merge pull request #4483 from jhadvig/gis (dmcphers+openshiftbot@redhat.com)
- Bug 1040948 - Executing PostGIS functions in PostGres9.2 (jhadvig@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Fixing double-slash in python and posgresql cartridge code
  (jhadvig@redhat.com)
