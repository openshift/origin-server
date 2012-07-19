%global cartridgedir %{_libexecdir}/stickshift/cartridges/jbosseap-6.0
%global jbossver 6.0.0.GA
%global oldjbossver 6.0.0.Beta2

Summary:   Provides JBossEAP6.0 support
Name:      cartridge-jbosseap-6.0
Version: 0.2.5
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
BuildRequires: java-devel >= 1:1.6.0
BuildRequires: jpackage-utils
Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: jboss-eap6 >= %{jbossver}
Requires: jboss-eap6-modules >= %{jbossver}
Requires: lsof

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
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp README %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
cp -r template %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
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
ln -s %{cartridgedir}/../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
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

ln -s %{cartridgedir}/../abstract-jboss/info/bin/app_ctl.sh %{buildroot}%{cartridgedir}/info/bin/app_ctl.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/build.sh %{buildroot}%{cartridgedir}/info/bin/build.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/deploy_httpd_proxy.sh %{buildroot}%{cartridgedir}/info/bin/deploy_httpd_proxy.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/deploy.sh %{buildroot}%{cartridgedir}/info/bin/deploy.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/tidy.sh %{buildroot}%{cartridgedir}/info/bin/tidy.sh
ln -s %{cartridgedir}/../abstract-jboss/info/bin/restore_tar.sh %{buildroot}%{cartridgedir}/info/bin/restore_tar.sh

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

alternatives --remove jbosseap-6.0 /opt/jboss-eap-%{oldjbossver}
alternatives --install /etc/alternatives/jbosseap-6.0 jbosseap-6.0 /opt/jboss-eap-%{jbossver} 102
alternatives --set jbosseap-6.0 /opt/jboss-eap-%{jbossver}
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
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%config(noreplace) %{cartridgedir}/info/configuration/


%changelog
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

