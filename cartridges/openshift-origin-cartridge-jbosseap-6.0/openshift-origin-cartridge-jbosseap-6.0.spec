%global cartridgedir %{_libexecdir}/openshift/cartridges/jbosseap-6.0
%global jbossver 6.0.0.GA
%global oldjbossver 6.0.0.Beta2

Summary:   Provides JBossEAP6.0 support
Name:      openshift-origin-cartridge-jbosseap-6.0
Version: 1.2.2
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
BuildRequires: java-devel >= 1:1.6.0
BuildRequires: jpackage-utils
Requires: openshift-origin-cartridge-abstract-jboss
Requires: rubygem(openshift-origin-node)
Requires: jbossas-appclient
Requires: jbossas-bundles
Requires: jbossas-core
Requires: jbossas-domain
Requires: jbossas-hornetq-native
Requires: jbossas-jbossweb-native
Requires: jbossas-modules-eap
Requires: jbossas-product-eap
Requires: jbossas-standalone
Requires: jbossas-welcome-content-eap
Requires: jboss-eap6-modules >= %{jbossver}
Requires: jboss-eap6-index
Requires: lsof
Requires: java-1.7.0-openjdk
Requires: java-1.7.0-openjdk-devel
Obsoletes: cartridge-jbosseap-6.0

%if 0%{?rhel}
Requires: maven3
%endif

%if 0%{?fedora}
Requires: maven
%endif


%description
Provides JBossEAP6.0 support to OpenShift


%prep
%setup -q


%build
mkdir -p info/data
pushd template/src/main/webapp > /dev/null
/usr/bin/jar -cvf ../../../../info/data/ROOT.war -C . .
popd


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp README %{buildroot}%{cartridgedir}/
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
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
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

ln -s %{cartridgedir}/../abstract-jboss/info/data/mysql.tar %{buildroot}%{cartridgedir}/info/data/mysql.tar

ln -s %{cartridgedir}/../abstract-jboss/info/hooks/conceal-port %{buildroot}%{cartridgedir}/info/hooks/conceal-port
ln -s %{cartridgedir}/../abstract-jboss/info/hooks/deconfigure %{buildroot}%{cartridgedir}/info/hooks/deconfigure
ln -s %{cartridgedir}/../abstract-jboss/info/hooks/expose-port %{buildroot}%{cartridgedir}/info/hooks/expose-port
ln -s %{cartridgedir}/../abstract-jboss/info/hooks/show-port %{buildroot}%{cartridgedir}/info/hooks/show-port
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


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0640,-,-) %{cartridgedir}/info/data/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%{cartridgedir}/template/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%config(noreplace) %{cartridgedir}/info/configuration/


%changelog
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
- add Requires: lsof to jboss spec (bdecoste@gmail.com)

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

