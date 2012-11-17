%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/mongodb-2.2
%global frameworkdir %{_libexecdir}/openshift/cartridges/mongodb-2.2

Name: openshift-origin-cartridge-mongodb-2.2
Version: 1.1.3
Release: 1%{?dist}
Summary: Embedded mongodb support for OpenShift

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git

Requires: openshift-origin-cartridge-abstract
Requires: mongodb-server
Requires: mongodb-devel
Requires: libmongodb
Requires: mongodb

Obsoletes: openshift-origin-cartridge-mongodb-2.0
Obsoletes: cartridge-mongodb-2.0
Obsoletes: cartridge-mongodb-2.2

%description
Provides rhc mongodb cartridge support


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
rm -rf %{buildroot}


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
* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ876800: Fix connection URLs for mongo,mysql, and postgres for scalable apps
  (pmorie@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix for Bug 873810 (jhonce@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Cleanup deprecated env vars during db deconfigure. (mpatel@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.26.10-1
- Merge pull request #777 from rmillner/master (openshift+bot@redhat.com)
- Fix to cleanup old env vars after migration on removing db from scalable app.
  (mpatel@redhat.com)
- BZ 849543: Add informative message about the cartridge credentials.
  (rmillner@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.26.9-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.26.8-1
- Fixes and workarounds for bugz 866385 - Can not restore data in mongodb
  successfully. (ramr@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.26.7-1
- Merge pull request #661 from ramr/master (openshift+bot@redhat.com)
- Merge pull request #653 from pmorie/rename (openshift+bot@redhat.com)
- Fix for mongorestore to workaround mongo 2.2 bug:
  https://jira.mongodb.org/browse/SERVER-7262 (ramr@redhat.com)
- Don't use rhcsh to control remote dbs. Also fix a typo in the postgres
  cartridge -- variable name. (ramr@redhat.com)
- Fix 'Obsoletes' for jbosseap6, port-proxy, mongodb-2.2, and diy
  (pmorie@gmail.com)
- Cartridge Fix for BZ807443 (jhonce@redhat.com)
- Fix functions to get installed dbs. (mpatel@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.26.6-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.26.5-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.26.4-1
- Typeless gear changes (mpatel@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.26.3-1
- Additional string change (rmillner@redhat.com)
- Convert variable names to mongodb-2.2. (rmillner@redhat.com)

* Mon Sep 17 2012 Adam Miller <admiller@redhat.com> 0.26.2-1
- US2755: Move from mongodb-2.0 to mongodb-2.2 (rmillner@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.26.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.25.4-1
- Fix for bugz 856487 - Can't add mongodb-2.2 for ruby1.9 app successfully.
  (ramr@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.25.3-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.25.2-1
- Add support to move postgres cart from/to gears. (mpatel@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.25.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.24.7-1
- Clean up DB environment variables during pre-destroy (ironcladlou@gmail.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.24.6-1
- fix for Bug 849035 - env vars should be removed for app when db cartridge is
  removed (rchopra@redhat.com)

* Mon Aug 20 2012 Adam Miller <admiller@redhat.com> 0.24.5-1
- Add missing variables (rmillner@redhat.com)

* Fri Aug 17 2012 Adam Miller <admiller@redhat.com> 0.24.4-1
- BZ841750: Only mention rockmongo and phpmyadmin for non-scalable installs.
  (rmillner@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.24.3-1
- Merge pull request #387 from rmillner/US2102 (openshift+bot@redhat.com)
- Merge pull request #384 from mrunalp/bugs/848287 (openshift+bot@redhat.com)
- US2102: Allow PostgreSQL to be embedded in a scalable application.
  (rmillner@redhat.com)
- BZ 848287: Pre move not called when move is within district.
  (mpatel@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.24.2-1
- US2696: Support for mysql/mongo cartridge level move. (mpatel@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.24.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- Mysql and mongodb set gear state when on a scalable app.
  (rmillner@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.23.4-1
- Stand-alone mysql or mongodb gears disable stale detection.
  (rmillner@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.23.3-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.23.2-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)
- Fix bugz 840166 - call mongodb repair automatically if ctl script start
  fails. (ramr@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.23.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.22.4-1
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.22.3-1
- Bug fix - should print the correct database name for scalable apps.
  (ramr@redhat.com)

* Thu Jun 21 2012 Adam Miller <admiller@redhat.com> 0.22.2-1
- Merge pull request #155 from rajatchopra/master (rmillner@redhat.com)
- fix for bug#833340: support same district move (rchopra@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.22.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.21.6-1
- httpd config files should get recreated on move/post-move
  (rchopra@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.21.5-1
- Fix for bugz 833029 and applying the same to mongo (rchopra@redhat.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.21.4-1
- Fix for bug 812046 (abhgupta@redhat.com)

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.21.3-1
- BZ824409 call unobfuscate_app_home on mongo and mysql gear moves
  (jhonce@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.21.2-1
- The single quotes cause CART_INFO_DIR to be embedded rather than its
  expansion. (rmillner@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.21.1-1
- bumping spec versions (admiller@redhat.com)
- Fix BZ827585 (jhonce@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.20.8-1
- Bugzilla 825714: Show connection info when mongo is embedded.
  (mpatel@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.20.7-1
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.20.6-1
- Revert "Broke the build, the tests have not been update to reflect this
  changeset." (ramr@redhat.com)
- Broke the build, the tests have not been update to reflect this changeset.
  (admiller@redhat.com)

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.20.5-1
- [mpatel+ramr] Fix issues where app_name is not the same as gear_name - fixup
  for typeless gears. (ramr@redhat.com)
- Fixes to snapshot/restore. (mpatel@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.20.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Fixup from merge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.20.3-1
- Fix cleanup. (mpatel@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.20.2-1
- Fix displayed connection info. (mpatel@redhat.com)
- %%build uses git, so BuildRequires: git (admiller@redhat.com)
- Address review comments. (mpatel@redhat.com)
- Changes to make mongodb run in standalone gear. (mpatel@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.20.1-1
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.19.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Some of the ctl script were not sourcing util from abstract.
  (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.19.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.19.2-1
- Fix for bugz 818377 - cleanup mongo shell history. (ramr@redhat.com)
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.19.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.18.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.18.4-1
- new package built with tito
