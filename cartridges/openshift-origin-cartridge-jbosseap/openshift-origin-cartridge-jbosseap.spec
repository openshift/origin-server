%global cartridgedir %{_libexecdir}/openshift/cartridges/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version: 2.14.0
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
Requires:      bc
%if 0%{?rhel}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      maven
%endif
BuildRequires: jpackage-utils
Provides:      openshift-origin-cartridge-jbosseap-6.0 = 2.0.0
Obsoletes:     openshift-origin-cartridge-jbosseap-6.0 <= 1.99.9
BuildArch:     noarch

%description
Provides JBossEAP support to OpenShift. (Cartridge Format V2)

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
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven
%endif

alternatives --remove jbosseap-6.0 /usr/share/jbossas
alternatives --remove jbosseap-6 /usr/share/jbossas
alternatives --install /etc/alternatives/jbosseap-6 jbosseap-6 /usr/share/jbossas 102
alternatives --set jbosseap-6 /usr/share/jbossas
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss eap 6.0.* upstream.
mkdir -p /etc/alternatives/jbosseap-6/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbosseap-6/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/versions/shared/modules/postgresql_module.xml /etc/alternatives/jbosseap-6/modules/org/postgresql/jdbc/main/module.xml

# Do the same for the mysql connector.
mkdir -p /etc/alternatives/jbosseap-6/modules/com/mysql/jdbc/main
ln -fs /usr/share/java/mysql-connector-java.jar /etc/alternatives/jbosseap-6/modules/com/mysql/jdbc/main
cp -p %{cartridgedir}/versions/shared/modules/mysql_module.xml /etc/alternatives/jbosseap-6/modules/com/mysql/jdbc/main/module.xml

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/versions/shared/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 2.13.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 2.13.3-1
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

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 2.13.2-1
- Cleaning specs (dmcphers@redhat.com)
- fix indentation (bparees@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 2.13.1-1
- Merge pull request #4574 from bparees/https
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 1057077 - Propagate https information to Java EE cartridgets(JBoss
  AS/EAP/Tomcat) in standard way (via request.isSecure()) (bparees@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 2.12.8-1
- Bug 974933 - Inconsistent message is shown when rhc threaddump for a scaled
  up app (jhadvig@redhat.com)
- Bump up cartridge versions (bparees@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 2.12.7-1
- Bug 1055646 - [new relic] JBossAS cart restart fails if kill -TERM is called
  when process has already terminated (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 2.12.6-1
- Merge pull request #4486 from bparees/maven_args
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Bug 1033673 - Unable to customize MAVEN_OPTS (bparees@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 2.12.5-1
- Merge pull request #4476 from pmorie/bugs/916388
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4422 from bparees/jboss_log_trim
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 916388: clean jboss* tmp dirs during tidy (pmorie@gmail.com)
- switch to size rotating log file handler instead of periodic rotating file
  handler (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 2.12.4-1
- Merge pull request #4455 from bparees/ds_reconnect
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051349 - sql db cannot be connected via java datasource after db
  cartridge restart on the first time (bparees@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 2.12.3-1
- Merge pull request #4348 from bparees/build_disabled
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4416 from bparees/jboss_startup
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4330 from bparees/jboss_62
  (dmcphers+openshiftbot@redhat.com)
- distinguish between timed out and failed jboss starts (bparees@redhat.com)
- update schema to latest jboss eap 6.2 (bparees@redhat.com)
- Bug 1028327 - No message about "skip_maven_build marker found .." after git
  push jbosseap-6 and jbossas-7 app with skip_maven_build marker added
  (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 2.12.2-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- Merge pull request #4408 from bparees/jboss_legacy
  (dmcphers+openshiftbot@redhat.com)
- properly substitute legacy variable to new jbosseap variable name
  (bparees@redhat.com)
- rename jee to java_ee_6 (bparees@redhat.com)


