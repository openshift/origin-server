%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartdir %{_libexecdir}/openshift/cartridges

Summary:       OpenShift common cartridge components
Name:          openshift-origin-cartridge-abstract
Version: 1.8.3
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      facter
Requires:      git
Requires:      make
Requires:      tar
Requires:      mod_ssl
# abstract/info/connection-hooks/publish-http-url
Requires:      python
# abstract/info/bin/jenkins_build
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(json)
# abstract/info/bin/open_ports.sh
Requires:      socat
# abstract/info/bin/nurture_app_push.sh
Requires:      curl
# abstract/info/bin/sync_gears.sh
Requires:      rsync
# abstract/info/lib/network
Requires:      lsof
BuildArch:     noarch

%description
This contains the common function used while building cartridges.

%package   jboss
Summary:   OpenShift common jboss cartridge components
Requires:  %{name} = %{version}
# abstract-jboss/info/bin/build.sh
Requires:  /usr/bin/mvn

%description jboss
This contains the common function used while building 
openshift jboss cartridges.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{cartdir}
cp -rv -p abstract %{buildroot}%{cartdir}/
cp -rv -p abstract-httpd %{buildroot}%{cartdir}/
cp -rv -p abstract-jboss %{buildroot}%{cartdir}/

%files
%doc COPYRIGHT LICENSE
%dir %{_libexecdir}/openshift/
%dir %{_libexecdir}/openshift/cartridges/
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract-httpd/
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract-httpd/info/
%attr(0750,-,-) %{_libexecdir}/openshift/cartridges/abstract-httpd/info/hooks/
%attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract-httpd/info/bin/
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract/
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract/info/
%dir %attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/hooks
%attr(0750,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/hooks/*
# tidy is now a cartridge hook and should be accessible to gear users
%attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/hooks/tidy
%attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/bin/
%attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/lib/
%attr(0750,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/connection-hooks/
%dir %attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/configuration/
%attr(0644,-,-) %{_libexecdir}/openshift/cartridges/abstract/info/configuration/health.html

%files jboss
%doc COPYRIGHT LICENSE
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract-jboss/
%dir %attr(0755,root,root) %{_libexecdir}/openshift/cartridges/abstract-jboss/info/
%attr(0750,-,-) %{_libexecdir}/openshift/cartridges/abstract-jboss/info/hooks/
%attr(0755,-,-) %{_libexecdir}/openshift/cartridges/abstract-jboss/info/bin/
%attr(0750,-,-) %{_libexecdir}/openshift/cartridges/abstract-jboss/info/connection-hooks/
%doc %{_libexecdir}/openshift/cartridges/abstract-jboss/README.md

%changelog
* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Bugs 958709, 958744, 958757 (dmcphers@redhat.com)
- Using post-configure to deploy quickstarts for v1 (dmcphers@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Card 276 (asari.ruby@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Bug 955492: Fix rsync command to correct hot deployment
  (ironcladlou@gmail.com)
- Bug 835778 (dmcphers@redhat.com)
- Bug 954317 - rhcsh test for V1 vs V2 failed (jhonce@redhat.com)
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

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Merge pull request #1908 from bdecoste/master (dmcphers@redhat.com)
- update rsync (bdecoste@gmail.com)
- abstract requires tar but that is no longer in @base (markllama@gmail.com)
- Bug 947016 (bdecoste@gmail.com)
- Merge pull request #1842 from bdecoste/master (dmcphers@redhat.com)
- rsync deployments (bdecoste@gmail.com)
- rsync deployments (bdecoste@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- Merge pull request #1825 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- clean deployments (bdecoste@gmail.com)
- Bug 928142 (bdecoste@gmail.com)
- Merge pull request #1822 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 928142 (bdecoste@gmail.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1800 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 927192 (bdecoste@gmail.com)
- Merge pull request #1786 from rmillner/BZ927346
  (dmcphers+openshiftbot@redhat.com)
- Bug 927346 - Run cartridge actions with CWD as the gear home directory.
  (rmillner@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Bug 923369 (bdecoste@gmail.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Bug 920375 (bdecoste@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Bug 922650: Fix default ROOT.war for JBoss carts (ironcladlou@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- minor cleanup of some cartridge spec files (tdawson@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Merge pull request #1557 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Enable management console (bdecoste@gmail.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- JBoss cartridge documentation for OSE 1.1 (calfonso@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- BZ916791: Fix invalid args passed to ps. (mrunalp@gmail.com)
- Merge pull request #1503 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Was using the wrong call. (rmillner@redhat.com)
- Bug 916829 - add health url. (rmillner@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Merge pull request #1474 from bdecoste/master (dmcphers@redhat.com)
- Bug 913217 (bdecoste@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Merge pull request #1454 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 895507 (bdecoste@gmail.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.4-2
- bump Release for fixed build target rebuild (admiller@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 913288 - Numeric login effected additional commands (jhonce@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Audit of remaining front-end Apache touch points. (rmillner@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 906740 - Update error message (jhonce@redhat.com)
- Fixes for ruby193 (john@ibiblio.org)
- remove community pod (dmcphers@redhat.com)
- remove use of filesystem cgroup countrol (mlamouri@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Add openshift-origin-cartridge-community-python-3.3 cartridge.
  (smitram@gmail.com)
- Add openshift-origin-cartridge-community-python-2.7 cartridge.
  (smitram@gmail.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Add file:// to the allowed git protocols and add the community-pod to the
  list of 'frameworks'!! (ramr@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.7-1
- Merge pull request #1195 from rmillner/BZ896364
  (dmcphers+openshiftbot@redhat.com)
- Bug 896364 - Minor cleanup. (rmillner@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.6-1
- BZ 896364: Check git urls for allowed types and emit useful error messages.
  (rmillner@redhat.com)
- Fix typos in rhc instructions displayed to client (ironcladlou@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.5-1
- Merge pull request #1163 from ironcladlou/endpoint-refactor
  (dmcphers@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Merge pull request #1158 from rmillner/BZ837489
  (dmcphers+openshiftbot@redhat.com)
- BZ 837489: Scramble the username due to mysql security bug.
  (rmillner@redhat.com)
- Fix for Bug 895878 (jhonce@redhat.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Merge pull request #1128 from ramr/master (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1110 from Miciah/silence-pushd-and-popd
  (dmcphers+openshiftbot@redhat.com)
- Add missing routes.json configuration for jboss* app types + minor cleanup.
  (ramr@redhat.com)
- Fix BZ891831 (pmorie@gmail.com)
- Consistently silence pushd and popd in hooks (miciah.masters@gmail.com)
- Update node web proxy config when updating namespace. (mpatel@redhat.com)
- Merge pull request #1083 from bdecoste/master (openshift+bot@redhat.com)
- re-enabed ews2 (bdecoste@gmail.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.8-1
- Merge pull request #1029 from bdecoste/master (openshift+bot@redhat.com)
- removed ews2.0 and sy xslt (bdecoste@gmail.com)
- ews2 and bugs (bdecoste@gmail.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.7-1
- Merge pull request #1035 from abhgupta/abhgupta-dev
  (openshift+bot@redhat.com)
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Fix for Bug 880013 (jhonce@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1023 from ramr/dev/websockets (openshift+bot@redhat.com)
- Node web sockets and http(s) proxy support with spec file and package.
  (ramr@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Fix state transitions during build cycle (ironcladlou@gmail.com)
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- Merge pull request #984 from jwhonce/dev/rm_phpmoadmin
  (openshift+bot@redhat.com)
- Merge pull request #983 from jwhonce/dev/rm_post-install
  (openshift+bot@redhat.com)
- Remove unused phpmoadmin cartridge (jhonce@redhat.com)
- Merge pull request #982 from bdecoste/master (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- BZ880429 (bdecoste@gmail.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Merge pull request #973 from bdecoste/master (openshift+bot@redhat.com)
- use /bin/env (dmcphers@redhat.com)
- Changing same uid move to rsync (dmcphers@redhat.com)
- ews2 (bdecoste@gmail.com)
- add oo-ruby (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Merge pull request #926 from jwhonce/dev/bz877172 (dmcphers@redhat.com)
- Merge pull request #924 from rmillner/BZ876640 (dmcphers@redhat.com)
- Merge pull request #925 from ironcladlou/scl-refactor (dmcphers@redhat.com)
- Fix for Bug 877172 (jhonce@redhat.com)
- BZ 876640: Warn if no git repo. (rmillner@redhat.com)
- Only use scl if it's available (ironcladlou@gmail.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- BZ 876640:Test if the target exists and report error. (rmillner@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Use standard PATH util in jboss carts (ironcladlou@gmail.com)
- WIP Ruby 1.9 runtime fixes (ironcladlou@gmail.com)
- Finish moving the stale disable to Origin. (rmillner@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Fix for Bug 874445 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Increase the table sizes to cover 15000 nodes in dev and prod.
  (rmillner@redhat.com)
- Cleanup spec for Fedora standards (tdawson@redhat.com)
- Unnecessary to run as system_u and causes test failures.
  (rmillner@redhat.com)
- BZ 872008: Use complete context def. (rmillner@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.3-1
- Port enable/disable_stale_detection (jhonce@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fix bundle caching during Jenkins builds (ironcladlou@gmail.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.17.20-1
- BZ 867322: Test if a cart was the only cart on a gear was failing.
  (rmillner@redhat.com)

* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.17.19-1
- Decouple hook subprocess streams from the parent process
  (ironcladlou@gmail.com)
- Fix submodule extraction by expanding ~ properly (ironcladlou@gmail.com)
- Make stop function work when called prior to any app start
  (ironcladlou@gmail.com)

* Mon Oct 22 2012 Adam Miller <admiller@redhat.com> 0.17.18-1
- Merge pull request #724 from Miciah/cartridge-abstract-require-make
  (openshift+bot@redhat.com)
- Make cartridge-abstract depend on make (miciah.masters@gmail.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.17.17-1
- Merge pull request #717 from pravisankar/dev/ravi/bug/866411
  (dmcphers@redhat.com)
- Fix for Bug# 866411 (rpenta@redhat.com)
- Fix clustering env var references (ironcladlou@gmail.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.17.16-1
- Fixing outstanding cgroups issues Removing hardcoded references to "OpenShift
  guest" and using GEAR_GECOS from node.conf instead (kraman@gmail.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Fix mysql-5.1 snapshot for scalable apps (ironcladlou@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.17.15-1
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.17.14-1
- BZ863937  Need update rhc app tail to rhc tail for output of rhc threaddump
  command (calfonso@redhat.com)
- BZ866327 (bdecoste@gmail.com)
- Merge pull request #661 from ramr/master (openshift+bot@redhat.com)
- Merge pull request #644 from bdecoste/master (openshift+bot@redhat.com)
- Don't use rhcsh to control remote dbs. Also fix a typo in the postgres
  cartridge -- variable name. (ramr@redhat.com)
- BZ 864519: Fix for git push failing for scalable apps w/ dbs.
  (mpatel@redhat.com)
- added tests and enabled ews (bdecoste@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- Merge pull request #623 from mrunalp/bugs/863998 (openshift+bot@redhat.com)
- Merge pull request #617 from mrunalp/bugs/util_db_functions_fix
  (openshift+bot@redhat.com)
- BZ 863998: Fix path to git repo. (mpatel@redhat.com)
- Fix functions to get installed dbs. (mpatel@redhat.com)
- Honor stop_lock during app_ctl stop calls (ironcladlou@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.17.13-1
- suppressing tmp cleanup errors in tidy script (abhgupta@redhat.com)
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.17.12-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.17.9-1
- Bug 860240 (dmcphers@redhat.com)
- Merge pull request #595 from mrunalp/dev/typeless (dmcphers@redhat.com)
- Typeless gear changes (mpatel@redhat.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.17.8-1
- Fix for bugz 859990 - Unidling on ssh. (ramr@redhat.com)

* Fri Sep 28 2012 Adam Miller <admiller@redhat.com> 0.17.7-1
- Fix for bugz 859565 - .dev.rhcloud.com matches foo-bardev.rhcloud.com
  (ramr@redhat.com)

* Thu Sep 27 2012 Adam Miller <admiller@redhat.com> 0.17.6-1
- Detect threaddump on a scalable application and print error.
  (rmillner@redhat.com)

* Wed Sep 26 2012 Adam Miller <admiller@redhat.com> 0.17.5-1
- Merge pull request #528 from bdecoste/master (openshift+bot@redhat.com)
- BZ857143 (bdecoste@gmail.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.17.4-1
- Merge pull request #498 from mscherer/add_recursive_submodule
  (dmcphers@redhat.com)
- add recursive submodule handling and simply initialization
  (mscherer@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.17.3-1
- BZ857205 part2 (bdecoste@gmail.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.17.2-1
- BZ858605 (bdecoste@gmail.com)
- BZ857205 (bdecoste@gmail.com)
- Merge pull request #502 from rajatchopra/master (openshift+bot@redhat.com)
- fixed started state for extended tests for hot_deploy (bdecoste@gmail.com)
- fix for bug#858092 (rchopra@redhat.com)
- US2747 (bdecoste@gmail.com)
- Merge pull request #479 from rmillner/f17proxy (openshift+bot@redhat.com)
- The chkconfig test no longer works on F17 and was no longer needed once port-
  proxy moved to origin-server (rmillner@redhat.com)
- US2747 (bdecoste@gmail.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.17.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.16.4-1
- Fix for Bug 852268 (jhonce@redhat.com)

* Thu Sep 06 2012 Adam Miller <admiller@redhat.com> 0.16.3-1
- Fix for bugz 853372 - Failed to move primary cartridge app due to httpd.pid
  file being empty. (ramr@redhat.com)
- Fix for bugz 852518 - Failed move due to httpd.pid file being empty.
  (ramr@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- Patch for BZ850962 (jhonce@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.15.7-1
- support for removing app local environment variables (rchopra@redhat.com)

* Fri Aug 17 2012 Adam Miller <admiller@redhat.com> 0.15.6-1
- Merge pull request #397 from rmillner/apachectl (openshift+bot@redhat.com)
- Fedora 17 does away with the init script method of calling configtest and
  graceful. (rmillner@redhat.com)
- Wrong path to stats socket. (rmillner@redhat.com)
- BZ844876: Needed to be more specific with the filter. (rmillner@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.15.5-1
- US2102: Allow PostgreSQL to be embedded in a scalable application.
  (rmillner@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.15.4-1
- Merge pull request #374 from rajatchopra/US2568 (openshift+bot@redhat.com)
- Merge pull request #375 from mrunalp/dev/US2696 (openshift+bot@redhat.com)
- US2696: Support for mysql/mongo cartridge level move. (mpatel@redhat.com)
- support for app-local ssh key distribution (rchopra@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.15.3-1
- Merge pull request #356 from rmillner/BZ847150 (openshift+bot@redhat.com)
- Remove Mike's email address and replace it with bofh (admiller@redhat.com)
- Queue multiple requests behind one httpd graceful or restart call for C9.
  (rmillner@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- Create sandbox directory. (rmillner@redhat.com)
- BZ 845332: Separate out configuration file management from the init script so
  that systemd properly interprets the daemon restart. (rmillner@redhat.com)
- Merge pull request #325 from kraman/dev/kraman/features/origin
  (rmillner@redhat.com)
- Reducing the amount of entropy needed to generate a password. The extra
  entropy was being discarded anyway. (kraman@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- BZ 844876: ignore the haproxy status socket (rmillner@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.14.9-1
- Merge pull request #302 from rmillner/dev/rmillner/bug/844123
  (rchopra@redhat.com)
- BZ844267 plus abstracted app_ctl_impl.sh (bdecoste@gmail.com)
- Move direct calls to httpd init script to httpd_singular locking script
  (rmillner@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.14.8-1
- abstracted app_ctl_impl.sh (bdecoste@gmail.com)
- BZ844267 plus abstracted app_ctl_impl.sh (bdecoste@gmail.com)

* Tue Jul 31 2012 William DeCoste <wdecoste@redhat.com> 0.14.7-1
- abstracted app_ctl_impl.sh for JBoss

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.14.6-1
- BZ 843354: Don't generate passwords that start with "-".
  (rmillner@redhat.com)
- Stand-alone mysql or mongodb gears disable stale detection.
  (rmillner@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.14.5-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- Refactor JBoss hot deployment support (ironcladlou@gmail.com)
- enable java7 (bdecoste@gmail.com)
- BZ 838365: Setting app state was failing because the user in question could
  not run processes.  Force-kill must kill all processes even if it cannot set
  app state for some reason. (rmillner@redhat.com)
- bz 831062 (bdecoste@gmail.com)

* Fri Jul 13 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Merge pull request #231 from rmillner/dev/rmillner/bug/839924
  (mrunalp@gmail.com)
- BZ 839924: Was deleting the wrong data directory. (rmillner@redhat.com)

* Fri Jul 13 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- several fixes related to migrations (dmcphers@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.13.6-1
- Support hot_deploy marker during gear sync (ironcladlou@gmail.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.13.5-1
- Separate prune into a pre step because gc needs additional space to run and
  prune does not.  This will allow space to be reclaimed before gc runs
  (dmcphers@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Refactor hot deploy support in Jenkins templates (ironcladlou@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)
- abstract jboss cart (bdecoste@gmail.com)

* Thu Jul 05 2012 William DeCoste <wdecoste@redhat.com> 0.13.3-1
- Abstract JBoss cartridge
  
* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
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
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'US2109' of github.com:openshift/origin-server into US2109
  (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Undo proxy code re-introduced via merge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Old backups will have data directory in the wrong place.  Allow either to
  exist in the tar file and transform the location on extraction without tar
  spitting out an error from providing non-existent path on the command line.
  (rmillner@redhat.com)
- Data directory moved to ~/app (rmillner@redhat.com)
- Merge branch 'US2109' of github.com:openshift/origin-server into US2109
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
- Automatic commit of package [openshift-origin-cartridge-abstract] release [0.10.5-1].
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
