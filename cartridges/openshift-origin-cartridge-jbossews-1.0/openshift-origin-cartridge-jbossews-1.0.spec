%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews-1.0
%global jbossver 1.0.2.GA
%global oldjbossver 1.0.1.GA

Summary:   Provides JBossEWS1.0 support
Name:      openshift-origin-cartridge-jbossews-1.0
Version:   1.0.11
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
BuildRequires: java-devel >= 1:1.6.0
BuildRequires: jpackage-utils
Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: tomcat6
Requires: lsof
Requires: java-1.7.0-openjdk
Requires: java-1.7.0-openjdk-devel

%if 0%{?rhel}
Requires: maven3
%endif

%if 0%{?fedora}
Requires: maven
%endif


%description
Provides JBossEWS1.0 support to OpenShift


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
* Fri Nov 02 2012 Adam Miller <admiller@redhat.com> 1.0.11-1
- BZ872533 (bdecoste@gmail.com)
- BZ872533 (bdecoste@gmail.com)

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

