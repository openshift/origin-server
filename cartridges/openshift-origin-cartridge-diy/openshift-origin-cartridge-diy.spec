%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/diy
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/diy

Name: openshift-origin-cartridge-diy
Version: 0.2.3
Release: 1%{?dist}
Summary: DIY cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
DIY cartridge for openshift.


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}


%clean
rm -rf %{buildroot}


%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/diy

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1976 from calfonso/master (dmcphers@redhat.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Bug fixes for DIY v2 cart -947010 (calfonso@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- Cron and DIY v2 cartridge fixes (calfonso@redhat.com)
- Cron cartridge 2.0 (calfonso@redhat.com)
- DIY Cartridge conformity to vendor-name (calfonso@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Fixing DIY cart git repo creation (chris@@hoflabs.com)

* Fri Mar 15 2013 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- new package built with tito

* Fri Mar 15 2013 Troy Dawson <tdawson@redhat.com> 0.1.2-1
- new package built with tito

* Thu Mar 14 2013 Chris Alfonso <calfonso@redhat.com> 0.1.1-1
- new package built with tito

