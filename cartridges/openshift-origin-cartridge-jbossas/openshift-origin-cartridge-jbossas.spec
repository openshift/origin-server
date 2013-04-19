%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jbossas
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/jbossas
%global jbossver 7.1.0.Final
%global oldjbossver 7.0.2.Final

Summary:       Provides JBossAS7 support
Name:          openshift-origin-cartridge-jbossas
Version: 1.1.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
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
Provides JBossAS support to OpenShift. (Cartridge Format V2)


%prep
%setup -q


%build


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jbossas

%if 0%{?rhel}
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/java/apache-maven-3.0.3 100
alternatives --set maven-3.0 /usr/share/java/apache-maven-3.0.3
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven
%endif

alternatives --remove jbossas-7.1 /usr/share/jbossas
alternatives --install /etc/alternatives/jbossas-7.1 jbossas-7.1 /usr/share/jbossas 102
alternatives --set jbossas-7.1 /usr/share/jbossas
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss as7.* upstream.
mkdir -p /etc/alternatives/jbossas-7.1/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossas-7.1/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/versions/7.1/modules/postgresql_module.xml /etc/alternatives/jbossas-7.1/modules/org/postgresql/jdbc/main/module.xml

%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jbossas


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.0.7-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 1.0.6-1
- V2 action hook cleanup (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Merge pull request #2056 from bdecoste/master (dmcphers@redhat.com)
- fix version in spec (bdecoste@gmail.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.0.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- be able to remove .openshift (bdecoste@gmail.com)
- install cart from spec (bdecoste@gmail.com)

* Thu Apr 11 2013 Dan McPherson <dmcphers@redhat.com> 1.0.4-1
- 

* Thu Apr 11 2013 Dan McPherson <dmcphers@redhat.com> 1.0.3-1
- new package built with tito

* Wed Apr 10 2013 Bill DeCoste <bdecoste@gmail.com> 1.0.2-1
- 

* Wed Apr 10 2013 Bill DeCoste <bdecoste@gmail.com> 1.0.1-1
- new package built with tito



