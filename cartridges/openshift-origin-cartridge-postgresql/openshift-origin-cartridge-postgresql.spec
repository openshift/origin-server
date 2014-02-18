%if 0%{?fedora}%{?rhel} <= 6
    %global scl postgresql92
    %global scl_prefix postgresql92-
    %global scl_ruby ruby193
    %global scl_prefix_ruby ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 1.21.0
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
