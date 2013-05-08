%global cartridgedir %{_libexecdir}/openshift/cartridges/jbosseap-6.0
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap-6.0
Version: 1.9.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract-jboss
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      jbossas-appclient
Requires:      jbossas-bundles
Requires:      jbossas-core
Requires:      jbossas-domain
Requires:      jbossas-hornetq-native
Requires:      jbossas-jbossweb-native
Requires:      jbossas-modules-eap
Requires:      jbossas-product-eap
Requires:      jbossas-standalone
Requires:      jbossas-welcome-content-eap
Requires:      jboss-eap6-modules
Requires:      jboss-eap6-index
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
Provides JBossEAP6.0 support to OpenShift


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
cp jbosseap6.0.md %{buildroot}%{cartridgedir}/
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
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven
%endif

alternatives --remove jbosseap-6.0 /usr/share/jbossas
alternatives --install /etc/alternatives/jbosseap-6.0 jbosseap-6.0 /usr/share/jbossas 102
alternatives --set jbosseap-6.0 /usr/share/jbossas
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss eap 6.0.* upstream.
mkdir -p /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main/module.xml


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
%doc %{cartridgedir}/jbosseap6.0.md
%config %{cartridgedir}/info/configuration/
%config %{cartridgedir}/info/bin/standalone.conf


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Bug 955492: Fix rsync command to correct hot deployment
  (ironcladlou@gmail.com)
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
- Merge pull request #1934 from lnader/card-534 (dmcphers@redhat.com)
- Added Additional-Control-Actions to jbosseap-6.0 and jbossas-7
  (lnader@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- minor fixes (bdecoste@gmail.com)
- Bug 883944 (bdecoste@gmail.com)
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
- Add provider data to the UI that is exposed by the server
  (ccoleman@redhat.com)

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
- fix eap spec file versions (bdecoste@gmail.com)
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
- BZ906845 (bdecoste@gmail.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Collect/Sync Usage data for EAP cart (rpenta@redhat.com)

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

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- messaging thread pool based on gear size (bdecoste@gmail.com)
- BZ901546 (bdecoste@gmail.com)

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

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- BZ844858 (bdecoste@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Merge pull request #900 from bdecoste/master (openshift+bot@redhat.com)
- BZ844858 (bdecoste@gmail.com)
- Merge pull request #895 from smarterclayton/us3046_quickstarts_and_app_types
  (openshift+bot@redhat.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ875675 (bdecoste@gmail.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #870 from bdecoste/master (openshift+bot@redhat.com)
- update jgroups auth key (bdecoste@gmail.com)
- Merge pull request #869 from bdecoste/master (openshift+bot@redhat.com)
- BZ874174 (bdecoste@gmail.com)
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

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.7.6-1
- updated jboss modules readme (bdecoste@gmail.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.7.5-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.7.4-1
- Merge pull request #703 from bdecoste/master (openshift+bot@redhat.com)
- BZ867063 (bdecoste@gmail.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.7.3-1
- Merge pull request #695 from bdecoste/master (openshift+bot@redhat.com)
- BZ867064 (bdecoste@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.7.2-1
- bump spec file, somehow the tito tag got out of sync (admiller@redhat.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com>
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- jboss use abstract restore_tar and tidy (bdecoste@gmail.com)

* Tue Oct 09 2012 William DeCoste <wdecoste@redhat.com> 0.7.0-1
- official eap6 rpms

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.6.3-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.6.2-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.5.2-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.4.2-1
- Fix broken cartridge hook symlinks (ironcladlou@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- remove central repo from pom (bdecoste@gmail.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.3.7-1
- BZ844267 plus abstracted app_ctl_impl.sh (bdecoste@gmail.com)

* Tue Jul 31 2012 William DeCoste <wdecoste@redhat.com> 0.3.6-1
- abstracted app_ctl_impl.sh for JBoss

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.3.5-1
- add postgres connection validation (bdecoste@gmail.com)
- add mysql connection validation (bdecoste@gmail.com)

* Fri Jul 20 2012 Adam Miller <admiller@redhat.com> 0.3.4-1
- fixed EAP website (bdecoste@gmail.com)
- bz841683 (bdecoste@gmail.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.3.3-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)
- enable java7 (bdecoste@gmail.com)
- Refactor JBoss hot deployment support (ironcladlou@gmail.com)
- enable java7 (bdecoste@gmail.com)
- enable java7 (bdecoste@gmail.com)
- require java7 (bdecoste@gmail.com)
- require java7 (bdecoste@gmail.com)

* Wed Jul 18 2012 William DeCoste <wdecoste@redhat.com> 0.3.2-1
- Require Java7

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.2.5-1
- more cartridges have better metadata (rchopra@redhat.com)
- abstract jboss cart (bdecoste@gmail.com)

* Thu Jul 05 2012 William DeCoste <wdecoste@redhat.com> 0.2.4-1
- Abstract JBoss cartridge

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.2.3-1
- BZ 833373: Change default builder to small. (rmillner@redhat.com)

* Thu Jun 21 2012 Adam Miller <admiller@redhat.com> 0.2.2-1
- remove base m2_repository (dmcphers@redhat.com)
- Fix for BZ 831966: Added link to missing connection hook. (mpatel@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.1.10-1
- remove duplicate source (bdecoste@gmail.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.1.9-1
- merged Replace all env vars in standalone.xml (bdecoste@gmail.com)
- add Requires:      lsof to jboss spec (bdecoste@gmail.com)

* Fri Jun 15 2012 Adam Miller <admiller@redhat.com> 0.1.8-1
- updated eap template pom (bdecoste@gmail.com)
- add eap maven repo (bdecoste@gmail.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.1.7-1
- add product.conf for eap6 (bdecoste@gmail.com)
- updated eap6 standalone.xml (bdecoste@gmail.com)
- updated eap6 standalone.xml (bdecoste@gmail.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.1.6-1
- bug 831130 (bdecoste@gmail.com)
- EAP6.0.0.GA (bdecoste@gmail.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.1.4-1
- update to EAP 6.0 GA (bdecoste@gmail.com)

* Tue Jun 12 2012 William DeCoste <wdecoste@redhat.com> 0.1.0
- Update to 6.0 GA

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.1.3-1
- updated jms deployment (bdecoste@gmail.com)
- increased deployment timeout to 5mins (bdecoste@gmail.com)
- sync eap manifest.yml (bdecoste@gmail.com)
- Revert "BZ824124 remove unused doc_root connector" (kraman@gmail.com)
- BZ824124 remove unused doc_root connector (jhonce@redhat.com)
- US2307 - update deconfigure (bdecoste@gmail.com)

* Tue Jun 05 2012 Dan McPherson <dmcphers@redhat.com> 0.1.2-1
- new package built with tito

* Wed May 16 2012 William DeCoste <wdecoste@redhat.com> 0.1.0
- initial

