%global cartridgedir %{_libexecdir}/openshift/cartridges/mock-plugin

Summary:       Mock plugin cartridge for V2 Cartridge SDK
Name:          openshift-origin-cartridge-mock-plugin
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides a mock plugin cartridge for use in the V2 Cartridge SDK. Used for integration
test platform functionality.

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
* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- Merge pull request #3479 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - restore mock and mock-plugin cartridge versions
  (jhonce@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Bug 962662 (dmcphers@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- spec file cleanup (tdawson@redhat.com)
- Merge pull request #2520 from jwhonce/wip/rm_post_setup
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - remove post-setup support (jhonce@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Fix bug 958977 (pmorie@gmail.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Switching v2 to be the default (dmcphers@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Special file processing (fotios@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- install and post setup tests (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.6-1
- WIP: scalable snapshot/restore (pmorie@gmail.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Refactor mock and mock-plugin connection hooks (pmorie@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- Improve mock/mock-plugin cartridges (ironcladlou@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- WIP Cartridge Refactor - Mung cartridge-vendor omit spaces and downcase
  (jhonce@redhat.com)
- Merge pull request #1683 from jwhonce/wip/mock_updated (dmcphers@redhat.com)
- WIP Cartridge Refactor - cucumber test refactor (jhonce@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- WIP Cartridge Refactor - Mock plugin installed from CartridgeRepository
  (jhonce@redhat.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 0.0.7-2
- fixing tags, will bring in lost changelog later

* Wed Feb 27 2013 Dan Mace <ironcladlou@gmail.com> 0.0.7-1
- Automatic commit of package [openshift-origin-cartridge-mock-plugin] release
  [0.0.6-1]. (ironcladlou@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-mock-plugin] release
  [0.0.5-1]. (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Dan Mace <ironcladlou@gmail.com> 0.0.6-1
- new package built with tito

* Tue Feb 19 2013 Paul Morie <pmorie@gmail.com> 0.0.5-1
- new package built with tito

