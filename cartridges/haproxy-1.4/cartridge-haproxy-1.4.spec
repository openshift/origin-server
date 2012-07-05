%global cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/haproxy-1.4
%global frameworkdir %{_libexecdir}/stickshift/cartridges/haproxy-1.4

Summary:   Provides embedded haproxy-1.4 support
Name:      cartridge-haproxy-1.4
Version: 0.12.5
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz


BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git

Requires:  stickshift-abstract
Requires:  haproxy
Requires:  rubygem-daemons
Requires:  rubygem-rest-client


%description
Provides haproxy balancer support to OpenShift


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
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/../../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../../abstract-httpd/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- more cartridges have better metadata (rchopra@redhat.com)
- Merge pull request #161 from VojtechVitek/php.ini-max_file_uploads
  (mmcgrath+openshift@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)
- Add max_file_uploads INI setting to php.ini files (vvitek@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- BugFix: 834151 (rpenta@redhat.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- 

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- BZ 835205: Fail gracefully when the gear is in a half-built state instead of
  trying to do the wrong thing. (rmillner@redhat.com)
- BZ 835157: Add exception handling to add/remove-gear and print informative
  messages. (rmillner@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.11.7-1
- Fix for BZ 831097 (mpatel@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.11.6-1
- fix for bug#833039. Fix for scalable app's mysql move across districts.
  (rchopra@redhat.com)

* Fri Jun 15 2012 Adam Miller <admiller@redhat.com> 0.11.5-1
- Security - # BZ785050 Removed the mod_autoindex from the httpd.conf files
  (tkramer@redhat.com)

* Fri Jun 15 2012 Tim Kramer <tkramer@redhat.com>
- # BZ785050 Removed mod_autoindex from two httpd.conf files

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.11.4-1
- support for group overrides so that we do not rely on filesystem co-location
  - fix for bug#824124 (rchopra@redhat.com)

* Mon Jun 11 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Moving stats socket file to run directory instead of tmp. On OpenShift
  Origin, multiple apps using haproxy caused errors because they compete over
  the /tmp/stats socket file. (kraman@gmail.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- fixing gearup bug (mmcgrath@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.10.8-1
- Bug 825354 (dmcphers@redhat.com)
- Fix for bz 816171 (mpatel@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.10.7-1
- Fix for bugz 824423 - fail to git push after haproxy gear move. Abstract
  expects cartridge_type as a result of typeless gears - set that.
  (ramr@redhat.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.10.6-1
- Merge pull request #60 from ramr/master (mmcgrath+openshift@redhat.com)
- Bug fix so that after a haproxy gear move the permissions are setup
  correctly. (ramr@redhat.com)
- Merge pull request #46 from rajatchopra/master (kraman@gmail.com)
- check for -1 on max value (rchopra@redhat.com)
- logic to check on scaling limits copied to haproxy_ctld (rchopra@redhat.com)
- change scaling policies in manifest.yml so that jboss really takes 2 as
  minimum (rchopra@redhat.com)
- code for min_gear setting (rchopra@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.10.4-1
- Fix for bugz 82087 -- app gear of a scalable app doesn't waken up from idled
  status. (ramr@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.10.3-1
- Automatic commit of package [cartridge-haproxy-1.4] release [0.10.2-1].
  (admiller@redhat.com)
- Fix for bugz 822476. Make the isrunning check more resilient.
  (ramr@redhat.com)
- Add a haproxy log file, so that there's some additional info.
  (ramr@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Fix for bugz 820051 - Allow scalable gears to be moved. (ramr@redhat.com)
- Bug fix to get scalable apps working. (ramr@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- Fix for bugz 822476. Make the isrunning check more resilient.
  (ramr@redhat.com)
- Add a haproxy log file, so that there's some additional info.
  (ramr@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge pull request #36 from rmillner/master (kraman@gmail.com)
- Add sample user pre/post hooks. (rmillner@redhat.com)
- Fix for bugz 820051 - Allow scalable gears to be moved. (ramr@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.9.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)
- changed git config within spec files to operate on local repo instead of
  changing global values (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.9.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.8.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.8.5-1
- new package built with tito

