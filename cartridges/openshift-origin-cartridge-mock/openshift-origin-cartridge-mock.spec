%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mock
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mock

Name: openshift-origin-cartridge-mock
Version: 0.3.5
Release: 1%{?dist}
Summary: Mock cartridge for V2 Cartridge SDK
Group: Development/Languages
License: ASL 2.0
URL: https://www.openshift.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util

%description
Provides a mock cartridge for use in the V2 Cartridge SDK. Used to integration
test platform functionality. (Cartridge Format V2)


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}/.openshift
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
cp .mock_hidden.erb %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}


%clean
rm -rf %{buildroot}


%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/mock

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/hooks
%dir %{cartridgedir}/conf
%dir %{cartridgedir}/conf.d
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/usr
%dir %{cartridgedir}/template
%dir %{cartridgedir}/.openshift
%config(noreplace) %{cartridgedir}/conf/
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%{cartridgedir}/.mock_hidden.erb
%doc %{cartridgedir}/README.md
%config(noreplace) %{cartridgedir}/mock.conf


%changelog
* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Merge pull request #2275 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_266 - Renamed OPENSHIFT_<short name>_PATH to
  OPENSHIFT_<short name>_PATH_ELEMENT (jhonce@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Add process-version control action (ironcladlou@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2247 from pmorie/dev/mockname
  (dmcphers+openshiftbot@redhat.com)
- Fix mock-0.2 display name (pmorie@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Card online_runtime_266 - Build PATH from
  CARTRIDGE_<CARTRIDGE_SHORT_NAME>_PATH (jhonce@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- install and post setup tests (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.8-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.6-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Fix cart-scoped action hook executions (ironcladlou@gmail.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Merge pull request #2015 from ironcladlou/dev/v2carts/build-system
  (dmcphers@redhat.com)
- Generate ssh key for web proxy cartridges (pmorie@gmail.com)
- Call cart pre-receive hook during default build lifecycle
  (ironcladlou@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1984 from jwhonce/wip/v2_cart_model (dmcphers@redhat.com)
- Merge pull request #1979 from pmorie/dev/snapshot_cuke
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Fix for processing dot file ERB's
  (jhonce@redhat.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Add core platform test for v2 snapshot/restore (pmorie@gmail.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Refactor mock and mock-plugin connection hooks (pmorie@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- Improve mock/mock-plugin cartridges (ironcladlou@gmail.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- Merge pull request #1809 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Bug 927614: Fix action hook execution during v2 control ops
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Refactor V2 connector_execute to use V1 contract
  (jhonce@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- WIP Cartridge Refactor - Add support for connection hooks (jhonce@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- WIP Cartridge Refactor -- restore --version to setup calls
  (jhonce@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- WIP Cartridge Refactor - Mung cartridge-vendor omit spaces and downcase
  (jhonce@redhat.com)
- Merge pull request #1683 from jwhonce/wip/mock_updated (dmcphers@redhat.com)
- V2 cucumber test refactor (ironcladlou@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- WIP Cartridge Refactor - Mock plugin installed from CartridgeRepository
  (jhonce@redhat.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1622 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1604 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 0.0.6-1
- Add simple v2 app builds (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 0.0.5-2
- fix version and tag for build (admiller@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 0.0.5-1
- WIP Cartridge Refactor (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com>
- WIP Cartridge Refactor (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 13 2013 Dan McPherson <dmcphers@redhat.com> 0.0.4-1
- 

* Wed Feb 13 2013 Dan McPherson <dmcphers@redhat.com> 0.0.3-1
- new package built with tito

* Fri Feb 01 2013 Paul Morie <pmorie@gmail.com> 0.0.2-1
- Re-version mock RPM to 0.0.1 (pmorie@gmail.com)
- wip (pmorie@gmail.com)

* Fri Feb 01 2013 Paul Morie <pmorie@gmail.com> 0.4-1
- 

* Fri Feb 01 2013 Paul Morie <pmorie@gmail.com> 0.3-1
- wip: mock readme (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-mock] release
  [0.2-1]. (pmorie@gmail.com)
- wip: mock cart rpm (pmorie@gmail.com)
- wip: mock cartridge spec (pmorie@gmail.com)
- wip: rename mock cart (pmorie@gmail.com)

* Thu Jan 31 2013 Paul Morie <pmorie@gmail.com> 0.2-1
- new package built with tito

