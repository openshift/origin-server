%global cartridgedir %{_libexecdir}/openshift/cartridges/python

Name:          openshift-origin-cartridge-python
Version: 0.8.2
Release:       1%{?dist}
Summary:       Python cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      python >= 2.6
Requires:      python < 2.7
Requires:      scl-utils
BuildRequires: scl-utils-build
#FIXME: Use %scl_require macro to properly define dependencies
Requires:      python27
Requires:      mod_wsgi >= 3.2
Requires:      mod_wsgi < 3.4
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 19
Requires:      python >= 2.7
Requires:      python < 2.8
Requires:      mod_wsgi >= 3.4
Requires:      mod_wsgi < 3.5
Requires:      httpd > 2.3
Requires:      httpd < 2.5
%endif

Requires:      MySQL-python
Requires:      pymongo
Requires:      pymongo-gridfs
Requires:      python-psycopg2
Requires:      python-virtualenv
Requires:      python-magic
%if 0%{?fedora}%{?rhel} <= 6
Requires:      python27-MySQL-python
Requires:      python27-python-psycopg2
%endif
Requires:      libjpeg
Requires:      libjpeg-devel
Requires:      libcurl
Requires:      libcurl-devel
Requires:      numpy
Requires:      numpy-f2py
Requires:      gcc-gfortran
Requires:      freetype-devel
Requires:      atlas-devel
Requires:      lapack-devel
Requires:      redhat-lsb-core

Obsoletes: openshift-origin-cartridge-community-python-2.7
Obsoletes: openshift-origin-cartridge-community-python-3.3
Obsoletes: openshift-origin-cartridge-python-2.6

BuildArch:     noarch

%description
Python cartridge for OpenShift. (Cartridge Format V2)


%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/versions/native %{buildroot}%{cartridgedir}/versions/2.6
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
%__mv %{buildroot}%{cartridgedir}/versions/native %{buildroot}%{cartridgedir}/versions/2.7
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%if 0%{?fedora}%{?rhel} <= 6
%attr(0755,-,-) %{cartridgedir}/versions/2.6/bin/
%endif
%attr(0755,-,-) %{cartridgedir}/versions/shared/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- Merge pull request #3021 from rvianello/readme_cron (dmcphers@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)
- added a note about the required cron cartridge. (riccardo.vianello@gmail.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.7.6-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.7.5-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.7.4-1
- Bug 982738 (dmcphers@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Bug 968252: Add missing marker docs (ironcladlou@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- <application.rb> Add feature to carts to handle wildcard ENV variable
  subscriptions (jolamb@redhat.com)
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- Merge pull request #2958 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
- Bug 977950 - Copying the v1 descriptions back into the v2 versions of the
  cartridge. (rmillner@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 24 2013 Adam Miller <admiller@redhat.com> 0.5.6-1
- Merge pull request #2921 from jwhonce/wip/cartridge_change_audit
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge - Correct manifest.yml (jhonce@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 0.5.5-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 0.5.4-1
- Bug 975700 - check the httpd pid file for corruption and attempt to fix it.
  (rmillner@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Merge pull request #2889 from mrunalp/bugs/pymig
  (dmcphers+openshiftbot@redhat.com)
- Specify python migrations as compatible. (mrunalp@gmail.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Pass the python binary to virtualenv. (mrunalp@gmail.com)
- Add version check around DefaultRuntimeDir directive as it is available only
  on apache 2.4+ (kraman@gmail.com)
- Update python cartridge for F19 version (kraman@gmail.com)
- Fix stop for httpd-based carts. (mrunalp@gmail.com)
- WIP Cartridge Refactor - Fix setups to be reentrant (jhonce@redhat.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.7-1
- Bug 968882 - Fix MIMEMagicFile (jhonce@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- Add cherrypy to python 3.3 template. (mrunalp@gmail.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Bug 966065: Make python-2.6 install script executable (ironcladlou@gmail.com)
- Merge pull request #2613 from mrunalp/bugs/965960
  (dmcphers+openshiftbot@redhat.com)
- Handle rsync exclusions (mrunalp@gmail.com)
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Bug 962662 (dmcphers@redhat.com)
- get submodules working in all cases (dmcphers@redhat.com)
- Bug 965537 - Dynamically build PassEnv httpd configuration
  (jhonce@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Include bash sdk in control file. (mrunalp@gmail.com)
- Merge pull request #2503 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2492 from mrunalp/dev/pybugs
  (dmcphers+openshiftbot@redhat.com)
- process-version -> update-configuration (dmcphers@redhat.com)
- Bug 963156 (dmcphers@redhat.com)
- Move env var creation to correct install file. (mrunalp@gmail.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Merge pull request #2442 from mrunalp/bugs/python_status
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- Fix python control status. (mrunalp@gmail.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- Python migration WIP. (mrunalp@gmail.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- fix missing target for cp (rchopra@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Card online_runtime_266 - Support for LD_LIBRARY_PATH (jhonce@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2192 from mrunalp/bugs/952660
  (dmcphers+openshiftbot@redhat.com)
- Add jenkins support for 2.7/3.3 (mrunalp@gmail.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.9-1
- Merge pull request #2090 from mrunalp/dev/python_cleanup
  (dmcphers@redhat.com)
- Cleanup python cart. (mrunalp@gmail.com)
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 0.2.8-1
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2060 from mrunalp/bug/py_clean_template
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Cleanup template action_hooks directory. (mrunalp@gmail.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)
- Merge pull request #2043 from mrunalp/dev/pyfixes (dmcphers@redhat.com)
- Add Version Overrides for python cartridge manifest. (mrunalp@gmail.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- Merge pull request #2032 from mrunalp/bugs/927761 (dmcphers@redhat.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Bug 927761: Add tidy for python cart all verison. (mrunalp@gmail.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Merge pull request #2001 from brenton/misc2 (dmcphers@redhat.com)
- Merge pull request #1994 from mrunalp/dev/py33
  (dmcphers+openshiftbot@redhat.com)
- Calling oo-admin-cartridge from a few more v2 cartridges
  (bleanhar@redhat.com)
- Add Python 3.3 support. (mrunalp@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Fixes for build/deploy. (mrunalp@gmail.com)
- WIP (mrunalp@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- Python v2 fixes. (mrunalp@gmail.com)
- adding all the jenkins jobs (dmcphers@redhat.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)
- Add connection hooks. (mrunalp@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- Merge pull request #1834 from mrunalp/bugs/928282
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1829 from mrunalp/bugs/928281
  (dmcphers+openshiftbot@redhat.com)
- BZ928282: Copy over hidden files under template. (mrunalp@gmail.com)
- BZ928281: Fix python logs. (mrunalp@gmail.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- Add ATLAS devel libs to bring up a newer version of numpy.
  (rmillner@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Fixes to get python cart work with rhc app create. (mrunalp@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- Fix cart names to exclude versions. (mrunalp@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Tue Mar 12 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Fixing tags on master 

* Fri Mar 08 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.1-1
- new package built with tito

* Wed Feb 20 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.0-1
- Initial SPEC created
