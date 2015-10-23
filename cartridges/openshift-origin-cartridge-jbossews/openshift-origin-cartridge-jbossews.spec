%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews

Summary:       Provides JBossEWS2.0 support
Name:          openshift-origin-cartridge-jbossews
Version: 1.35.3
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      bc
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      tomcat6
Requires:      tomcat7
Requires:      java-1.6.0-openjdk
Requires:      java-1.6.0-openjdk-devel
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
%if 0%{?rhel}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      maven
%endif
BuildRequires: jpackage-utils
Provides:      openshift-origin-cartridge-jbossews-1.0 = 2.0.0
Provides:      openshift-origin-cartridge-jbossews-2.0 = 2.0.0
Obsoletes:     openshift-origin-cartridge-jbossews-1.0 <= 1.99.9
Obsoletes:     openshift-origin-cartridge-jbossews-2.0 <= 1.99.9
BuildArch:     noarch

%description
Provides JBossEWS1.0 and JBossEWS2.0 support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

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

alternatives --remove jbossews-1.0 /usr/share/tomcat6
alternatives --install /etc/alternatives/jbossews-1.0 jbossews-1.0 /usr/share/tomcat6 102
alternatives --set jbossews-1.0 /usr/share/tomcat6

alternatives --remove jbossews-2.0 /usr/share/tomcat7
alternatives --install /etc/alternatives/jbossews-2.0 jbossews-2.0 /usr/share/tomcat7 102
alternatives --set jbossews-2.0 /usr/share/tomcat7

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/template
%{cartridgedir}/usr
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.35.3-1
- Bumping cartridge versions (abhgupta@redhat.com)

* Thu Oct 15 2015 Stefanie Forrester <sedgar@redhat.com> 1.35.2-1
- Merge pull request #6266 from sferich888/BZ1270660
  (dmcphers+openshiftbot@redhat.com)
- Implementing a sleep function to mimic the EAP waitfordeployments call
  (sferich888@gmail.com)

* Thu Sep 17 2015 Unknown name 1.35.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.34.4-1
- Add java-1.6.0-openjdk requirment to jboss cartridges (tiwillia@redhat.com)

* Thu Aug 20 2015 Wesley Hearn <whearn@redhat.com> 1.34.3-1
- Bumping cartridge versions (abhgupta@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.34.2-1
- updating java cartridges to include the java8 marker and JDK8 path
  (cdaley@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.34.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Wed Jul 01 2015 Wesley Hearn <whearn@redhat.com> 1.33.3-1
- Bump cartridge versions for Sprint 64 (j.hadvig@gmail.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.33.2-1
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.32.3-1
- Bump cartridge versions for Sprint 58 (maszulik@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.32.2-1
- updating links for developer resources in initial pages for cartridges
  (cdaley@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bumping cartridge versions (j.hadvig@gmail.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- Bug 1180399: Build fails if the default settings.xml is missing
  (j.hadvig@gmail.com)
- Merge pull request #6035 from jhadvig/BZ1176970
  (dmcphers+openshiftbot@redhat.com)
- BUG 1176970: Delete all dependencies except settings.xml (j.hadvig@gmail.com)
- Bug 1175489: Updating sed logic and escaping env vars (j.hadvig@gmail.com)
- Bug 1175489: Wrong grep regexp in jbossews (j.hadvig@gmail.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Dec 01 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Unify `-x' shell attribute in cartridge scripts (vvitek@redhat.com)
- Fix jbossews snapshot_exclusions (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Merge pull request #5949 from VojtechVitek/upgrade_scrips
  (dmcphers+openshiftbot@redhat.com)
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1147946 - Do not snapshot jboss*/standalone/tmp (jhonce@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Merge pull request #5748 from jwhonce/wip/proc_net
  (dmcphers+openshiftbot@redhat.com)
- Corrected jboss issues WRT lsof (mmcgrath@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Bump cartridge versions for Sprint 49 (maszulik@redhat.com)

* Tue Aug 19 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Bug 1084427 - Stop JBossEws cartridge gracefully (bvarga@redhat.com)

* Thu Aug 14 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Merge pull request #5683 from soltysh/binary_deploy_tests
  (dmcphers+openshiftbot@redhat.com)
- Reafactored binary deployment tests for running them faster.
  (maszulik@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- always meet control error when restartstop a jbossews scalable app with
  medium or large gear size (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.26.5-1
- Merge pull request #5673 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- bump cart versions for sprint 48 (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.26.4-1
- Merge pull request #5640 from a13m/bz1122166
  (dmcphers+openshiftbot@redhat.com)
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Tue Jul 29 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Bug 1123105 - Fixed binary jbossews binary deployment, currently when no
  config files are specified inside archive, then template's one are taken as
  the default (maszulik@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- JVM heap optimization settings and remove SerialGC (bvarga@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Merge pull request #5374 from shekhargulati/master
  (dmcphers+openshiftbot@redhat.com)
- added Servlet 3 dependency (shekhargulati84@gmail.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.23.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.22.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- fix bad variable reference for version check (bparees@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Incorrect log file name in the output when threaddump jbossews app.
  (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.21.2-1
- Remove unused teardowns (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- remove copy from setup script (bparees@redhat.com)
- move config copy into install/upgrade scripts instead of setup script
  (bparees@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- change mirror1.ops to mirror.ops, which is load balanced between servers
  (tdawson@redhat.com)
- Merge pull request #4787 from developercorey/fix_mysql_ds
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)
- updatin MysqlDS to be MySQLDS to fall in line with ExampleDS and PostgreSQLDS
  data source names (cdaley@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Bug 1061392 - Can't create Java Application using Tomcat7 with existing
  sources (bparees@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Update README.md (dereckson@espace-win.org)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- Merge pull request #4574 from bparees/https
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 1057077 - Propagate https information to Java EE cartridgets(JBoss
  AS/EAP/Tomcat) in standard way (via request.isSecure()) (bparees@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.18.7-1
- Bug 988756 - Adding Requires: bc to jbossews cartridge (bleanhar@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- Bug 974933 - Inconsistent message is shown when rhc threaddump for a scaled
  up app (jhadvig@redhat.com)
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.18.5-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Merge pull request #4420 from bparees/tomcat_build_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Bug 1048294 - Tomcat does not clean work directory when application is
  redeployed (bparees@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4416 from bparees/jboss_startup
  (dmcphers+openshiftbot@redhat.com)
- distinguish between timed out and failed jboss starts (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.18.2-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
