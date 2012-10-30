%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossas-7
%global jbossver 7.1.0.Final
%global oldjbossver 7.0.2.Final

Summary:   Provides JBossAS7 support
Name:      openshift-origin-cartridge-jbossas-7
Version: 1.0.1
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
Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: jboss-as7 >= %{jbossver}
Requires: jboss-as7-modules >= %{jbossver}
Requires: lsof
Requires: java-1.7.0-openjdk
Requires: java-1.7.0-openjdk-devel
Obsoletes: cartridge-jbossas-7

%if 0%{?rhel}
Requires: maven3
%endif

%if 0%{?fedora}
Requires: maven
%endif


%description
Provides JBossAS7 support to OpenShift


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
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh
ln -s %{cartridgedir}/../abstract/info/bin/restore_tar.sh %{buildroot}%{cartridgedir}/info/bin/restore_tar.sh
ln -s %{cartridgedir}/../abstract/info/bin/tidy.sh %{buildroot}%{cartridgedir}/info/bin/tidy.sh

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

alternatives --remove jbossas-7.0 /opt/jboss-as-%{oldjbossver}
alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /opt/jboss-as-%{jbossver} 102
alternatives --set jbossas-7 /opt/jboss-as-%{jbossver}
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss as 7.* upstream.
mkdir -p /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main/module.xml


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
- add Requires: lsof to jboss spec (bdecoste@gmail.com)
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
