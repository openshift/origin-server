%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.23.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb-2.2
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      pymongo
Requires:      mms-agent
BuildArch:     noarch

%description
Provides 10gen MMS agent cartridge support. (Cartridge Format V2)


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
cp -r * %{buildroot}%{cartridgedir}/

%clean
rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/10gen-mms-agent


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/metadata
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.22.2-1
- Special file processing (fotios@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.22.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- implementing install and post-install (dmcphers@redhat.com)
- install and post setup tests (dmcphers@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.21.7-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.21.6-1
- Merge pull request #1988 from ironcladlou/dev/v2carts/locked-files-refactor
  (dmcphers@redhat.com)
- Bug 950224: Remove unnecessary Endpoints (ironcladlou@gmail.com)
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 949817 (dmcphers@redhat.com)

* Mon Apr 08 2013 Dan McPherson <dmcphers@redhat.com> 1.21.4-1
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Sat Apr 06 2013 Dan McPherson <dmcphers@redhat.com> 1.21.3-1
- new package built with tito

* Sat Apr 06 2013 Dan McPherson <dmcphers@redhat.com> 1.21.2-1
- new package built with tito

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
