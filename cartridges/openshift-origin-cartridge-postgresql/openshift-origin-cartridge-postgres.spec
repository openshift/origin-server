%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/postgresql
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version:       0.0.9
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      postgresql < 9
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


%description
Provides PostgreSQL cartridge support to OpenShift


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/conf
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%config(noreplace) %{cartridgedir}/conf/
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
* Wed Apr 17 2013 Dan McPherson <dmcphers@redhat.com> 0.0.9-1
- 

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


* Wed Apr 04 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.1-1
- Initial V2 Package
