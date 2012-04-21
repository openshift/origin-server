%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/postgresql-8.4

Name: cartridge-postgresql-8.4
Version: 0.7.2
Release: 1%{?dist}
Summary: Embedded postgresql support for express

Group: Network/Daemons
License: ASL 2.0
URL: https://engineering.redhat.com/trac/Libra
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-postgresql-8.4

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
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.7.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.9-1
- This was done to allow a cucumber test to continue to work.  The test will be
  fixed in a subsequent commit. Revert "no ports defined now exits 1"
  (rmillner@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.6.8-1
- no ports defined now exits 1 (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.6.7-1
- Relying on being able to send back appropriate output to the broker on a
  failure and we are using return codes inside the script.
  (rmillner@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.6-1
- removed test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.5-1
- Test commit (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.4-1
- test commits (mmcgrath@redhat.com)
- Return in a way that broker can manage. (rmillner@redhat.com)
- Merge remote-tracking branch 'origin/master' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-postgresql-8.4] release [0.6.3-1].
  (mmcgrath@redhat.com)
- test commit (mmcgrath@redhat.com)

* Tue Apr 03 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.3-1
- test commit (mmcgrath@redhat.com)
- Fix for bugz 808013 - Use a postgres data template for speeding up and
  working around initdb issues and don't use initdb. (ramr@redhat.com)

* Tue Apr 03 2012 Mike McGrath <mmcgrath@redhat.com>
- Fix for bugz 808013 - Use a postgres data template for speeding up and
  working around initdb issues and don't use initdb. (ramr@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.6.3-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Fix for bugz 808013 - Use a postgres data template for speeding up and
  working around initdb issues and don't use initdb. (ramr@redhat.com)

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.6.2-1
- Renaming for open-source release

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.6.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.5.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- Update postgres cartridge li/libra => stickshift (kraman@gmail.com)
- take back username and pw (dmcphers@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.4.5-1
- do even less when ip doesnt change on move (dmcphers@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.4.4-1
- Missed that we'd transitioned from OPENSHIFT_*_IP to OPENSHIFT_*_HOST.
  (rmillner@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- Update show-port hook and re-add function. (rmillner@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Fix for bugz 797140 - restore PostgreSQL data using snapshot tarball
  (ramr@redhat.com)
- Embedded cartridges that expose ports should reap their proxy in removal if
  it hasn't been done already. (rmillner@redhat.com)
- Forgot to include uuid in calls (rmillner@redhat.com)
- Use the libra-proxy configuration rather than variables to spot conflict and
  allocation. Switch to machine readable output. Simplify the proxy calls to
  take one target at a time (what most cartridges do anyway). Use cartridge
  specific variables. (rmillner@redhat.com)
- Add port hooks to postgres (rmillner@redhat.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- Fix minor irritant message saying logged in user can't be dropped on a
  restore snapshot (fallout of bugz 791091). (ramr@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.4.1-1
- bump spec numbers (dmcphers@redhat.com)
- Fix for bugz 791091 - snapshot restore postgresql data failure.
  (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.3.4-1
- Bugfixes in postgres cartridge descriptor Bugfix in connection resolution
  inside profile Adding REST API to retrieve descriptor (kraman@gmail.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.3.3-1
- cleaning up specs to force a build (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.3.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)
- Cleanup usage message to include status and fix bug - missing cat.
  (ramr@redhat.com)
