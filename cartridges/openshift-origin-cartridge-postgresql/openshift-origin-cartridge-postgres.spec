%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/postgresql
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/postgresql

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql
Version: 0.2.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
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
Provides PostgreSQL cartridge support to OpenShift. (Cartridge Format V2)


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

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/postgresql

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


* Wed Apr 04 2013 Fotios Lindiakos <fotios@redhat.com> 0.0.1-1
- Initial V2 Package
