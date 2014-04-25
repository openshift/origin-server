%if 0%{?fedora}%{?rhel} <= 6
    %global scl postgresql92
    %global scl_prefix postgresql92-
    %global scl_ruby ruby193
    %global scl_prefix_ruby ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 1.24.2
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
