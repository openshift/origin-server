%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins-1.4

Summary:       Provides jenkins-1.4 support
Name:          openshift-origin-cartridge-jenkins-1.4
Version: 1.9.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.6
Requires:      jenkins
Requires:      jenkins-plugin-openshift
BuildRequires: git
BuildArch:     noarch

%description
Provides jenkins cartridge to openshift nodes


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

%post
service jenkins stop
chkconfig jenkins off


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
cp -r template %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages


%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0750,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%{cartridgedir}/template/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- fixing tests (dmcphers@redhat.com)
- adding install and post install for jenkins (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- delete all calls to remove_ssh_key, and remove_domain_env_vars
  (rchopra@redhat.com)
- Merge pull request #1943 from bdecoste/master (dmcphers@redhat.com)
- Bug 947092 (bdecoste@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- wait for Jenkins to come up fully (bdecoste@gmail.com)
- Bug 947092 (bdecoste@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- cleanup (dmcphers@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Merge pull request #1473 from danmcp/master (dmcphers@redhat.com)
- Use update rather than find_and_modify (dmcphers@redhat.com)
- Bug 916026 - Removing hardcoded library version references from jenkins
  password encoder classpath (bleanhar@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Fixing jenkins commons-codec dependency version (upstream jenkins-1.501)
  (kraman@gmail.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Add remote debugging support to Jenkins (ironcladlou@gmail.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Bug 906454: Update Jenkins job configs during domain update
  (ironcladlou@gmail.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- fix for bug 895730 and 895733 (abhgupta@redhat.com)
- cleanup (dmcphers@redhat.com)
- Manifest file fixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.6-1
- Fix typos in rhc instructions displayed to client (ironcladlou@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.5-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Mon Jan 14 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Merge pull request #1145 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- disable jenkins DNS multicast (bdecoste@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Add missing routes.json configuration for jenkins apps. (ramr@redhat.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- use /etc/alternatives/jre for jenkins (bdecoste@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- Merge pull request #983 from jwhonce/dev/rm_post-install
  (openshift+bot@redhat.com)
- Merge pull request #982 from bdecoste/master (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- BZ880429 (bdecoste@gmail.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- Merge pull request #976 from jwhonce/dev/rm_post-remove
  (openshift+bot@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Cleanup visuals of app creation, indicate default git branch, add a date
  helper for visuals, and ensure jenkins has the instant_app tag.
  (ccoleman@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.98.9-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.98.8-1
- fix typos (dmcphers@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.98.7-1
- Honor stop_lock during app_ctl stop calls (ironcladlou@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.98.6-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.98.5-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.98.4-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 26 2012 Adam Miller <admiller@redhat.com> 0.98.3-1
- Disable Jenkins built-in SSH server by default (ironcladlou@gmail.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.98.2-1
- Rewrite outgoing http URLs as HTTPS for jenkins httpd (pmorie@gmail.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.98.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.97.3-1
- Merge pull request #450 from smarterclayton/switch_to_newer_broker_tags
  (openshift+bot@redhat.com)
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)
- Use the agreed on newer broker tags for jenkins and jenkins-client
  (ccoleman@redhat.com)

* Thu Sep 06 2012 Adam Miller <admiller@redhat.com> 0.97.2-1
- Adding >= 1.6 to the java require to avoid pulling in gcj
  (bleanhar@redhat.com)
- Adding a link to the Jira issue for the Jenkins spec (bleanhar@redhat.com)
- Adding a java require to the jenkins cartridge spec (bleanhar@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.97.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.96.3-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.96.2-1
- bz 831062 (bdecoste@gmail.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.96.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Mon Jul 09 2012 Adam Miller <admiller@redhat.com> 0.95.3-1
- Disable automatic Jenkins update checking (ironcladlou@gmail.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.95.2-1
- more cartridges have better metadata (rchopra@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.95.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.94.4-1
- bug 801655 (bdecoste@gmail.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.94.3-1
- Fix for bug 812046 (abhgupta@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.94.2-1
- fix jenkins httpd proxy (bdecoste@gmail.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.94.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.93.5-1
- Bug 825354 (dmcphers@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.93.4-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.93.3-1
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Hand merged preconfigure being pulled into configure (jhonce@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-jenkins-1.4] release [0.93.2-1].
  (admiller@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Bug fixes to get tests running - mysql and python fixes, delete user dirs
  otherwise rhc-accept-node fails and tests fail. (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-jenkins-1.4] release [0.92.4-1].
  (admiller@redhat.com)
- Removing redundant application destruction message from jenkins cartridge
  (kraman@gmail.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.93.2-1
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Add sample user pre/post hooks. (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.93.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.92.4-1
- Merge pull request #27 from kraman/dev/kraman/bug/806935
  (dmcphers@redhat.com)
- Removing redundant application destruction message from jenkins cartridge
  (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.92.1-1
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Dan McPherson <dmcphers@redhat.com> 0.91.7-1
- fix for bug 813229 - jenkins reload now happens in the plugin - so reload
  step in app_ctl.sh is a no-op now (abhgupta@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.91.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.91.5-1
- new package built with tito

