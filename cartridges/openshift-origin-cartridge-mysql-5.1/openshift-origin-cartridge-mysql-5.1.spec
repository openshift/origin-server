%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/mysql-5.1
%global frameworkdir %{_libexecdir}/openshift/cartridges/mysql-5.1

Name: openshift-origin-cartridge-mysql-5.1
Version: 0.33.7
Release: 1%{?dist}
Summary: Provides embedded mysql support

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
Requires: openshift-origin-cartridge-abstract
Requires: mysql-server
Requires: mysql-devel
Obsoletes: cartridge-mysql-5.1

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
