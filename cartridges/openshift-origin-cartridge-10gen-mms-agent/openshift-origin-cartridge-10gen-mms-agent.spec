%global cartridgedir %{_libexecdir}/openshift/cartridges/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.29.0
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      pymongo
Requires:      mms-agent

Obsoletes: openshift-origin-cartridge-10gen-mms-agent-0.1


BuildArch:     noarch

%description
Provides 10gen MMS agent cartridge support. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.28.2-1
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.27.3-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.27.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.27.1-1
- Bug 990849 - Bumped manifest Version element in error (jhonce@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.26.4-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.26.3-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.26.2-1
- Bug 987872 (dmcphers@redhat.com)
- Check cartridge configure order dependency in the broker (rpenta@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.25.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.24.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.23.6-1
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.23.5-1
- Bug 966857: Fix executable bit in 10gen cartridge scripts
  (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.23.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.23.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.23.2-1
- Bug 962627 (dmcphers@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Move folder creation back to setup (dmcphers@redhat.com)

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
