%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/python
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/python

Name: openshift-origin-cartridge-python
Version: 0.3.0
Release: 1%{?dist}
Summary: Python cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://www.openshift.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      python
Requires:      mod_wsgi >= 3.2
Requires:      mod_wsgi < 3.4
Requires:      httpd < 2.4
Requires:      MySQL-python
Requires:      pymongo
Requires:      pymongo-gridfs
Requires:      python-psycopg2
Requires:      python-virtualenv
Requires:      python-magic
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
BuildRequires: git
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Python cartridge for OpenShift. (Cartridge Format V2)


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/


%clean
rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/python

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/hooks
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
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
