%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/postgresql-8.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/postgresql-8.4

Name: openshift-origin-cartridge-postgresql-8.4
Version: 1.0.0
Release: 1%{?dist}
Summary: Provides embedded PostgreSQL support

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

BuildRequires: git
Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: postgresql
Requires: postgresql-server
Requires: postgresql-libs
Requires: postgresql-devel
Requires: postgresql-contrib
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
Obsoletes: cartridge-postgresql-8.4

%description
Provides PostgreSQL cartridge support to OpenShift


%prep
%setup -q


%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git init
git add -f .
git config user.email "builder@example.com"
git config user.name "Template builder"
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore


%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.14.9-1
- Fix to cleanup old env vars after migration on removing db from scalable app.
  (mpatel@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.14.8-1
- Fix for bugz 867299 - Always meet time out error when embed postgresql to
  app. (ramr@redhat.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.14.7-1
- Fix for bugz 864164 - The PostgreSQL server is not running during deploy hook
  execution. (ramr@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.14.6-1
- Merge pull request #661 from ramr/master (openshift+bot@redhat.com)
- Merge pull request #656 from mrunalp/bugs/865087 (openshift+bot@redhat.com)
- Don't use rhcsh to control remote dbs. Also fix a typo in the postgres
  cartridge -- variable name. (ramr@redhat.com)
- BZ 865087: Add postgresql-contrib to cartridge. (mpatel@redhat.com)
- Cartridge Fix for BZ807443 (jhonce@redhat.com)
- Fix functions to get installed dbs. (mpatel@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.14.5-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.14.4-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Typeless gear changes (mpatel@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- fix for bug#857345 (rchopra@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Tue Sep 11 2012 Troy Dawson <tdawson@redhat.com> 0.13.4-1
- BZ 852395: Exit from deconfigure when db type doesn't match.
  (mpatel@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Add support to move postgres cart from/to gears. (mpatel@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- Clean up DB environment variables during pre-destroy (ironcladlou@gmail.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- Merge pull request #415 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #410 from rmillner/dev/rmillner/bug/849074
  (openshift+bot@redhat.com)
- fix for Bug 849035 - env vars should be removed for app when db cartridge is
  removed (rchopra@redhat.com)
- BZ 849074: The gear_uuid needed to be updated in additional places.
  (rmillner@redhat.com)

* Mon Aug 20 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- BZ 849074: backup and restore didnt take into account the secondary gear.
  (rmillner@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- US2102: Allow PostgreSQL to be embedded in a scalable application.
  (rmillner@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Merge pull request #220 from pravisankar/dev/ravi/bug806273
  (abhgupta@redhat.com)
- - Don't show postgresql-8.4 as valid options to embed cartridge when mysql is
  already installed and viceversa. (rpenta@redhat.com)
- Change references to PostgreSQL. (rmillner@redhat.com)

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
- Merge branch 'master' of github.com:openshift/origin-server (ramr@redhat.com)
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
