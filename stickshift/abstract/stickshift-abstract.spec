%define cartdir %{_libexecdir}/stickshift/cartridges

Summary:   StickShift common cartridge components
Name:      stickshift-abstract
Version: 0.13.4
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   stickshift-abstract-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch: noarch
Requires: git
Requires: mod_ssl

%description
This contains the common function used while building cartridges.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartdir}
cp -rv abstract %{buildroot}%{cartdir}/
cp -rv abstract-httpd %{buildroot}%{cartdir}/
cp -rv abstract-jboss %{buildroot}%{cartdir}/
cp -rv LICENSE %{buildroot}%{cartdir}/abstract
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract
cp -rv LICENSE %{buildroot}%{cartdir}/abstract-httpd
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract-httpd
cp -rv LICENSE %{buildroot}%{cartdir}/abstract-jboss
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract-jboss

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract-httpd/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/bin/
#%{_libexecdir}/stickshift/cartridges/abstract-httpd/info
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract-jboss/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-jboss/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract-jboss/info/bin/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-jboss/info/connection-hooks/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-jboss/info/data/
#%{_libexecdir}/stickshift/cartridges/abstract-jboss/info
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/bin/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/lib/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/connection-hooks/
%{_libexecdir}/stickshift/cartridges/abstract/info
%doc %{_libexecdir}/stickshift/cartridges/abstract/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract/LICENSE
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/LICENSE
%doc %{_libexecdir}/stickshift/cartridges/abstract-jboss/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract-jboss/LICENSE


%post

%changelog
* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Refactor hot deploy support in Jenkins templates (ironcladlou@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)

* Thu Jul 05 2012 William DeCoste <wdecoste@redhat.com> 0.13.3-1
- Abstract JBoss cartridge
  
* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- merged Replace all env vars in standalone.xml (bdecoste@gmail.com)
- Merge pull request #124 from
  matejonnet/dev/mlazar/update/jboss_add_custom_module_dir (bdecoste@gmail.com)
- Replace all env vars in standalone.xml. (matejonnet@gmail.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- Merge pull request #130 from abhgupta/agupta-dev
  (mmcgrath+openshift@redhat.com)
- Prevent passing binary on stdin to pre-receive hook (dmace@redhat.com)
- Fix for bug 812046 (abhgupta@redhat.com)
- Add hot deployment support via hot_deploy marker (dmace@redhat.com)
- BZ829452: Stop and print an informative message if the remote repository
  cannot be reached. (rmillner@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- Add port wrap around to manage UID descrepency between dev and the district
  code in stg/prod. (rmillner@redhat.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
-  Fix update-namespace.sh called twice due to typeless gear dir name changes.
  Just do it once -- don't need gear type anymore. (ramr@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bumping spec versions (admiller@redhat.com)

* Thu May 31 2012 Adam Miller <admiller@redhat.com> 0.11.7-1
- Bugzilla 826819: redeploy_repo_dir assumed . was the git repo and that
  assumption had changed.  Bugzilla 827111: Add safety around rm -rf
  (rmillner@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.11.6-1
- Bug 825354 (dmcphers@redhat.com)
- Merge pull request #81 from rajatchopra/master
  (mmcgrath+openshift@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)
- fix for several bugs.. first 3 args should be shifted before connection info
  is processed (rchopra@redhat.com)
- Adding a dependency resolution step (using post-recieve hook) for all
  applications created from templates. Simplifies workflow by not requiring an
  additional git pull/push step Cucumber tests (kraman@gmail.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.5-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.11.4-1
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
- Merge branch 'US2109' of github.com:openshift/crankcase into US2109
  (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Undo proxy code re-introduced via merge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Old backups will have data directory in the wrong place.  Allow either to
  exist in the tar file and transform the location on extraction without tar
  spitting out an error from providing non-existent path on the command line.
  (rmillner@redhat.com)
- Data directory moved to ~/app (rmillner@redhat.com)
- Merge branch 'US2109' of github.com:openshift/crankcase into US2109
  (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- clean up comments etc (jhonce@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Bug fixes to get tests running - mysql and python fixes, delete user dirs
  otherwise rhc-accept-node fails and tests fail. (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [stickshift-abstract] release [0.10.5-1].
  (admiller@redhat.com)
- Fixing bugs related to user hooks. (rmillner@redhat.com)
- Bug fix - correct app/ directory permissions. (ramr@redhat.com)
- Fixes for jenkins cartridge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- set uid:gid for user owned git repo (jhonce@redhat.com)
- Bug fixes to get app creation working. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)
- Refactor unix_user model to create gear TA1975 (jhonce@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Merge pull request #41 from mrunalp/master (smitram@gmail.com)
- missing status=I from several carts (dmcphers@redhat.com)
- Changes to make mongodb run in standalone gear. (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- silence the overlaping alias issues (mmcgrath@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- Fixing bugs related to user hooks. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.4-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- code cleanup at the bash level (mmcgrath@redhat.com)
- general style cleanup (mmcgrath@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- 

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.5-1
- new package built with tito
