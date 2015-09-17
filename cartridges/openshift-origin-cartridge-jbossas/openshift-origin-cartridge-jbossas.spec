%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossas
%global jbossver 7.1.1.Final
%global oldjbossver 7.1.0.Final

Summary:       Provides JBossAS7 support
Name:          openshift-origin-cartridge-jbossas
Version: 1.34.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      java-1.6.0-openjdk
Requires:      java-1.6.0-openjdk-devel
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
Requires:      jboss-as7-modules >= %{jbossver}
Requires:      bc
Requires:      jboss-openshift-metrics-module
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

# link in the metrics module
mkdir -p /etc/alternatives/jbossas-7/modules/com/openshift
ln -fs /usr/share/openshift/jboss/modules/com/openshift/metrics /etc/alternatives/jbossas-7/modules/com/openshift/metrics

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
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Thu Sep 17 2015 Unknown name 1.34.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.33.4-1
- Add java-1.6.0-openjdk requirment to jboss cartridges (tiwillia@redhat.com)

* Thu Aug 20 2015 Wesley Hearn <whearn@redhat.com> 1.33.3-1
- Bumping cartridge versions (abhgupta@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.33.2-1
- updating java cartridges to include the java8 marker and JDK8 path
  (cdaley@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.33.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Wed Jul 01 2015 Wesley Hearn <whearn@redhat.com> 1.32.3-1
- Bump cartridge versions for Sprint 64 (j.hadvig@gmail.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.32.2-1
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bump cartridge versions for Sprint 58 (maszulik@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- updating links for developer resources in initial pages for cartridges
  (cdaley@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.30.3-1
- Bumping cartridge versions (j.hadvig@gmail.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.30.2-1
- Bug 1180399: Build fails if the default settings.xml is missing
  (j.hadvig@gmail.com)
- BUG 1176970: Delete all dependencies except settings.xml (j.hadvig@gmail.com)
- Bug 1175489: Wrong grep regexp in jbossews (j.hadvig@gmail.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Merge pull request #5949 from VojtechVitek/upgrade_scrips
  (dmcphers+openshiftbot@redhat.com)
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Bug 1147946 - Do not snapshot jboss*/standalone/tmp (jhonce@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Bug 1145123 - Updated jbossas manifest description (mfojtik@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Fix websockets in jbossas cartridge (agoldste@redhat.com)
- Corrected jboss issues WRT lsof (mmcgrath@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.26.4-1
- Merge pull request #5673 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- bump cart versions for sprint 48 (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- JVM heap optimization settings and remove SerialGC (bvarga@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.6-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 1.24.5-1
- Update JBoss cart specs for new metrics location (agoldste@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Fix JBoss installation issue (metrics) (andy.goldstein@gmail.com)

* Tue Apr 29 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- JBoss metrics module (andy.goldstein@gmail.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- Bug 1083663 - Provide better message when upgrade-node is used on a rerun
  (dmcphers@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Use consistent log format across jboss carts (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Remove unused teardowns (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4864 from bparees/jb_cleanup
  (dmcphers+openshiftbot@redhat.com)
- minor cleanup of jboss config scripts (bparees@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Template cleanup (dmcphers@redhat.com)
- Merge pull request #4825 from bparees/jboss_config
  (dmcphers+openshiftbot@redhat.com)
- allow users to prevent overwrite of local jboss config from repository
  (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- change mirror1.ops to mirror.ops, which is load balanced between servers
  (tdawson@redhat.com)
- add retry logic for deployment scan check (bparees@redhat.com)
- Merge pull request #4787 from developercorey/fix_mysql_ds
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)
- updatin MysqlDS to be MySQLDS to fall in line with ExampleDS and PostgreSQLDS
  data source names (cdaley@redhat.com)

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



