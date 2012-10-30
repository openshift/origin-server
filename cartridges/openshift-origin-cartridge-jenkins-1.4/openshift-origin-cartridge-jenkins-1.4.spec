%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins-1.4

Summary:   Provides jenkins-1.4 support
Name:      openshift-origin-cartridge-jenkins-1.4
Version: 1.0.1
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

BuildRequires: git
Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires: java >= 1.6
Requires: jenkins
Requires: jenkins-plugin-openshift
Obsoletes: cartridge-jenkins-1.4

%description
Provides jenkins cartridge to openshift nodes


%prep
%setup -q


%build


%post
service jenkins stop
chkconfig jenkins off


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
cp -r template %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
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

