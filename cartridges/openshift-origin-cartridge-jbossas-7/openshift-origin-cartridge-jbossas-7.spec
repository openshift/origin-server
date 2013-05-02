%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossas-7
%global jbossver 7.1.1.Final
%global oldjbossver 7.1.0.Final

Summary:       Provides JBossAS7 support
Name:          openshift-origin-cartridge-jbossas-7
Version: 1.9.2
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract-jboss
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      lsof
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
Requires:      jboss-as7-modules >= %{jbossver}
%if 0%{?rhel}
Requires:      jboss-as7 >= %{jbossver}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      jboss-as
Requires:      bc
Requires:      maven
%endif
BuildRequires: git
BuildRequires: jpackage-utils
BuildArch:     noarch

%description
Provides JBossAS7 support to OpenShift


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
cp jbossas7.md %{buildroot}%{cartridgedir}/
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

ln -s %{cartridgedir}/../abstract-jboss/info/bin/app_ctl.sh %{buildroot}%{cartridgedir}/info/bin/app_ctl.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/app_ctl_impl.sh %{buildroot}%{cartridgedir}/info/bin/app_ctl_impl.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/deploy_httpd_proxy.sh %{buildroot}%{cartridgedir}/info/bin/deploy_httpd_proxy.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/deploy.sh %{buildroot}%{cartridgedir}/info/bin/deploy.sh

ln -s %{cartridgedir}/../abstract-jboss/info/connection-hooks/publish_jboss_cluster %{buildroot}%{cartridgedir}/info/connection-hooks/publish_jboss_cluster
ln -s %{cartridgedir}/../abstract-jboss/info/connection-hooks/publish_jboss_remoting %{buildroot}%{cartridgedir}/info/connection-hooks/publish_jboss_remoting
ln -s %{cartridgedir}/../abstract-jboss/info/connection-hooks/set_jboss_cluster %{buildroot}%{cartridgedir}/info/connection-hooks/set_jboss_cluster
ln -s %{cartridgedir}/../abstract-jboss/info/connection-hooks/set_jboss_remoting %{buildroot}%{cartridgedir}/info/connection-hooks/set_jboss_remoting

ln -s %{cartridgedir}/../abstract-jboss/info/hooks/deconfigure %{buildroot}%{cartridgedir}/info/hooks/deconfigure
ln -s %{cartridgedir}/../abstract-jboss/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump

ln -s %{cartridgedir}/../abstract-jboss/info/hooks/configure %{buildroot}%{cartridgedir}/info/hooks/configure

%post
# To modify an alternative you should:
# - remove the previous version if it's no longer valid
# - install the new version with an increased priority
# - set the new version as the default to be safe

%if 0%{?rhel}
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/java/apache-maven-3.0.3 100
alternatives --set maven-3.0 /usr/share/java/apache-maven-3.0.3

alternatives --remove jbossas-7 /opt/jboss-as-%{oldjbossver}
alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /opt/jboss-as-%{jbossver} 102
alternatives --set jbossas-7 /opt/jboss-as-%{jbossver}
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven

alternatives --remove jbossas-7.0 /user/share/jboss-as
alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /usr/share/jboss-as 102
alternatives --set jbossas-7 /usr/share/jboss-as
%endif

#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss as 7.* upstream.
mkdir -p /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main/module.xml


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
%doc %{cartridgedir}/jbossas7.md
%config %{cartridgedir}/info/configuration/
%config %{cartridgedir}/info/bin/standalone.conf

