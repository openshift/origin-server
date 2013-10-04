%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins-client

Summary:       Embedded jenkins client support for OpenShift 
Name:          openshift-origin-cartridge-jenkins-client
Version: 1.16.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      wget
%if 0%{?fedora}%{?rhel} <= 6
Requires:      java-1.6.0-openjdk
%else
Requires:      java-1.7.0-openjdk
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-json
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-jenkins-client-1.4

%description
Provides plugin jenkins client support. (Cartridge Format V2)

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
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Merge pull request #3455 from jwhonce/latest_cartridge_versions
  (dmcphers+openshiftbot@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- <cartridge versions> origin_runtime_219, Fix up Display-Name: field in
  manifests https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-
  versions (jolamb@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- <cart version> origin_runtime_219, Update carts and manifests with new
  versions, handle version change in upgrade code
  https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-versions
  (jolamb@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.11.5-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- redo sparse cart addition/deletion as user can override their scaling factors
  (rchopra@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Bug 975530 (dmcphers@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Fix bug 967439 - improve jenkins client message (jliggitt@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.8.3-1
- Merge pull request #2532 from ironcladlou/bz/962324
  (dmcphers+openshiftbot@redhat.com)
- spec file cleanup (tdawson@redhat.com)
- Bug 962324: Add status output to jenkins-client (ironcladlou@gmail.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Bug 956044 (dmcphers@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- minor fixes (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- Bug 835778 (dmcphers@redhat.com)
- Merge pull request #2208 from ironcladlou/dev/v2carts/post-configure
  (dmcphers+openshiftbot@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- adding install and post install for jenkins (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 952161 (asari.ruby@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.6.6-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Merge pull request #1988 from ironcladlou/dev/v2carts/locked-files-refactor
  (dmcphers@redhat.com)
- Bug 950224: Remove unnecessary Endpoints (ironcladlou@gmail.com)
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- jenkins WIP (dmcphers@redhat.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- getting jenkins working (dmcphers@redhat.com)
- Getting jenkins working (dmcphers@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- using erbs (dmcphers@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- adding openshift node util (dmcphers@redhat.com)
- More v2 jenkins-client progress (ironcladlou@gmail.com)
- implementing builder_cartridge based on cart categories (dmcphers@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- adding jenkins teardown (dmcphers@redhat.com)
- Jenkins client WIP (dmcphers@redhat.com)
- Merge pull request #1709 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- jenkins client WIP (dmcphers@redhat.com)
- more jenkins WIP (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- v2 cart cleanup (bdecoste@gmail.com)
- add jenkins cart (dmcphers@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.5.4-1
- new package built with tito

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.5.3-1
- new package built with tito


