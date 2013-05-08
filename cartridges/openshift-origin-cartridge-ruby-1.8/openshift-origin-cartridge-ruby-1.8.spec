%global cartridgedir %{_libexecdir}/openshift/cartridges/ruby-1.8

Summary:       Provides ruby rack support running on Phusion Passenger
Name:          openshift-origin-cartridge-ruby-1.8
Version: 1.9.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mod_bw
Requires:      sqlite-devel
Requires:      rubygems
Requires:      rubygem-rack >= 1.1.0
#Requires:      rubygem-rack < 1.2.0
Requires:      rubygem-passenger
Requires:      rubygem-passenger-native
Requires:      rubygem-passenger-native-libs
Requires:      mod_passenger
Requires:      rubygem-bundler
Requires:      rubygem-mongo
Requires:      rubygem-sqlite3
Requires:      rubygem-thread-dump
Requires:      ruby-sqlite3
Requires:      ruby-mysql
Requires:      rubygem-bson_ext
Requires:      mysql-devel
Requires:      ruby-devel
Requires:      libxml2
Requires:      libxml2-devel
Requires:      libxslt
Requires:      libxslt-devel
Requires:      gcc-c++
Requires:      js
# Deps for users
Requires:      ruby-RMagick
%if 0%{?rhel}
Requires:      ruby-nokogiri
%endif
%if 0%{?fedora}
Requires:      rubygem-nokogiri
%endif
BuildRequires: git
BuildArch:     noarch

%description
Provides ruby support to OpenShift

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
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract-httpd/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
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

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Merge pull request #2342 from BanzaiMan/dev/hasari/c288_followup
  (dmcphers+openshiftbot@redhat.com)
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Bugs 958709, 958744, 958757 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.5-1
- Change corresponding to adb5092a for Ruby 1.8 cartridge
  (asari.ruby@gmail.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Card 534 (lnader@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- <threaddump> fix bug 923405 so ruby thread dump reports useful log file
  (lmeyer@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 913217 (bdecoste@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Bug 906671: Fix log location in Ruby tidy hook (ironcladlou@gmail.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fixed scaled app creation Fixed scaled app cartridge addition Updated
  descriptors to set correct group overrides for web_cartridges
  (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1112 from mrunalp/bugs/891431
  (dmcphers+openshiftbot@redhat.com)
- Fix BZ864797: Add doc for disable_auto_scaling marker (pmorie@gmail.com)
- Fix for BZ 891431. (mpatel@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- BZ855264 - Can't 'rhc app tail' ruby app error_log file when the server's
  timezone is not EST. (calfonso@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Fix for Bug 862919 (jhonce@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- Merge pull request #976 from jwhonce/dev/rm_post-remove
  (openshift+bot@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.3-1
- Merge pull request #803 from ramr/master (openshift+bot@redhat.com)
- Fix README to use new variable scheme + fixup wrong variable in diy cart.
  (ramr@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fix bundle caching during Jenkins builds (ironcladlou@gmail.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.99.7-1
- BZ 843286: Enable auth files via htaccess (rmillner@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.99.6-1
- BZ863937  Need update rhc app tail to rhc tail for output of rhc threaddump
  command (calfonso@redhat.com)
- Both prod and stg mirrors point to the ops mirror -- so use
  mirror1.ops.rhcloud.com - also makes for consistent behaviour across
  DEV/STG/INT/PROD. (ramr@redhat.com)
- Fix for Bug 862876 (jhonce@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.99.5-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.99.4-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.99.3-1
- Typeless gear changes (mpatel@redhat.com)

* Thu Sep 27 2012 Adam Miller <admiller@redhat.com> 0.99.2-1
- Detect threaddump on a scalable application and print error.
  (rmillner@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.99.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.98.2-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.98.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.97.3-1
- Fix for bugz 847605 - add hot_deploy instructions to README for ruby-1.8 and
  ruby-1.9 (ramr@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.97.2-1
- Enable hot deployment support for Ruby cartridges (ironcladlou@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.97.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Wed Aug 01 2012 Adam Miller <admiller@redhat.com> 0.96.5-1
- Some frameworks (ex: mod_wsgi) need HTTPS set to notify the app that https
  was used. (rmillner@redhat.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.96.4-1
- The [ operator requires a space afterward in bash, = is used for string
  compare and if PID could be blank it must be quoted so that the blank is
  compared as a string. (rmillner@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.96.3-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.96.2-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)
- Fixes for bugz 840030 - Apache blocks access to /icons. Remove these as
  mod_autoindex has now been turned OFF (see bugz 785050 for more details).
  (ramr@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.96.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.95.6-1
- 

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.95.5-1
- Fix for bugz 837468 - use UTC time + ruby19 cleanup: write to stderr.
  (ramr@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.95.4-1
- more cartridges have better metadata (rchopra@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.95.3-1
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.95.2-1
- Fix for bugz 835876 - use current euid. (ramr@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.95.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.94.3-1
- BZ830115 fix for ruby thread dumps (jhonce@redhat.com)

* Fri Jun 15 2012 Adam Miller <admiller@redhat.com> 0.94.2-1
- Security - BZ785050 remove mod_autoindex from all httpd.confs
  (tkramer@redhat.com)

* Fri Jun 15 2012 Tim Kramer <tkramer@redhat.com>
- Security BZ785050 Removed mod_autoindex from both httpd.conf files (tkramer@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.94.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.93.7-1
- Bug 825354 (dmcphers@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)
- Adding a dependency resolution step (using post-recieve hook) for all
  applications created from templates. Simplifies workflow by not requiring an
  additional git pull/push step Cucumber tests (kraman@gmail.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.93.6-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.93.5-1
- .state file in new location (jhonce@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.93.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-ruby-1.8] release [0.93.2-1].
  (admiller@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Fixing ruby spec for fedora installs. ruby-nokogiri -> rubygem-nokogiri
  (kraman@neptune.localdomain)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-ruby-1.8] release [0.92.6-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.93.3-1
- Merge pull request #41 from mrunalp/master (smitram@gmail.com)
- Handle passenger not stopping more forcefully (dmcphers@redhat.com)
- Changes to descriptors/specs to execute the new connector.
  (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.93.2-1
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Fixing ruby spec for fedora installs. ruby-nokogiri -> rubygem-nokogiri
  (kraman@neptune.localdomain)
- Add sample user pre/post hooks. (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.93.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.92.6-1
- Bug 819739 (dmcphers@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.5-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Some of the ctl script were not sourcing util from abstract.
  (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.4-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)
- changed git config within spec files to operate on local repo instead of
  changing global values (kraman@gmail.com)

* Thu May 03 2012 Dan McPherson <dmcphers@redhat.com> 0.92.3-1
- Adding obsoletes for machines that may have cartridge with old name already
  installed. (kraman@gmail.com)

* Wed May 02 2012 Krishna Raman <kraman@gmail.com> 0.92.2-1
- new package built with tito

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.92.1-1
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.91.7-1
- Inversed logic since we don't use Fedora name in the open source image.
  (mpatel@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.91.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.91.5-1
- new package built with tito
