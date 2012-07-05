%global cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/postgresql-8.4

Name: cartridge-postgresql-8.4
Version: 0.11.2
Release: 1%{?dist}
Summary: Embedded postgresql support for express

Group: Network/Daemons
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: postgresql
Requires: postgresql-server
Requires: postgresql-libs
Requires: postgresql-devel
Requires: postgresql-ip4r
Requires: postgresql-jdbc
Requires: postgresql-plperl
Requires: postgresql-plpython
Requires: postgresql-pltcl
Requires: PyGreSQL
Requires: perl-Class-DBI-Pg
Requires: perl-DBD-Pg
Requires: perl-DateTime-Format-Pg
Requires: php-pear-MDB2-Driver-pgsql
Requires: php-pgsql
Requires: postgis
Requires: python-psycopg2
Requires: ruby-postgres
Requires: rhdb-utils
Requires: uuid-pgsql


%description
Provides rhc postgresql cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- more cartridges have better metadata (rchopra@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- Fix for bug 812046 (abhgupta@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.9.3-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.9.2-1
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.8.4-1
- Additional scripts not sourcing util. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.8.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.8.2-1
- Fix typo "immediately". (ramr@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (ramr@redhat.com)
- Fix for bugz 813934 - immediate shutdown to close all sessions if graceful
  shutdown times out. (ramr@redhat.com)
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.8.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.7.5-1
- cleaning up spec files (dmcphers@redhat.com)
- Fix for bugz 812491 - postgresql restore fails when user name begins w/ a
  digit. (ramr@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.7.4-1
- new package built with tito
