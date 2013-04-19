%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jbosseap
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version: 2.2.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
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
Requires:      jboss-eap6-index
Requires:      lsof
Requires:      java-1.7.0-openjdk
Requires:      java-1.7.0-openjdk-devel
%if 0%{?rhel}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      maven
%endif
BuildRequires: git
BuildRequires: jpackage-utils
BuildArch:     noarch

%description
Provides JBossEAP support to OpenShift


%prep
%setup -q


%build


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jbosseap

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
alternatives --install /etc/alternatives/jbosseap-6.0 jbosseap-6.0 /usr/share/jbossas 102
alternatives --set jbosseap-6.0 /usr/share/jbossas
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss eap 6.0.* upstream.
mkdir -p /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/versions/6.0/modules/postgresql_module.xml /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main/module.xml

%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jbosseap


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
* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 2.1.8-1
- Merge pull request #2088 from calfonso/master (dmcphers@redhat.com)
- Merge pull request #2076 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)
- Bug 928701 (bdecoste@gmail.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 2.1.7-1
- V2 action hook cleanup (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 2.1.6-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Merge pull request #2011 from bdecoste/master (dmcphers@redhat.com)
- be able to remove .openshift (bdecoste@gmail.com)
- install cart from spec (bdecoste@gmail.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 2.1.5-1
- Merge pull request #2008 from bdecoste/master (dmcphers@redhat.com)
- as7 v2 cart and eap clustering (bdecoste@gmail.com)
- eapv2 clustering (bdecoste@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 2.1.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 2.1.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1956 from mrunalp/bugs/949273 (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Bug 949273: Fix the manifest. (mrunalp@gmail.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 2.1.2-1
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- Bug 883944 (bdecoste@gmail.com)
- hot_deploy (bdecoste@gmail.com)
- update rsync (bdecoste@gmail.com)
- update jbosseap cart2 (bdecoste@gmail.com)
- link log dir (bdecoste@gmail.com)
- Bug 947016 (bdecoste@gmail.com)
- adding all the jenkins jobs (dmcphers@redhat.com)
- adding jenkins artifacts glob (dmcphers@redhat.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)
- Merge pull request #1842 from bdecoste/master (dmcphers@redhat.com)
- rsync deployments (bdecoste@gmail.com)
- rsync deployments (bdecoste@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 2.1.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 2.0.8-1
- Merge pull request #1830 from bdecoste/master (dmcphers@redhat.com)
- Bug 927555 (bdecoste@gmail.com)
- Merge pull request #1822 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 928142 (bdecoste@gmail.com)
- Merge pull request #1819 from bdecoste/master (dmcphers@redhat.com)
- Bug 927555 (bdecoste@gmail.com)
- Merge pull request #1805 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 927618 (bdecoste@gmail.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 2.0.7-1
- Merge pull request #1791 from bdecoste/master (dmcphers@redhat.com)
- update killtree (bdecoste@gmail.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 2.0.6-1
- Add provider data to the UI that is exposed by the server
  (ccoleman@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 2.0.5-1
- Merge pull request #1748 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 920375 (bdecoste@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 2.0.4-1
- updated jbosseap cart (bdecoste@gmail.com)
- fix postgresql module for jbosseap (bdecoste@gmail.com)
- v2 cart cleanup (bdecoste@gmail.com)
- V2 manifest fixes (ironcladlou@gmail.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 2.0.3-1
- Merge pull request #1655 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- remove java-devel BuildRequires, move ROOT.war jar to configure
  (bdecoste@gmail.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 2.0.2-1
- fix eap spec file versions (bdecoste@gmail.com)
- Merge pull request #1644 from ironcladlou/dev/v2carts/endpoint-refactor
  (dmcphers@redhat.com)
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 2.0.1-1
- Fixing tito tags on master

* Wed Mar 13 2013 Bill DeCoste <bdecoste@gmail.com> 2.0.1-1
- new package built with tito


