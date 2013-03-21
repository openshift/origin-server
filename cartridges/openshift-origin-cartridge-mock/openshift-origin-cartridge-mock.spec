%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mock
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mock

Name: openshift-origin-cartridge-mock
Version: 0.1.3
Release: 1%{?dist}
Summary: Mock cartridge for V2 Cartridge SDK
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Provides a mock cartridge for use in the V2 Cartridge SDK. Used to integration
test platform functionality.


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}/.openshift
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}


%clean
rm -rf %{buildroot}


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
%doc %{cartridgedir}/README.md
%config(noreplace) %{cartridgedir}/mock.conf


%changelog
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

