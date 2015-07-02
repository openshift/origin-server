# RHEL has 0.6 and 0.10. but 0.10 has a prefix for SCL
# Fedora 18 and 19 has 0.10 as the default
%if 0%{?fedora}%{?rhel} <= 6
  %global scl nodejs010
  %global scl_prefix nodejs010-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/nodejs

Summary:       Provides Node.js support
Name:          openshift-origin-cartridge-nodejs
Version: 1.33.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      %{scl}
%endif
Requires:      %{?scl:%scl_prefix}npm
Requires:      %{?scl:%scl_prefix}nodejs-pg
Requires:      %{?scl:%scl_prefix}nodejs-options
Requires:      %{?scl:%scl_prefix}nodejs-supervisor
Requires:      %{?scl:%scl_prefix}nodejs-async
Requires:      %{?scl:%scl_prefix}nodejs-express
Requires:      %{?scl:%scl_prefix}nodejs-connect
Requires:      %{?scl:%scl_prefix}nodejs-mongodb
Requires:      %{?scl:%scl_prefix}nodejs-mysql
Requires:      %{?scl:%scl_prefix}nodejs-node-static
Requires:      nodejs
Requires:      nodejs-async
Requires:      nodejs-connect
Requires:      nodejs-express
Requires:      nodejs-mongodb
Requires:      nodejs-mysql
Requires:      nodejs-node-static
Requires:      nodejs-pg
Requires:      nodejs-supervisor
Requires:      nodejs-options
Provides:      openshift-origin-cartridge-nodejs-0.6 = 2.0.0
Obsoletes:     openshift-origin-cartridge-nodejs-0.6 <= 1.99.9
BuildArch:     noarch

%description
Provides Node.js support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec
%__rm logs/.gitkeep
find versions/ -name .gitignore -delete
find versions/ -name .gitkeep -delete

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/env
%{cartridgedir}/lib
%{cartridgedir}/logs
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.33.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Wed Jul 01 2015 Wesley Hearn <whearn@redhat.com> 1.32.3-1
- Bump cartridge versions for Sprint 64 (j.hadvig@gmail.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.32.2-1
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)
- Merge pull request #6144 from Miciah/delete-bogus-nodejs_context-invocation
  (dmcphers+openshiftbot@redhat.com)
- Delete bogus nodejs_context invocation (miciah.masters@gmail.com)
- Bug 1221836 - Add check if the HTTP port is open for nodejs cartridge
  (mfojtik@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bump cartridge versions for Sprint 58 (maszulik@redhat.com)

* Fri Feb 20 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- updating links for developer resources in initial pages for cartridges
  (cdaley@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Bump cartridge versions for Sprint 49 (maszulik@redhat.com)

* Thu Aug 14 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1128717 - set production as a default node environment
  (maszulik@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.28.5-1
- Merge pull request #5584 from jhadvig/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Bump cartridge versions for 2.0.47 (jhadvig@gmail.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.28.4-1
- Edit nodejs upgrade script for latest version (jhadvig@redhat.com)

* Mon Jul 07 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Card origin_cartridge_224 - Upgrading nodejs quickstarts to version 0.10
  (maszulik@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- multiple nodejs processes running in a gear (bparees@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- Merge pull request #5419 from ryanj/npm-globals
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 47 (admiller@redhat.com)
- Include npm CLI scripts in the user's PATH -
  https://trello.com/c/eTwC7UbD/174-support-for-javascript-cli-build-tools-
  from-npm (ryan.jarvinen@gmail.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Bug 1111314 - Remove mysql-server dependency from nodejs cartridge
  (jdetiber@redhat.com)
- Merge pull request #5491 from mfojtik/fix-nodejs-update
  (dmcphers+openshiftbot@redhat.com)
- Bug 1104922 - Bump the nodejs cartridge version to trigger update
  (mfojtik@redhat.com)

* Wed Jun 18 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Fix bug 1108951: correct nodejs update-configuration function
  (pmorie@gmail.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Merge pull request #5480 from mfojtik/nodejs_scl
  (dmcphers+openshiftbot@redhat.com)
- Bug 1104922 - Add v8314 collection list of enabled SCL for nodejs cart
  (mfojtik@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.25.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.24.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.24.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Make nodejs watch just a single file by default instead of REPO_DIR
  (mfojtik@redhat.com)
- Removing f19 logic (dmcphers@redhat.com)
- Bug 1073413 - Fix versions in nodejs upgrade script (mfojtik@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- fix bash regexp in upgrade scripts (vvitek@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #4847 from mfojtik/bugzilla/1071165
  (dmcphers+openshiftbot@redhat.com)
- Bug 1071165 - npm no longer supports its self-signed certificates
  (mfojtik@redhat.com)
- Update nodejs cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 1065506 - Increase OPENSHIFT_NODEJS_POLL_INTERVAL default value to 10000
  (mfojtik@redhat.com)
- Bug 1065681 - Allows users to specify what folder/files supervisor will watch
  (mfojtik@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4707 from danmcp/master (dmcphers@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 888714 - Remove gitkeep files from rpms (dmcphers@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Bug 1059374 - Sanitize supervisor_bin/node_bin before pkill
  (mfojtik@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Bug 1059142 - Fix 'cartridge_bin' command in nodejs control script
  (mfojtik@redhat.com)
- Store cartridge_pid in bash variable (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1059374 - Sanity check pkill in nodejs control script
  (mfojtik@redhat.com)
- Bug 1059144 - Refactored nodejs control script (mfojtik@redhat.com)
- Merge pull request #4593 from mfojtik/card/89
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_89 - Make npm optional and restrict hot_deploy to
  supervisor only (mfojtik@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.20.6-1
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Bug 1048756 - 503 Service Temporarily Unavailable met when accessing after
  deploying pacman for nodejs-0.6/0.10 app (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.20.3-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
