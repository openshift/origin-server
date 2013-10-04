%global cartridgedir %{_libexecdir}/openshift/cartridges/jbosseap
%global jbossver 6.0.1.GA
%global oldjbossver 6.0.0.GA

Summary:       Provides JBossEAP6.0 support
Name:          openshift-origin-cartridge-jbosseap
Version: 2.10.0
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

Obsoletes: openshift-origin-cartridge-jbosseap-6.0

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
* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 2.9.2-1
- Merge pull request #3518 from a13m/bugzilla/989276
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'master' of https://github.com/openshift/origin-server into
  bugzilla/989276 (agrimm@redhat.com)
- Bug 989276 - Check for existence of ROOT.war before attempting to copy it
  (agrimm@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 2.9.1-1
- Card origin_runtime_102 - use secret token for auth_value in JGroups
  (jhonce@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 2.8.5-1
- Bug 1002893 - Added .jdbc to the mysql module name in JBossEAP
  (mfojtik@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 2.8.4-1
- Merge pull request #3595 from mfojtik/bugzilla/1002893
  (dmcphers+openshiftbot@redhat.com)
- Bug 1002893 - Updated jbosseap cartridge to support mysql-connector
  (mfojtik@redhat.com)
- Bug 1005281 - EAP cartridge maps to specific EAP release
  (bleanhar@redhat.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 2.8.3-1
- Merge pull request #3569 from brenton/BZ1005281
  (dmcphers+openshiftbot@redhat.com)
- Bug 1005281 - EAP cartridge maps to specific EAP release
  (bleanhar@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 2.8.2-1
- Bug 1004927: Don't override JAVA_HOME in standalone.conf
  (ironcladlou@gmail.com)
- Fix bug 1004899: remove legacy subscribes from manifests (pmorie@gmail.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 2.8.1-1
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 2.7.7-1
- Merge pull request #3456 from tdawson/tdawson/fixmirrorfix/2013-08
  (admiller@redhat.com)
- change mirror.openshift.com to mirror1.ops.rhcloud.com for aws mirroring
  (tdawson@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 2.7.6-1
- Merge pull request #3455 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 2.7.5-1
- Merge pull request #3444 from dobbymoodge/fix_cart_names_card219
  (dmcphers+openshiftbot@redhat.com)
- <cartridge versions> origin_runtime_219, Fix up Display-Name: field in
  manifests https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-
  versions (jolamb@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 2.7.4-1
- fix old mirror url (tdawson@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 2.7.3-1
- Merge pull request #3279 from detiber/clientresult
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- <JBoss Cartridges> - Move deployment verification to client_result
  (jdetiber@redhat.com)
- <cart version> origin_runtime_219, Update carts and manifests with new
  versions, handle version change in upgrade code
  https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-versions
  (jolamb@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 2.7.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 2.7.1-1
- Cartridge - Clean up manifests (jhonce@redhat.com)
- Card origin_runtime_148 - append JAVA_OPT_EXT to JAVA_OPT (jhonce@redhat.com)
- Merge pull request #3302 from detiber/fixJBawsTests
  (dmcphers+openshiftbot@redhat.com)
- Fix runtime extended tests (jdetiber@redhat.com)
- Merge pull request #3300 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3021 from rvianello/readme_cron (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Update JBoss cartridges control script (jdetiber@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)
- added a note about the required cron cartridge. (riccardo.vianello@gmail.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 2.6.5-1
- Merge pull request #3244 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 975792 (dmcphers@redhat.com)
- Merge pull request #3235 from detiber/noExplodedWars
  (dmcphers+openshiftbot@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)
- Revert back to not deploying exploded wars by default in JBoss cartridges
  (jdetiber@redhat.com)
- Merge pull request #3055 from Miciah/update-CART_DIR-in-standalone.conf
  (dmcphers+openshiftbot@redhat.com)
- Use OPENSHIFT_*_DIR in standalone.conf (miciah.masters@gmail.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 2.6.4-1
- Bug 982738 (dmcphers@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 2.6.3-1
- JBoss Deployment verification (jdetiber@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 2.6.2-1
- <application.rb> Add feature to carts to handle wildcard ENV variable
  subscriptions (jolamb@redhat.com)
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 2.6.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 2.5.4-1
- Bug 980321: Sync repo dir with live deployments dir on initial install
  (ironcladlou@gmail.com)
- Bug 980487: Add jboss-cli.sh to the jboss* cartridges (ironcladlou@gmail.com)

* Tue Jul 09 2013 Adam Miller <admiller@redhat.com> 2.5.3-1
- Explicitly specify ERB files to process in jboss cartridges
  (ironcladlou@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 2.5.2-1
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 2.5.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 24 2013 Adam Miller <admiller@redhat.com> 2.4.7-1
- Bug 975794: Move oo-admin-cartridge operations to %%posttrans
  (ironcladlou@gmail.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 2.4.6-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 2.4.5-1
- Bug 975708: Fix java7 marker regression (ironcladlou@gmail.com)
- Merge pull request #2904 from ironcladlou/bz/975794
  (dmcphers+openshiftbot@redhat.com)
- Bug 975794: Use install to create volatile environment variables
  (ironcladlou@gmail.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 2.4.4-1
- Bug 975708: Fix jboss java7 marker regression (ironcladlou@gmail.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 2.4.3-1
- Merge pull request #2881 from ironcladlou/bz/972979
  (dmcphers+openshiftbot@redhat.com)
- Bug 972979: Don't include ROOT.war in initial Git repository
  (ironcladlou@gmail.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 2.4.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Bug 973825 (dmcphers@redhat.com)
- add APP_UUID to process (bdecoste@gmail.com)
- Use -z with quotes (dmcphers@redhat.com)
- Bug 971106: Fix skip_maven_build marker support (ironcladlou@gmail.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)
- Bug 969321: Fix jboss thread dump log file path message
  (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 2.4.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 2.3.8-1
- Merge pull request #2672 from pmorie/bugs/968343
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 968343 (pmorie@gmail.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 2.3.7-1
- Bug 968279: Fix jboss[as|eap] java7 marker detection (ironcladlou@gmail.com)
- Merge pull request #2655 from ironcladlou/bz/967532
  (dmcphers+openshiftbot@redhat.com)
- Bug 967532: Fix initial ROOT.war deployment for jboss cartridges
  (ironcladlou@gmail.com)
- Bug 966876 - Fix AVC denial in jbossas7 and jbosseap6 carts on startup
  (jdetiber@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 2.3.6-1
- Bug 966065: Make python-2.6 install script executable (ironcladlou@gmail.com)
- Merge pull request #2604 from ironcladlou/bz/966255
  (dmcphers+openshiftbot@redhat.com)
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 2.3.5-1
- Merge pull request #2593 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Fixing perms (dmcphers@redhat.com)
- fixing perms (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 2.3.4-1
- Bug 962662 (dmcphers@redhat.com)
- Merge pull request #2560 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- add generic-java hook (bdecoste@gmail.com)
- Merge pull request #2554 from pmorie/bugs/964348
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)
- Merge pull request #2550 from ironcladlou/bz/965012
  (dmcphers+openshiftbot@redhat.com)
- Bug 965012: Generate initial ROOT.war dynamically on install for jboss
  cartridges (ironcladlou@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 2.3.3-1
- spec file cleanup (tdawson@redhat.com)
- Make jboss cluster variables cartridge-scoped (ironcladlou@gmail.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 2.3.2-1
- process-version -> update-configuration (dmcphers@redhat.com)
- Bug 963156 (dmcphers@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- messaging_scheduled_thread_pool_max_size=5 (bdecoste@gmail.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- fix module path (bdecoste@gmail.com)
- Merge pull request #2411 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- fix clustering for non-scaled AS/EAP (bdecoste@gmail.com)

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


