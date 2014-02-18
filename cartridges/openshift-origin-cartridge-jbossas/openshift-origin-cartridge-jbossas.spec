%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossas
%global jbossver 7.1.1.Final
%global oldjbossver 7.1.0.Final

Summary:       Provides JBossAS7 support
Name:          openshift-origin-cartridge-jbossas
Version: 1.21.0
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
Requires:      bc
%if 0%{?rhel}
Requires:      jboss-as7 >= %{jbossver}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      jboss-as
Requires:      maven
%endif
BuildRequires: jpackage-utils
Provides:      openshift-origin-cartridge-jbossas-7 = 2.0.0
Obsoletes:     openshift-origin-cartridge-jbossas-7 <= 1.99.9
BuildArch:     noarch

%description
Provides JBossAS support to OpenShift. (Cartridge Format V2)


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

if [ `alternatives --display jbossas-7 | grep jboss-as-%{oldjbossver} | wc -l` -gt 0 ]; then
  alternatives --remove jbossas-7 /opt/jboss-as-%{oldjbossver}
fi
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

#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss as7.* upstream.
mkdir -p /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/versions/7/modules/postgresql_module.xml /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main/module.xml

%postun
# Cleanup alternatives if uninstall only
# This is run after %post so we do not want to remove if an upgrade
# Don't uninstall the maven alternative, since it is also used by jbosseap and jbossews carts
if [ $1 -eq 0 ]; then
  %if 0%{?rhel}
    alternatives --remove jbossas-7 /opt/jboss-as-%{jbossver}
  %endif

  %if 0%{?fedora}
    alternatives --remove jbossas-7 /usr/share/jboss-as
  %endif
fi

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/versions/7/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4714 from bparees/eap_restore
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 1062894 - Fail to restore the snapshot of a jbosseap-6 app to the
  existing one (bparees@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- fix indentation (bparees@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Merge pull request #4490 from bparees/update_jbossas_schema
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- update to latest schema level and add size based log rotation
  (bparees@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bump up cartridge versions (bparees@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Bug 1055646 - [new relic] JBossAS cart restart fails if kill -TERM is called
  when process has already terminated (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4486 from bparees/maven_args
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Bug 1033673 - Unable to customize MAVEN_OPTS (bparees@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Fix bug 916388: clean jboss* tmp dirs during tidy (pmorie@gmail.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4455 from bparees/ds_reconnect
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051349 - sql db cannot be connected via java datasource after db
  cartridge restart on the first time (bparees@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Merge pull request #4348 from bparees/build_disabled
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4416 from bparees/jboss_startup
  (dmcphers+openshiftbot@redhat.com)
- distinguish between timed out and failed jboss starts (bparees@redhat.com)
- Bug 1028327 - No message about "skip_maven_build marker found .." after git
  push jbosseap-6 and jbossas-7 app with skip_maven_build marker added
  (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- rename jee to java_ee_6 (bparees@redhat.com)



