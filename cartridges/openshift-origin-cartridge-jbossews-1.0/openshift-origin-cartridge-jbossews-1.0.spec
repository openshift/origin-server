%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews-1.0
%global jbossver 1.0.2.GA
%global oldjbossver 1.0.1.GA

Summary:       Provides JBossEWS1.0 support
Name:          openshift-origin-cartridge-jbossews-1.0
Version: 1.10.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract-jboss
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      tomcat6
Requires:      lsof
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
%if 0%{?rhel}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      maven
%endif
BuildRequires: git
BuildRequires: jpackage-utils
BuildArch:     noarch

%description
Provides JBossEWS1.0 support to OpenShift


%prep
%setup -q


%build


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp README %{buildroot}%{cartridgedir}/
cp jbossews1.0.md %{buildroot}%{cartridgedir}/
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
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh
ln -s %{cartridgedir}/../abstract/info/bin/restore_tar.sh %{buildroot}%{cartridgedir}/info/bin/restore_tar.sh

#ln -s %{cartridgedir}/../abstract-jboss/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump

%post
# To modify an alternative you should:
# - remove the previous version if it's no longer valid
# - install the new version with an increased priority
# - set the new version as the default to be safe

%if 0%{?rhel}
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/java/apache-maven-3.0.3 100
alternatives --set maven-3.0 /usr/share/java/apache-maven-3.0.3
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven
%endif

alternatives --remove jbossews-1.0 /usr/share/tomcat6
alternatives --install /etc/alternatives/jbossews-1.0 jbossews-1.0 /usr/share/tomcat6 102
alternatives --set jbossews-1.0 /usr/share/tomcat6
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss ews 1.0.* upstream.
#mkdir -p /etc/alternatives/jbossews-6.0/modules/org/postgresql/jdbc/main
#ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossews-1.0/modules/org/postgresql/jdbc/main
#cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbossews-1.0/modules/org/postgresql/jdbc/main/module.xml


%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%{cartridgedir}/template/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%doc %{cartridgedir}/jbossews1.0.md
%config(noreplace) %{cartridgedir}/info/configuration/


%changelog
* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Bug 960650: Integrate with mysql and postgresql cartridges by default
  (ironcladlou@gmail.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Bug 958892 (bdecoste@gmail.com)
- Bug 958892 (bdecoste@gmail.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Merge pull request #2345 from pmorie/bugs/957262
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2342 from BanzaiMan/dev/hasari/c288_followup
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 957262 (pmorie@gmail.com)
- Merge pull request #2340 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)
- fix env / replacement (bdecoste@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Bugs 958709, 958744, 958757 (dmcphers@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Bug 956651 (bdecoste@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

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

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Bug 922650: Fix default ROOT.war for JBoss carts (ironcladlou@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- JBoss cartridge documentation for OSE 1.1 (calfonso@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Bug 916388: Fix JBoss tidy scripts (ironcladlou@gmail.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Merge pull request #1474 from bdecoste/master (dmcphers@redhat.com)
- Bug 913217 (bdecoste@gmail.com)
- Bug 913217 (bdecoste@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 895507 (bdecoste@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Merge pull request #1351 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- default resource settings (bdecoste@gmail.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Bug 906845 - maven heap size (bdecoste@gmail.com)
- Bug 906845 (bdecoste@gmail.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Merge pull request #1285 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- BZ906845 (bdecoste@gmail.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Add tomcat version tags so that new RHC will allow 'rhc app create foo
  tomcat6' (ccoleman@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Bug 889932 (dmcphers@redhat.com)
- Fixed scaled app creation Fixed scaled app cartridge addition Updated
  descriptors to set correct group overrides for web_cartridges
  (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Fix typos in rhc instructions displayed to client (ironcladlou@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Add missing routes.json configuration for jboss* app types + minor cleanup.
  (ramr@redhat.com)
- Fix BZ864797: Add doc for disable_auto_scaling marker (pmorie@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
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

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Merge pull request #895 from smarterclayton/us3046_quickstarts_and_app_types
  (openshift+bot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- Update the JBoss cart name (ccoleman@redhat.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Source rewritten PATH before further mods (ironcladlou@gmail.com)
- Use standard PATH util in jboss carts (ironcladlou@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #833 from tdawson/tdawson/fed-update/openshift-origin-
  cartridge-abstract-1.1.1 (openshift+bot@redhat.com)
- Cleanup spec for Fedora standards (tdawson@redhat.com)
- BZ868053 (bdecoste@gmail.com)
- Merge pull request #822 from bdecoste/master (openshift+bot@redhat.com)
- BZ872533 (bdecoste@gmail.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.10-1
- Merge pull request #805 from bdecoste/master (openshift+bot@redhat.com)
- updated ews UI info (bdecoste@gmail.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.9-1
- BZ871314 (bdecoste@gmail.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 1.0.8-1
- Merge pull request #188 from slagle/dev/slagle-ssl-certificate
  (openshift+bot@redhat.com)
- BZ867064 (bdecoste@gmail.com)
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 1.0.7-1
- Merge pull request #711 from bdecoste/master (dmcphers@redhat.com)
- ews bugs (bdecoste@gmail.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 1.0.6-1
- Merge pull request #703 from bdecoste/master (openshift+bot@redhat.com)
- BZ867063 (bdecoste@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 1.0.5-1
- Merge pull request #680 from ramr/master (dmcphers@redhat.com)
- Fix EWS cartridge mirrors. Both prod and stg mirrors point to the ops mirror
  -- so use mirror1.ops.rhcloud.com - also makes for consistent behaviour
  across DEV/STG/INT/PROD. (ramr@redhat.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 1.0.4-1
- BZ863937  Need update rhc app tail to rhc tail for output of rhc threaddump
  command (calfonso@redhat.com)
- BZ866327 (bdecoste@gmail.com)
- fixed ews scaling (bdecoste@gmail.com)
- fixed ews pid for scaled (bdecoste@gmail.com)
- BZ865282 and updated sample app (bdecoste@gmail.com)
- updated isrunning (bdecoste@gmail.com)
- added ews2 and cleaned ews1 (bdecoste@gmail.com)
- added ews2 and cleaned ews1 (bdecoste@gmail.com)
- update (bdecoste@gmail.com)
- update (bdecoste@gmail.com)
- updated ews cart (bdecoste@gmail.com)

* Thu Oct 11 2012 William DeCoste <wdecoste@redhat.com> 1.0.3-1
- update

* Thu Oct 11 2012 William DeCoste <wdecoste@redhat.com> 1.0.2-1
- update

* Wed Oct 10 2012 William DeCoste <wdecoste@redhat.com> 1.0.1-1
- update

* Wed Oct 10 2012 William DeCoste <wdecoste@redhat.com> 1.0.0-1
- initial

