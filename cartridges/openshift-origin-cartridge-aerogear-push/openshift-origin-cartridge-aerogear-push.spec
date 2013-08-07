%global cartridgedir %{_libexecdir}/openshift/cartridges/aerogear-push
%global jbossver 7.1.1.Final

Summary:       Provides the AeroGear UnifiedPush Server on top of JBossAS7
Name:          openshift-origin-cartridge-aerogear-push
Version: 1.0.7
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       https://github.com/fjuma/openshift-origin-cartridge-aerogear-push/archive/master.zip
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      lsof
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
Requires:      jboss-as7-modules >= %{jbossver}
Requires:	   facter
%if 0%{?rhel}
Requires:      jboss-as7 >= %{jbossver}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      jboss-as
Requires:      bc
Requires:      maven
%endif
BuildRequires: jpackage-utils
BuildArch:     noarch

%description
Provides the AeroGear UnifiedPush Server on top of JBossAS7 on OpenShift. (Cartridge Format V2)


%prep
%setup -q


%build
%__rm %{name}.spec


%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}


%post

%if 0%{?rhel}
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/java/apache-maven-3.0.3 100
alternatives --set maven-3.0 /usr/share/java/apache-maven-3.0.3

alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /opt/jboss-as-%{jbossver} 102
alternatives --set jbossas-7 /opt/jboss-as-%{jbossver}
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven

alternatives --remove jbossas-7 /usr/share/jboss-as
alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /usr/share/jboss-as 102
alternatives --set jbossas-7 /usr/share/jboss-as
%endif

# Add the AeroGear netty module
mkdir -p %{cartridgedir}/usr/modules/org/jboss/aerogear/netty/main
ln -fs %{cartridgedir}/versions/0.8.0/modules/org/jboss/aerogear/netty/main/* %{cartridgedir}/usr/modules/org/jboss/aerogear/netty/main

# Add the AeroGear SimplePush module
mkdir -p %{cartridgedir}/usr/modules/org/jboss/aerogear/simplepush/main
ln -fs %{cartridgedir}/versions/0.8.0/modules/org/jboss/aerogear/simplepush/main/* %{cartridgedir}/usr/modules/org/jboss/aerogear/simplepush/main


%posttrans
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/versions/0.8.0/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Tue Aug 06 2013 Paul Morie <pmorie@gmail.com> 1.0.7-1
- Updating to the latest SimplePush, UnifiedPush, and 0.0.2 version of the
  AdminUI. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.6-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.5-1]. (pmorie@gmail.com)
- Updating to the latest UnifiedPush, SimplePush, and Netty subsystem with
  datasource dependency support. (fjuma@redhat.com)
- Temporarily installing the AeroGear SimplePush and Netty modules in
  bin/install instead of the spec file to make it easier to remove the spec
  file for the downloadable cartridge. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.4-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and to the latest UnifiedPush WAR that
  contains a fix for the AdminUI. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.3-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and Netty modules and to the latest
  UnifiedPush WAR that contains the initial AdminUI. (fjuma@redhat.com)
- Updating the modules and subsystem configuration for SimplePush and adding a
  datasource for SimplePush. (fjuma@redhat.com)
- Updating to the latest UnifiedPush Server WAR file and modifying the
  UnifiedPush datasource name. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.2-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)
- Initial import from fjuma (pmorie@gmail.com)

* Thu Aug 01 2013 Paul Morie <pmorie@gmail.com> 1.0.6-1
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.5-1]. (pmorie@gmail.com)
- Updating to the latest UnifiedPush, SimplePush, and Netty subsystem with
  datasource dependency support. (fjuma@redhat.com)
- Temporarily installing the AeroGear SimplePush and Netty modules in
  bin/install instead of the spec file to make it easier to remove the spec
  file for the downloadable cartridge. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.4-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and to the latest UnifiedPush WAR that
  contains a fix for the AdminUI. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.3-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and Netty modules and to the latest
  UnifiedPush WAR that contains the initial AdminUI. (fjuma@redhat.com)
- Updating the modules and subsystem configuration for SimplePush and adding a
  datasource for SimplePush. (fjuma@redhat.com)
- Updating to the latest UnifiedPush Server WAR file and modifying the
  UnifiedPush datasource name. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.2-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)
- Initial import from fjuma (pmorie@gmail.com)

* Wed Jul 31 2013 Paul Morie <pmorie@gmail.com> 1.0.5-1
- Updating to the latest UnifiedPush, SimplePush, and Netty subsystem with
  datasource dependency support. (fjuma@redhat.com)
- Temporarily installing the AeroGear SimplePush and Netty modules in
  bin/install instead of the spec file to make it easier to remove the spec
  file for the downloadable cartridge. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.4-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and to the latest UnifiedPush WAR that
  contains a fix for the AdminUI. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.3-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and Netty modules and to the latest
  UnifiedPush WAR that contains the initial AdminUI. (fjuma@redhat.com)
- Updating the modules and subsystem configuration for SimplePush and adding a
  datasource for SimplePush. (fjuma@redhat.com)
- Updating to the latest UnifiedPush Server WAR file and modifying the
  UnifiedPush datasource name. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.2-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)
- Initial import from fjuma (pmorie@gmail.com)

* Tue Jul 30 2013 Paul Morie <pmorie@gmail.com> 1.0.4-1
- Updating to the latest SimplePush and to the latest UnifiedPush WAR that
  contains a fix for the AdminUI. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.3-1]. (pmorie@gmail.com)
- Updating to the latest SimplePush and Netty modules and to the latest
  UnifiedPush WAR that contains the initial AdminUI. (fjuma@redhat.com)
- Updating the modules and subsystem configuration for SimplePush and adding a
  datasource for SimplePush. (fjuma@redhat.com)
- Updating to the latest UnifiedPush Server WAR file and modifying the
  UnifiedPush datasource name. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.2-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)
- Initial import from fjuma (pmorie@gmail.com)

* Mon Jul 29 2013 Paul Morie <pmorie@gmail.com> 1.0.3-1
- Updating to the latest SimplePush and Netty modules and to the latest
  UnifiedPush WAR that contains the initial AdminUI. (fjuma@redhat.com)
- Updating the modules and subsystem configuration for SimplePush and adding a
  datasource for SimplePush. (fjuma@redhat.com)
- Updating to the latest UnifiedPush Server WAR file and modifying the
  UnifiedPush datasource name. (fjuma@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.2-1]. (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)
- Initial import from fjuma (pmorie@gmail.com)

* Tue Jul 23 2013 Paul Morie <pmorie@gmail.com> 1.0.2-1
- Automatic commit of package [openshift-origin-cartridge-aerogear-push]
  release [1.0.1-1]. (pmorie@gmail.com)
- Changing the port for the SimplePush socket binding to 8676.
  (fjuma@redhat.com)

* Mon Jul 22 2013 Paul Morie <pmorie@gmail.com> 1.0.1-1
- new package built with tito



