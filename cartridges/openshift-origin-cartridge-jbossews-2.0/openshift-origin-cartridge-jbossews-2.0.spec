%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews-2.0
%global jbossver 2.0.0.GA
%global oldjbossver 2.0.0.CR1

Summary:   Provides JBossEWS2.0 support
Name:      openshift-origin-cartridge-jbossews-2.0
Version: 1.1.6
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildArch: noarch

BuildRequires: git
BuildRequires: java-devel >= 1:1.6.0
BuildRequires: jpackage-utils
Requires: openshift-origin-cartridge-abstract-jboss
Requires: rubygem(openshift-origin-node)
Requires: tomcat7
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
Provides JBossEWS2.0 support to OpenShift


%prep
%setup -q


%build
mkdir -p info/data
pushd template/src/main/webapp > /dev/null
/usr/bin/jar -cvf ../../../../info/data/ROOT.war -C . .
popd


%install
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
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

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

alternatives --remove jbossews-2.0 /usr/share/tomcat7
alternatives --install /etc/alternatives/jbossews-2.0 jbossews-2.0 /usr/share/tomcat7 102
alternatives --set jbossews-2.0 /usr/share/tomcat7
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss ews 1.0.* upstream.
#mkdir -p /etc/alternatives/jbossews-6.0/modules/org/postgresql/jdbc/main
#ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossews-2.0/modules/org/postgresql/jdbc/main
#cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbossews-2.0/modules/org/postgresql/jdbc/main/module.xml


%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
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
* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.1.6-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.1.5-1
- Bug 906845 - maven heap size (bdecoste@gmail.com)
- Bug 906845 (bdecoste@gmail.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.1.4-1
- Merge pull request #1285 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- BZ906845 (bdecoste@gmail.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.1.3-1
- Add tomcat version tags so that new RHC will allow 'rhc app create foo
  tomcat6' (ccoleman@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.1.2-1
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

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.0.9-1
- Merge pull request #1189 from ironcladlou/bz/902178
  (dmcphers+openshiftbot@redhat.com)
- Fix typos in rhc instructions displayed to client (ironcladlou@gmail.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.0.8-1
- Merge pull request #1018 from tdawson/tdawson/mirrors.fix
  (dmcphers+openshiftbot@redhat.com)
- changed mirror1.stg and prod to mirror1.ops (tdawson@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.0.7-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Fri Jan 11 2013 Adam Miller <admiller@redhat.com> 1.0.6-1
- new package built with tito

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.0.5-1
- Merge pull request #1035 from abhgupta/abhgupta-dev
  (openshift+bot@redhat.com)
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.0.4-1
- Fix for Bug 880013 (jhonce@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.0.3-1
- new package built with tito

* Wed Nov 21 2012 Bill DeCoste <bdecoste@gmail.com> 1.0.2-1
- new package built with tito

* Thu Oct 11 2012 William DeCoste <wdecoste@redhat.com> 1.0.1-1
- initial