%changelog
* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- update as v2 spec for as7.1.1 (bdecoste@gmail.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- switchyard update and as 7.1.1 upgrade (bdecoste@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Bug 956497: Fix port bindings for jboss carts (ironcladlou@gmail.com)
- Bug 955492: Fix rsync command to correct hot deployment
  (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Merge pull request #1981 from bdecoste/master (dmcphers@redhat.com)
- Update standalone.xml (bdecoste@gmail.com)
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #1934 from lnader/card-534 (dmcphers@redhat.com)
- Added Additional-Control-Actions to jbosseap-6.0 and jbossas-7
  (lnader@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- minor fixes (bdecoste@gmail.com)
- update rsync (bdecoste@gmail.com)
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
- Merge pull request #1822 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 928142 (bdecoste@gmail.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1800 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 927192 (bdecoste@gmail.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- updated Fedora Requires (bdecoste@gmail.com)
- updated Fedora Requires (bdecoste@gmail.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Bug 920375 (bdecoste@gmail.com)
- Bug 920375 (bdecoste@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Bug 906840 (bdecoste@gmail.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- JBoss cartridge documentation for OSE 1.1 (calfonso@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- Bug 916388: Fix JBoss tidy scripts (ironcladlou@gmail.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Merge pull request #1474 from bdecoste/master (dmcphers@redhat.com)
- Bug 913217 (bdecoste@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Merge pull request #1454 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 895507 (bdecoste@gmail.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 906840 (bdecoste@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- config for more resilient proxied datasources (bdecoste@gmail.com)
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

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.7-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- Bug 906845 - maven heap size (bdecoste@gmail.com)
- Bug 906845 (bdecoste@gmail.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Merge pull request #1285 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- BZ906845 (bdecoste@gmail.com)
- BZ906845 (bdecoste@gmail.com)
- BZ906845 (bdecoste@gmail.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- add Fedora link to AS base for AS7 (bdecoste@gmail.com)

* Thu Jan 31 2013 Bill DeCoste <bdecoste@gmail.com> 1.4.3-1
- add Fedora link to AS base 

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- BZ904081 (bdecoste@gmail.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Bug 889932 (dmcphers@redhat.com)
- Manifest file fixes (kraman@gmail.com)
- Fixed scaled app creation Fixed scaled app cartridge addition Updated
  descriptors to set correct group overrides for web_cartridges
  (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- messaging thread pool based on gear size (bdecoste@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- routable ws host/port (bdecoste@gmail.com)
- Fix BZ864797: Add doc for disable_auto_scaling marker (pmorie@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1058 from bdecoste/master (dmcphers@redhat.com)
- reset jgroups bind addr (bdecoste@gmail.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- removed ews2.0 and sy xslt (bdecoste@gmail.com)
- ews2 and bugs (bdecoste@gmail.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- BZ881365 (bdecoste@gmail.com)
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- Merge pull request #976 from jwhonce/dev/rm_post-remove
  (openshift+bot@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- BZ844858 (bdecoste@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #900 from bdecoste/master (openshift+bot@redhat.com)
- BZ844858 (bdecoste@gmail.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #870 from bdecoste/master (openshift+bot@redhat.com)
- update jgroups auth key (bdecoste@gmail.com)
- Merge pull request #858 from bdecoste/master (openshift+bot@redhat.com)
- BZ821556 (bdecoste@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- US3064 - switchyard (bdecoste@gmail.com)
- BZ874174 (bdecoste@gmail.com)
- Merge pull request #841 from bdecoste/master (openshift+bot@redhat.com)
- BZ867083 and initial switchyard cart (bdecoste@gmail.com)
- Merge pull request #833 from tdawson/tdawson/fed-update/openshift-origin-
  cartridge-abstract-1.1.1 (openshift+bot@redhat.com)
- Cleanup spec for Fedora standards (tdawson@redhat.com)
- BZ868053 (bdecoste@gmail.com)
- Bumping specs to at least 1.1 (dmcphers@redhat.com)
- Merge pull request #818 from bdecoste/master (dmcphers@redhat.com)
- updated jboss README (bdecoste@gmail.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.98.9-1
- updated jboss modules readme (bdecoste@gmail.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.98.8-1
- Merge pull request #188 from slagle/dev/slagle-ssl-certificate
  (openshift+bot@redhat.com)
- BZ867064 (bdecoste@gmail.com)
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.98.7-1
- Merge pull request #703 from bdecoste/master (openshift+bot@redhat.com)
- BZ867063 (bdecoste@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.98.6-1
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.98.5-1
- Both prod and stg mirrors point to the ops mirror -- so use
  mirror1.ops.rhcloud.com - also makes for consistent behaviour across
  DEV/STG/INT/PROD. (ramr@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.98.4-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.98.3-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.98.2-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.98.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.97.2-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.97.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.96.6-1
- BZ844267 plus abstracted app_ctl_impl.sh (bdecoste@gmail.com)

* Tue Jul 31 2012 William DeCoste <wdecoste@redhat.com> 0.96.5-1
- abstracted app_ctl_impl.sh for JBoss

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.96.4-1
- add postgres connection validation (bdecoste@gmail.com)
- add mysql connection validation (bdecoste@gmail.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.96.3-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)
- enable java7 (bdecoste@gmail.com)
- Refactor JBoss hot deployment support (ironcladlou@gmail.com)
- enable java7 (bdecoste@gmail.com)
- enable java7 (bdecoste@gmail.com)
- require java7 (bdecoste@gmail.com)
- require java7 (bdecoste@gmail.com)

* Wed Jul 18 2012 William DeCoste <wdecoste@redhat.com> 0.96.2-1
- Require Java7

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.96.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.95.5-1
- Merge pull request #183 from rajatchopra/master (admiller@redhat.com)
- Refactor hot deploy support in Jenkins templates (ironcladlou@gmail.com)
- more cartridges have better metadata (rchopra@redhat.com)
- abstract jboss cart (bdecoste@gmail.com)

* Thu Jul 05 2012 William DeCoste <wdecoste@redhat.com> 0.95.4-1
- Abstract JBoss cartridge

* Thu Jun 21 2012 Adam Miller <admiller@redhat.com> 0.95.3-1
- remove base m2_repository (dmcphers@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.95.2-1
- 

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.95.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.94.9-1
- remove duplicate source (bdecoste@gmail.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.94.8-1
- Merge branch 'master' of github.com:openshift/origin-server (admiller@redhat.com)
- Install initial ROOT.war into app-root during configure (dmace@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.94.7-1
- merged Replace all env vars in standalone.xml (bdecoste@gmail.com)
- Merge pull request #124 from
  matejonnet/dev/mlazar/update/jboss_add_custom_module_dir (bdecoste@gmail.com)
- add Requires:      lsof to jboss spec (bdecoste@gmail.com)
- Add custom module path to JBoss AS. (matejonnet@gmail.com)
- Replace all env vars in standalone.xml. (matejonnet@gmail.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.94.6-1
- The medium builder appears to be unnecessary now and causes some confusion.
  (rmillner@redhat.com)
- Add hot deployment support via hot_deploy marker (dmace@redhat.com)
- updated eap6 standalone.xml (bdecoste@gmail.com)

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.94.5-1
- bug 831130 (bdecoste@gmail.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.94.4-1
- 

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.94.3-1
- updated jms deployment (bdecoste@gmail.com)
- increased deployment timeout to 5mins (bdecoste@gmail.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.94.2-1
- Disable restart of JBoss app on namespace alter (dmace@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.94.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.93.8-1
- Bug 825354 (dmcphers@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)
- Adding a dependency resolution step (using post-recieve hook) for all
  applications created from templates. Simplifies workflow by not requiring an
  additional git pull/push step Cucumber tests (kraman@gmail.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.93.7-1
- Merge pull request #42 from ironcladlou/master
  (mmcgrath+openshift@redhat.com)
- fix for bug#822080 and jboss cartridge now has a scaling minimum of 1
  (rchopra@redhat.com)
- Merge pull request #46 from rajatchopra/master (kraman@gmail.com)
- change scaling policies in manifest.yml so that jboss really takes 2 as
  minimum (rchopra@redhat.com)
- Implement update-namespace hook in jbossas-7 cart (dmace@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.93.6-1
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.93.5-1
- fix standalone.xml webservices wsdlHost (bdecoste@gmail.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.93.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Old backups will have data directory in the wrong place.  Allow either to
  exist in the tar file and transform the location on extraction without tar
  spitting out an error from providing non-existent path on the command line.
  (rmillner@redhat.com)
- Data directory moved to ~/app (rmillner@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-jbossas-7] release [0.93.2-1].
  (admiller@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- bug 820822 - increased timeout (bdecoste@gmail.com)
- bug 820822 - increased timeout (bdecoste@gmail.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-jbossas-7] release [0.92.4-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.93.3-1
- Changes to descriptors/specs to execute the new connector.
  (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.93.2-1
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- bug821960 (bdecoste@gmail.com)
- Add sample user pre/post hooks. (rmillner@redhat.com)
- bug 820822 - increased timeout (bdecoste@gmail.com)
- bug 820822 - increased timeout (bdecoste@gmail.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.93.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.92.4-1
- Bug 819739 (dmcphers@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.92.2-1
- US2113 (bdecoste@gmail.com)
- US2113 (bdecoste@gmail.com)
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.92.1-1
- bumping spec versions (admiller@redhat.com)

* Wed Apr 25 2012 Krishna Raman <kraman@gmail.com> 0.91.7-1
- Setup defaults for maven settings and memory usage (kraman@gmail.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.91.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.91.5-1
- new package built with tito
