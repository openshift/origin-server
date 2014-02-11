%global cartridgedir %{_libexecdir}/openshift/cartridges/jbossews

Summary:       Provides JBossEWS2.0 support
Name:          openshift-origin-cartridge-jbossews
Version: 1.19.3
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
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-jbossews-1.0
Obsoletes: openshift-origin-cartridge-jbossews-2.0

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
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
