%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jbosseap
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version:       2.0.6
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract-jboss
Requires:      rubygem(openshift-origin-node)
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
Provides JBossEAP support to OpenShift


%prep
%setup -q


%build


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/

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
cp -p %{cartridgedir}/versions/6.0/modules/postgresql_module.xml /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main/module.xml


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 2.0.6-1
- Add provider data to the UI that is exposed by the server
  (ccoleman@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 2.0.5-1
- Merge pull request #1748 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 920375 (bdecoste@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 2.0.4-1
- updated jbosseap cart (bdecoste@gmail.com)
- fix postgresql module for jbosseap (bdecoste@gmail.com)
- v2 cart cleanup (bdecoste@gmail.com)
- V2 manifest fixes (ironcladlou@gmail.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 2.0.3-1
- Merge pull request #1655 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 2.0.2-1
- fix eap spec file versions (bdecoste@gmail.com)
- Merge pull request #1644 from ironcladlou/dev/v2carts/endpoint-refactor
  (dmcphers@redhat.com)
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 2.0.1-1
- Fixing tito tags on master

* Wed Mar 13 2013 Bill DeCoste <bdecoste@gmail.com> 2.0.1-1
- new package built with tito


