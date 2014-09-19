%global cartridgedir %{_libexecdir}/openshift/cartridges/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version: 2.21.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
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
Requires:      bc
Requires:      jboss-openshift-metrics-module
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

# link in the metrics module
mkdir -p /etc/alternatives/jbosseap-6/modules/com/openshift
ln -fs /usr/share/openshift/jboss/modules/com/openshift/metrics /etc/alternatives/jbosseap-6/modules/com/openshift/metrics

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/versions/shared/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 2.21.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 2.20.4-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue Sep 09 2014 Adam Miller <admiller@redhat.com> 2.20.3-1
- Bug 1125430 - jboss-eap6-index is no longer needed (bleanhar@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 2.20.2-1
- Corrected jboss issues WRT lsof (mmcgrath@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 2.20.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 2.19.4-1
- Merge pull request #5673 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- bump cart versions for sprint 48 (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 2.19.3-1
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 2.19.2-1
- JVM heap optimization settings and remove SerialGC (bvarga@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 2.19.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 2.18.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 2.18.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 2.18.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 2.17.6-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 2.17.5-1
- Update JBoss cart specs for new metrics location (agoldste@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 2.17.4-1
- Fix JBoss installation issue (metrics) (andy.goldstein@gmail.com)

* Tue Apr 29 2014 Adam Miller <admiller@redhat.com> 2.17.3-1
- JBoss metrics module (andy.goldstein@gmail.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 2.17.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 2.17.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 2.16.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 2.16.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 2.16.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 2.15.5-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Use consistent log format across jboss carts (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 2.15.4-1
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 2.15.3-1
- Add messaging throughput configuration to EAP (bparees@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 2.15.2-1
- Remove unused teardowns (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 2.15.1-1
- Bug 916758 - Give better message on config failure (dmcphers@redhat.com)
- add xpaas tag to eap cartridge (bparees@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 2.14.4-1
- These jboss packages are _not_ optional for the JBoss cartridge.
  (bleanhar@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 2.14.3-1
- Merge pull request #4864 from bparees/jb_cleanup
  (dmcphers+openshiftbot@redhat.com)
- minor cleanup of jboss config scripts (bparees@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 2.14.2-1
- Bug 1071123 - Fix template symlink (dmcphers@redhat.com)
- Template cleanup (dmcphers@redhat.com)
- Merge pull request #4825 from bparees/jboss_config
  (dmcphers+openshiftbot@redhat.com)
- allow users to prevent overwrite of local jboss config from repository
  (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 2.14.1-1
- change mirror1.ops to mirror.ops, which is load balanced between servers
  (tdawson@redhat.com)
- add retry logic for deployment scan check (bparees@redhat.com)
- Merge pull request #4787 from developercorey/fix_mysql_ds
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)
- updatin MysqlDS to be MySQLDS to fall in line with ExampleDS and PostgreSQLDS
  data source names (cdaley@redhat.com)

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


