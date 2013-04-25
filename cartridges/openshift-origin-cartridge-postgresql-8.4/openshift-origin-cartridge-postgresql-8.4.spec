%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/postgresql-8.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/postgresql-8.4

Summary:       Provides embedded PostgreSQL support
Name:          openshift-origin-cartridge-postgresql-8.4
Version: 1.8.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
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
BuildRequires: git
BuildArch:     noarch

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

%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
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
* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- BZ912255: Change connection url string to use variable names instead of
  absolute values. (mrunalp@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Audit of remaining front-end Apache touch points. (rmillner@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Apply changes from comments. Fix diffs from brenton/origin-server.
  (john@ibiblio.org)
- Dependency fix for postgres cartridge (john@ibiblio.org)
- Drop dependency on ruby-postgres (john@ibiblio.org)
- Fixes for ruby193 (john@ibiblio.org)
- Fix endpoint manifest entries in database cartridges (ironcladlou@gmail.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- Merge pull request #943 from mscherer/fix/cartridge/typo_in_pgsql_url
  (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- Bug 889923 (dmcphers@redhat.com)
- Manifest file fixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)
- fix assignation of postgresql_dburl, using a inexistant variable
  (misc@zarb.org)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.4-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Fix BZ892006: Make postgresql socket file access solvent and add tests for
  postgres and mysql socket files. (pmorie@gmail.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- remove logic where uuid of a gear could change for a cartridge move - fix
  bug#884589 (rchopra@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- remove logic that attempts to move cart from one gear to another
  (rchopra@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Bug 880108 (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ 877534: Remove DB_SOCKET from db connectors. (mpatel@redhat.com)
- Merge pull request #928 from rmillner/BZ876944 (openshift+bot@redhat.com)
- Merge pull request #923 from pmorie/bugs/876800 (dmcphers@redhat.com)
- Needed cartridge_type to be set. (rmillner@redhat.com)
- Merge pull request #920 from ramr/master (openshift+bot@redhat.com)
- BZ876800: Fix connection URLs for mongo,mysql, and postgres for scalable apps
  (pmorie@gmail.com)
- Fix for BZ 874881. (mpatel@redhat.com)
- Fix for bugz 876836 - add gdal (Geospatial Data Abstraction library) support
  - used w/ GIS modules. (ramr@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix for Bug 873810 (jhonce@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Cleanup deprecated env vars during db deconfigure. (mpatel@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

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
