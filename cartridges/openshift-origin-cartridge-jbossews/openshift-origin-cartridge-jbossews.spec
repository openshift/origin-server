%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews

Summary:       Provides JBossEWS2.0 support
Name:          openshift-origin-cartridge-jbossews
Version: 1.27.4
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
Requires:      lsof
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
