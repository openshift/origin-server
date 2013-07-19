%global cartridgedir %{_libexecdir}/openshift/cartridges/aerogear-push
%global jbossver 7.1.1.Final

Summary:       Provides the AeroGear UnifiedPush Server on top of JBossAS7
Name:          openshift-origin-cartridge-aerogear-push
Version: 1.0.0
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


