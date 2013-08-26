%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/haproxy

Summary:       Provides HA Proxy
Name:          openshift-origin-cartridge-haproxy
Version: 1.16.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      haproxy
Requires:      socat
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      %{?scl:%scl_prefix}rubygem-rest-client

Obsoletes: openshift-origin-cartridge-haproxy-1.4

BuildArch:     noarch

%description
HAProxy cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Mon Sep 30 2013 Troy Dawson <tdawson@redhat.com> 1.15.6-1
- Merge pull request #3730 from jwhonce/bug/1012812
  (dmcphers+openshiftbot@redhat.com)
- Bug 1012812 - Report error if configuration files are missing
  (jhonce@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.5-1
- Use the Ruby SDK functions in fix_local.sh in haproxy cart
  (mfojtik@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Feature tests for ssl_to_gear, V3 of mock cart serves https at primary
  endpoint on port 8123 (teddythetwig@gmail.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge pull request #3659 from mfojtik/bugzilla/1007455
  (dmcphers+openshiftbot@redhat.com)
- Added OpenShift::Cartridge::Sdk namespace and removed TODO
  (mfojtik@redhat.com)
- Bug 1007455 - Added primary_cartridge methods to Ruby SDK
  (mfojtik@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Bug 980826 (dmcphers@redhat.com)
- Add support for cartridge protocol types in manifest (rchopra@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 0.9.3-1
- Merge pull request #3620 from ironcladlou/dev/cart-version-bumps
  (dmcphers+openshiftbot@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)

* Wed Sep 11 2013 Adam Miller <admiller@redhat.com> 0.9.2-1
- Bug 1006085 (dmcphers@redhat.com)
- Merge pull request #3611 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1006085 (dmcphers@redhat.com)
- Bug 985024: Remove haproxy status page as the backup page.
  (mrunalp@gmail.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.9.1-1
- Bug 1000727 - HAProxy using CLIENT_MESSAGE for status messages
  (jhonce@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.8.6-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 0.8.5-1
- Adjust interval before considering auto scale down (dmcphers@redhat.com)
- HAProxy fixes. (mrunalp@gmail.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 0.8.4-1
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.8.3-1
- Merge pull request #3366 from jwhonce/bug/991362
  (dmcphers+openshiftbot@redhat.com)
- Bug 991362 - remove processing listing from haproxy control#status
  (jhonce@redhat.com)
- Fix calculation. (mrunalp@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- Add support for auto-scaling with multiple haproxies. (mrunalp@gmail.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- only primary haproxy should sync and deploy (rchopra@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.7.6-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 0.7.5-1
- Merge pull request #3214 from mrunalp/bugs/rhc_ext_sca_test
  (dmcphers+openshiftbot@redhat.com)
- Fix. (mrunalp@gmail.com)
- Enable auto-scaling only on head gear. (mrunalp@gmail.com)
- Merge pull request #3207 from mrunalp/bugs/982615
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3205 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3203 from mrunalp/bugs/haproxy_maxconn
  (dmcphers+openshiftbot@redhat.com)
- Use client_message instead of client_result. (mrunalp@gmail.com)
- haproxy should use gear's uuid, and not app's uuid (rchopra@redhat.com)
- Fix for maxconn set to 2 for local gear. (mrunalp@gmail.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.7.4-1
- Bug 982738 (dmcphers@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Merge pull request #2981 from Miciah/haproxy_ctld_daemon.rb-fix-typo-
  backgrace (dmcphers+openshiftbot@redhat.com)
- haproxy_ctld_daemon.rb: Fix backtrace option (miciah.masters@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)
- make haproxy a sparse cart (rchopra@redhat.com)
- Fix log file perms. (mrunalp@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 0.6.4-1
- WIP Cartridge - bump cartridge versions (jhonce@redhat.com)
- Bug 982482 (mrunalp@gmail.com)

* Wed Jul 03 2013 Adam Miller <admiller@redhat.com> 0.6.3-1
- moving sync into the sdk (dmcphers@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- Merge pull request #2958 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
- Bug 977493 - Avoid leaking the lock file descriptor to child processes.
  (rmillner@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 0.5.4-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Bug 974786: Scaled gear hot deploy logic fix (ironcladlou@gmail.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Copy over haproxy.cfg template only if it doesn't exist. (mrunalp@gmail.com)
- origin_runtime_137 - FrontendHttpServer accepts "target_update" option which
  causes it to read the old options for a connection and just update the
  target. (rmillner@redhat.com)
- Merge pull request #2702 from mrunalp/bugs/haproxy_disable_local
  (dmcphers+openshiftbot@redhat.com)
- Disable local gear only after a remote gear is UP or there is a timeout.
  (mrunalp@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.9-1
- Bug 968994: Fix hot deploy during initial scaled gear deployment
  (ironcladlou@gmail.com)
- make sure you are doing math with floats (dmcphers@redhat.com)
- Tuning scale up and down (dmcphers@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 0.4.8-1
- Merge pull request #2655 from ironcladlou/bz/967532
  (dmcphers+openshiftbot@redhat.com)
- Bug 967532: Fix initial ROOT.war deployment for jboss cartridges
  (ironcladlou@gmail.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 0.4.7-1
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- remove install build required for non buildable carts (dmcphers@redhat.com)
- Merge pull request #2622 from mrunalp/bugs/haproxy_validate_config
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2612 from jwhonce/bug/964347
  (dmcphers+openshiftbot@redhat.com)
- fix to call correct script. (mrunalp@gmail.com)
- Bug 964347 - Run cartridge scripts from cartridge home directory
  (jhonce@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Merge pull request #2613 from mrunalp/bugs/965960
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2609 from mrunalp/bugs/haproxy_set_proxy
  (dmcphers+openshiftbot@redhat.com)
- Handle rsync exclusions (mrunalp@gmail.com)
- Fix set proxy to look for first endpoint in the manifest. (mrunalp@gmail.com)
- Merge pull request #2601 from ironcladlou/bz/964002
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2600 from mrunalp/bugs/966068
  (dmcphers+openshiftbot@redhat.com)
- Bug 964002: Support hot deployment in scalable apps (ironcladlou@gmail.com)
- Add force-reload functionality. (mrunalp@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Bug 962662 (dmcphers@redhat.com)
- Reload HAProxy instead of restarting it in hooks. (mrunalp@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- spec file cleanup (tdawson@redhat.com)
- Merge pull request #2522 from mrunalp/dev/haproxy_hook
  (dmcphers+openshiftbot@redhat.com)
- Remove unused hooks. (mrunalp@gmail.com)
- cleanup (dmcphers@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Pass ws connections argument. (mrunalp@gmail.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- <haproxy_ctld.rb> Bug 962714 - Fix p_usage method to exit immediately
  (jolamb@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Add full paths to add-gear/remove-gear scripts. (mrunalp@gmail.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Switching v2 to be the default (dmcphers@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- Special file processing (fotios@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Add init option to remote deploy. (mrunalp@gmail.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Merge pull request #2275 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_266 - Renamed OPENSHIFT_<short name>_PATH to
  OPENSHIFT_<short name>_PATH_ELEMENT (jhonce@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2248 from mrunalp/bug/haproxy_fixes
  (dmcphers+openshiftbot@redhat.com)
- Move haproxy shared scripts into /usr/bin. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Card online_runtime_266 - Build PATH from
  CARTRIDGE_<CARTRIDGE_SHORT_NAME>_PATH (jhonce@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2194 from mrunalp/dev/haproxy_cleanup
  (dmcphers+openshiftbot@redhat.com)
- HAProxy cleanup. (mrunalp@gmail.com)
- implementing install and post-install (dmcphers@redhat.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-haproxy] release
  [0.2.10-1]. (tdawson@redhat.com)
- Fix bug 927850 (pmorie@gmail.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.10-1
- Fix bug 927850 (pmorie@gmail.com)

* Sun Apr 14 2013 Dan McPherson <dmcphers@redhat.com> 0.2.9-1
- 

* Sun Apr 14 2013 Dan McPherson <dmcphers@redhat.com> 0.2.8-1
- 

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.6-1
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Generate ssh key for web proxy cartridges (pmorie@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Fix haproxy v2 path construction (ironcladlou@gmail.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- HAProxy deploy wip. (mrunalp@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- new package built with tito

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com>
- new package built with tito

* Tue Mar 26 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

