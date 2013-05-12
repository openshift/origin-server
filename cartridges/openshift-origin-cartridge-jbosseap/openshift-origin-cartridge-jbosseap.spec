%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version: 2.3.1
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
Requires:	   facter
%if 0%{?rhel}
Requires:      maven3
%endif
%if 0%{?fedora}
Requires:      maven
%endif
BuildRequires: jpackage-utils
BuildArch:     noarch

%description
Provides JBossEAP support to OpenShift. (Cartridge Format V2)


%prep
%setup -q


%build
%__rm %{name}.spec


%install
%__rm -rf %{buildroot}
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}


%clean
%__rm -rf %{buildroot}


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
alternatives --install /etc/alternatives/jbosseap-6.0 jbosseap-6.0 /usr/share/jbossas 102
alternatives --set jbosseap-6.0 /usr/share/jbossas
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss eap 6.0.* upstream.
mkdir -p /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/versions/6.0/modules/postgresql_module.xml /etc/alternatives/jbosseap-6.0/modules/org/postgresql/jdbc/main/module.xml

%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 2.3.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)
- Bug 956572 (bdecoste@gmail.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 2.2.7-1
- Bug 960378 960458 (bdecoste@gmail.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 2.2.6-1
- Bug 958606; Bug 959833; Fix standalone.xml env replacement typos
  (ironcladlou@gmail.com)
- Merge pull request #2340 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- fix env / replacement (bdecoste@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 2.2.5-1
- Special file processing (fotios@redhat.com)
- Bug 958669: Fix MySQL var expansion in standalone.xml (ironcladlou@gmail.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 2.2.4-1
- Merge pull request #2303 from ironcladlou/bz/955509
  (dmcphers+openshiftbot@redhat.com)
- Bug 955509: Remove duplicate cart install lines from specfile
  (ironcladlou@gmail.com)
- Card online_runtime_266 - Support for JAVA_HOME (jhonce@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 2.2.3-1
- Merge pull request #2280 from mrunalp/dev/auto_env_vars
  (dmcphers+openshiftbot@redhat.com)
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2275 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2266 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_266 - Renamed OPENSHIFT_<short name>_PATH to
  OPENSHIFT_<short name>_PATH_ELEMENT (jhonce@redhat.com)
- Bug 956050 (bdecoste@gmail.com)
- Bug 956050 (bdecoste@gmail.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 2.2.2-1
- Merge pull request #2258 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 956050 956043 (bdecoste@gmail.com)
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 2.2.1-1
- Bug 956497: Fix port bindings for jboss carts (ironcladlou@gmail.com)
- Card online_runtime_266 - Build PATH from
  CARTRIDGE_<CARTRIDGE_SHORT_NAME>_PATH (jhonce@redhat.com)
- cleanup (bdecoste@gmail.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2191 from jwhonce/wip/raw_envvar
  (dmcphers+openshiftbot@redhat.com)
- Bug 954283 - JBoss standalone.conf sourcing env vars (jhonce@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 952513 (bdecoste@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- Bug 952044 and 952043: JBoss v2 cart tidy fixes (ironcladlou@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

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


