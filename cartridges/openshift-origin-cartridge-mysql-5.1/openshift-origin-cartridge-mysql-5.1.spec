%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/mysql-5.1
%global frameworkdir %{_libexecdir}/openshift/cartridges/mysql-5.1

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql-5.1
Version: 1.8.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mysql-server
Requires:      mysql-devel
BuildRequires: git
BuildArch:     noarch

%description
Provides mysql cartridge support to OpenShift


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

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- BZ912255: Change connection url string to use variable names instead of
  absolute values. (mrunalp@gmail.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Bug 901445 - Minor output tweak. (rmillner@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- None of the other db gears have this hook. (rmillner@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
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
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- Various bugfixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Merge pull request #1188 from ironcladlou/bz/902184
  (dmcphers+openshiftbot@redhat.com)
- Set grants correctly upon MySQL restore (ironcladlou@gmail.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- BZ 901502: Needed to account for username change in dump/restore.
  (rmillner@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Merge pull request #1163 from ironcladlou/endpoint-refactor
  (dmcphers@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- BZ 837489: Scramble the username due to mysql security bug.
  (rmillner@redhat.com)

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

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- BZ 877534: Remove DB_SOCKET from db connectors. (mpatel@redhat.com)
- BZ876800: Fix connection URLs for mongo,mysql, and postgres for scalable apps
  (pmorie@gmail.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Fix for Bug 874445 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix for Bug 873810 (jhonce@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Cleanup deprecated env vars during db deconfigure. (mpatel@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.33.9-1
- Merge pull request #777 from rmillner/master (openshift+bot@redhat.com)
- Fix to cleanup old env vars after migration on removing db from scalable app.
  (mpatel@redhat.com)
- BZ 849543: Add informative message about the cartridge credentials.
  (rmillner@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.33.8-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.33.7-1
- Fix mysql-5.1 snapshot for scalable apps (ironcladlou@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.33.6-1
- Don't use rhcsh to control remote dbs. Also fix a typo in the postgres
  cartridge -- variable name. (ramr@redhat.com)
- Cartridge Fix for BZ807443 (jhonce@redhat.com)
- Fix functions to get installed dbs. (mpatel@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.33.5-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.33.4-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.33.3-1
- Typeless gear changes (mpatel@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.33.2-1
- fix for bug#857345 (rchopra@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.33.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Tue Sep 11 2012 Troy Dawson <tdawson@redhat.com> 0.32.3-1
- BZ 852395: Exit from deconfigure when db type doesn't match.
  (mpatel@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.32.2-1
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.32.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.31.8-1
- Merge pull request #418 from mrunalp/bugs/db_ctl_script_missing_var
  (openshift+bot@redhat.com)
- Set db ctl script var that was no longer getting set due to refactoring.
  (mpatel@redhat.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.31.7-1
- fix for Bug 849035 - env vars should be removed for app when db cartridge is
  removed (rchopra@redhat.com)

* Mon Aug 20 2012 Adam Miller <admiller@redhat.com> 0.31.6-1
- Bug 848866 not waiting long enough for mysql to be ready (jhonce@redhat.com)
- Add missing variables to mysql stop (rmillner@redhat.com)

* Fri Aug 17 2012 Adam Miller <admiller@redhat.com> 0.31.5-1
- BZ841750: Only mention rockmongo and phpmyadmin for non-scalable installs.
  (rmillner@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.31.4-1
- Merge pull request #387 from rmillner/US2102 (openshift+bot@redhat.com)
- Merge pull request #384 from mrunalp/bugs/848287 (openshift+bot@redhat.com)
- US2102: Allow PostgreSQL to be embedded in a scalable application.
  (rmillner@redhat.com)
- BZ 848287: Pre move not called when move is within district.
  (mpatel@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.31.3-1
- US2696: Support for mysql/mongo cartridge level move. (mpatel@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.31.2-1
- Fix for bugz 845162 - MySQL cartridge status hook doesn't correctly show true
  status if pid file contains an invalid pid. (ramr@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.31.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- Mysql and mongodb set gear state when on a scalable app.
  (rmillner@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.30.5-1
- Stand-alone mysql or mongodb gears disable stale detection.
  (rmillner@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.30.4-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.30.3-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)

* Fri Jul 13 2012 Adam Miller <admiller@redhat.com> 0.30.2-1
- several fixes related to migrations (dmcphers@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.30.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.29.4-1
- - Don't show postgresql-8.4 as valid options to embed cartridge when mysql is
  already installed and viceversa. (rpenta@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.29.3-1
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Thu Jun 21 2012 Adam Miller <admiller@redhat.com> 0.29.2-1
- Merge pull request #155 from rajatchopra/master (rmillner@redhat.com)
- fix for bug#833340: support same district move (rchopra@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.29.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.28.7-1
- httpd config files should get recreated on move/post-move
  (rchopra@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.28.6-1
- Merge pull request #141 from rmillner/dev/rmillner/bug/833012
  (mrunalp@gmail.com)
- Fix for bugz 833029 and applying the same to mongo (rchopra@redhat.com)
- fix for bug#833039. Fix for scalable app's mysql move across districts.
  (rchopra@redhat.com)
- BZ 833012: Pull DB_HOST from mysql gear itself. (rmillner@redhat.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.28.5-1
- Fix for bug 812046 (abhgupta@redhat.com)
- BZ828703: Scalable apps use the host field differently; just update the
  password on every admin entry. (rmillner@redhat.com)

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.28.4-1
- BZ824409 call unobfuscate_app_home on mongo and mysql gear moves
  (jhonce@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.28.3-1
- 

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.28.2-1
- Mismatched quotes (rmillner@redhat.com)
- The single quotes cause CART_INFO_DIR to be embedded rather than its
  expansion. (rmillner@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.28.1-1
- bumping spec versions (admiller@redhat.com)
- BZ827585 (jhonce@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.27.8-1
- Fix for bugz 825077 - mysql added to a scalable app is not accessible via
  environment variables - OPENSHIFT_DB_HOST variable was incorrectly set.
  (ramr@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.27.7-1
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.27.6-1
- deconfigure script was deleting the directory it was using as a flag before
  testing it (jhonce@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.27.5-1
- resolve symlink before testing for inode (jhonce@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.27.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-mysql-5.1] release [0.27.2-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Refactored mysql cartridge to use lib/util functions (jhonce@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Bug fixes to get tests running - mysql and python fixes, delete user dirs
  otherwise rhc-accept-node fails and tests fail. (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-mysql-5.1] release [0.26.5-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.27.3-1
- Changes to make mongodb run in standalone gear. (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.27.2-1
- Add sample user pre/post hooks. (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.27.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.26.5-1
- Bug 819739 (dmcphers@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.26.4-1
- Additional scripts not sourcing util. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.26.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)
- changed git config within spec files to operate on local repo instead of
  changing global values (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.26.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.26.1-1
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.25.7-1
- Origin-server missing node_ssl_template.conf - add it in - fix for bugz 815276.
  (ramr@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.25.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.25.5-1
- new package built with tito
