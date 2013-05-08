%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mock-plugin
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mock-plugin

Name: openshift-origin-cartridge-mock-plugin
Version: 0.4.1
Release: 1%{?dist}
Summary: Mock plugin cartridge for V2 Cartridge SDK
Group: Development/Languages
License: ASL 2.0
URL: https://www.openshift.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util

%description
Provides a mock plugin cartridge for use in the V2 Cartridge SDK. Used to integration
test platform functionality.


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/conf
%dir %{cartridgedir}/conf.d
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/usr
%config(noreplace) %{cartridgedir}/conf/
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%config(noreplace) %{cartridgedir}/mock-plugin.conf


%changelog
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

