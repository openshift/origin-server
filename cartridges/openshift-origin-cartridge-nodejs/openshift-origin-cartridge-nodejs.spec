%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/nodejs

Summary:       Provides Node.js support
Name:          openshift-origin-cartridge-nodejs
Version: 1.11.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: nodejs >= 0.6
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      nodejs-async
Requires:      nodejs-connect
Requires:      nodejs-express
Requires:      nodejs-mongodb
Requires:      nodejs-mysql
Requires:      nodejs-node-static
Requires:      nodejs-pg
Requires:      nodejs-supervisor
%if 0%{?fedora} >= 19
Requires:      npm
%endif

BuildArch:     noarch

%description
Provides Node.js support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

echo "NodeJS version is `/usr/bin/node -v`"
if [[ $(/usr/bin/node -v) == v0.6* ]]; then
%__rm -f %{buildroot}%{cartridgedir}/versions/0.10
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.6 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
fi

if [[ $(/usr/bin/node -v) == v0.10* ]]; then
%__rm -f %{buildroot}%{cartridgedir}/versions/0.6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.10 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
fi

%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.10.5-1
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Bug 962662 (dmcphers@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.10.3-1
- Merge pull request #2544 from mrunalp/bugs/nodejs
  (dmcphers+openshiftbot@redhat.com)
- Use correct variable in control script. (mrunalp@gmail.com)
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Bug 963156 (dmcphers@redhat.com)
- status call should echo expected message (asari.ruby@gmail.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- moving templates to usr (dmcphers@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.9.3-1
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- fixing tests (dmcphers@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- implementing install and post-install (dmcphers@redhat.com)
- Merge pull request #2187 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- install and post setup tests (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Merge pull request #2147 from BanzaiMan/dev/hasari/bz87442
  (dmcphers+openshiftbot@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Bug 87442 (asari.ruby@gmail.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.8.8-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.8.6-1
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Add post_deploy hook, too. (asari.ruby@gmail.com)
- Add .openshift to the Node.js cartridge application template, so that it may
  be populated upon creation. (asari.ruby@gmail.com)
- Use $OPENSHIFT_TMP_DIR where applicable. (asari.ruby@gmail.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Further improvements on Node.js v2 cartridge. (asari.ruby@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #1930 from mrunalp/dev/cart_hooks (dmcphers@redhat.com)
- Add hooks for other carts. (mrunalp@gmail.com)
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)

* Fri Apr 05 2013 Dan McPherson <dmcphers@redhat.com> 1.8.1-1
- new package built with tito

* Fri Apr 05 2013 Dan Mace <ironcladlou@gmail.com> 1.8.0-1
- new package built with tito

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 913217 (bdecoste@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Merge pull request #1333 from mrunalp/bugs/908538
  (dmcphers+openshiftbot@redhat.com)
- Bug 908538: Fix for git checkout failing in npm build. (mrunalp@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- 892068 (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fixed scaled app creation Fixed scaled app cartridge addition Updated
  descriptors to set correct group overrides for web_cartridges
  (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Merge pull request #534 from mscherer/fix_desc_nodejs_repo
  (dmcphers+openshiftbot@redhat.com)
- fix the version set in description of a new node js repo
  (mscherer@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1110 from Miciah/silence-pushd-and-popd
  (dmcphers+openshiftbot@redhat.com)
- Fix BZ864797: Add doc for disable_auto_scaling marker (pmorie@gmail.com)
- Consistently silence pushd and popd in hooks (miciah.masters@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- Merge pull request #976 from jwhonce/dev/rm_post-remove
  (openshift+bot@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- BZ 877325: Added websites. (rmillner@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Merge pull request #895 from smarterclayton/us3046_quickstarts_and_app_types
  (openshift+bot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Fix bugz 876130 - Node.js application w/ jenkins enabled does not startup
  supervisor on hot_deploy marker push. (ramr@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Fix for bugz 874634 - handle modules packaged along w/ the app and updates.
  (ramr@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Set npm temp directory at nodejs app configure time. (ramr@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix bugz 873548 - meet npm ERR if trying to install dependency for nodejs
  (ramr@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fix README to use new variable scheme + fixup wrong variable in diy cart.
  (ramr@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
- Remove need of workaround in fix for bugz 869874 - move ~/node_modules to
  ~/.node_modules (ramr@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.14.10-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.14.9-1
- Add support for nodejs hot deployment. (ramr@redhat.com)
- Revert "Documentation updates" - add back node.js hot deployment support
  documention. (ramr@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.14.8-1
- No more deplist -- readme should say package.json (ramr@redhat.com)
- Documentation updates (ironcladlou@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.14.7-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.14.6-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.14.5-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 26 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- Fix for bugz 856275 - support for "local" (user workstation) development and
  test. (ramr@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- BZ858605 (bdecoste@gmail.com)
- US2747 (bdecoste@gmail.com)
- US2747 (bdecoste@gmail.com)
- US2747 (bdecoste@gmail.com)

* Tue Sep 18 2012 William DeCoste <wdecoste@redhat.com> 0.14.2-1
- add nodejs-supervisor
* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- Merge pull request #455 from sg00dwin/master (openshift+bot@redhat.com)
- fix for 839242. css changes only (sgoodwin@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Sep 06 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Fix for bugz 852598 - Local gear of nodejs scalable app is down after
  creating this app. (ramr@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- Implement started/stopped transitions in state file (ironcladlou@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Mon Jul 30 2012 Dan McPherson <dmcphers@redhat.com> 0.11.4-1
- Fix for BZ843394. (mpatel@redhat.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Fix for bugz 840165 - update readmes. (ramr@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Fri Jul 06 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- Fix build failures -- seems like something in npm link output causes broker
  to fail parsing the response. (ramr@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- more cartridges have better metadata (rchopra@redhat.com)
- Fix for bugz 837058 - EACCESS on ~/.node-gyp directory. (ramr@redhat.com)
- Merge pull request #176 from rajatchopra/master (rpenta@redhat.com)
- Fixes for saving node_modules across deployments. (ramr@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.9.2-1
- The single quotes cause CART_INFO_DIR to be embedded rather than its
  expansion. (rmillner@redhat.com)
- Fix issue with node_modules resolution with GEAR_DIR movement. Node.js
  searches up the directory chain for node_modules, since we are now under app-
  root/runtime/repo, this causes issues w/ installed user modules.
  (ramr@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.8.6-1
- Bug 825354 (dmcphers@redhat.com)
- Adding a dependency resolution step (using post-recieve hook) for all
  applications created from templates. Simplifies workflow by not requiring an
  additional git pull/push step Cucumber tests (kraman@gmail.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.8.5-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.8.4-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Fixup from merge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-nodejs-0.6] release [0.8.2-1].
  (admiller@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-nodejs-0.6] release [0.7.4-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.8.3-1
- Add support for package.json - US2135. (ramr@redhat.com)
- Changes to descriptors/specs to execute the new connector.
  (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.8.2-1
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Add sample user pre/post hooks. (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.8.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 09 2012 Adam Miller <admiller@redhat.com> 0.7.5-1
- Bug 820033 (dmcphers@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.7.4-1
- Bug 819739 (dmcphers@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.7.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)
- changed git config within spec files to operate on local repo instead of
  changing global values (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.7.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.7.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.6.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.6.5-1
- new package built with tito
