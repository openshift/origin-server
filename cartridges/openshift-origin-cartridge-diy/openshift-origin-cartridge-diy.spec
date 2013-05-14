%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/diy

Name: openshift-origin-cartridge-diy
Version: 0.4.1
Release: 1%{?dist}
Summary: DIY cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://www.openshift.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch: noarch

%description
DIY cartridge for openshift. (Cartridge Format V2)


%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__rm -rf %{buildroot}
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}


%clean
%__rm -rf %{buildroot}


%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)
- removing version logic from diy (dmcphers@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- moving templates to usr (dmcphers@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Special file processing (fotios@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Merge pull request #2297 from ironcladlou/bz/955482
  (dmcphers+openshiftbot@redhat.com)
- Bug 955482: Remove unnecessary symlink from RPM spec (ironcladlou@gmail.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Env var WIP. (mrunalp@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Merge pull request #2145 from sosiouxme/fixdeps
  (dmcphers+openshiftbot@redhat.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- Bug 947010: Exclude grep when checking for existing process
  (ironcladlou@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.7-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- Bug 952041 - Add support for tidy to DIY and PHP cartridges
  (jhonce@redhat.com)
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.2.5-1
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Fixing stop and restart when diy is already stopped (calfonso@redhat.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

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

