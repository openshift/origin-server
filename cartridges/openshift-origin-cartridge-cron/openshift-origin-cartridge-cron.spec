%global cartridgedir %{_libexecdir}/openshift/cartridges/cron

Summary:       Embedded cron support for OpenShift
Name:          openshift-origin-cartridge-cron
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util

Obsoletes: openshift-origin-cartridge-cron-1.4

BuildArch:     noarch

%description
Cron cartridge for openshift. (Cartridge Format V2)

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
* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Revert "cartridges: display the cron install message only on the web_proxy
  gear in a scaled environment" (dmcphers@redhat.com)
- Revert "use proper return codes in has_web_proxu() bash sdk"
  (dmcphers@redhat.com)
- use proper return codes in has_web_proxu() bash sdk (mmahut@redhat.com)
- cartridges: display the cron install message only on the web_proxy gear in a
  scaled environment (mmahut@redhat.com)
- cartridges: displaying the gear uuid to distinguish between gears in a cron
  scaled environment (RHBZ#1006712) (mmahut@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Bug 1005305 - The cron cartridge should support scaled applications
  (bleanhar@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- openshift-origin-cartridge-cron: stop the cartridge only if started during a
  restart (mmahut@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- Cartridge - Clean up manifests (jhonce@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Update cartridge versions for Sprint 31 (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Merge pull request #3197 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2811 from BanzaiMan/dev/hasari/bz971586
  (dmcphers+openshiftbot@redhat.com)
- Bug 982738 (dmcphers@redhat.com)
- Mimic rhcsh logic more closely (asari.ruby@gmail.com)
- Bug 971586 (asari.ruby@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.9.3-1
- WIP Cartridge - bump cartridge versions (jhonce@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- Merge pull request #2958 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
- Bug 977493 - Avoid leaking the lock file descriptor to child processes.
  (rmillner@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Beef up cron cart README (asari.ruby@gmail.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.7.6-1
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.7.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Make process label checks in cuke tests v1/v2 compatible
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- cron cleanup (dmcphers@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Removed empty dirs from cron cartridge (calfonso@redhat.com)
- Removed unused jobs from cron cart. This lives in the platform now
  (calfonso@redhat.com)
- Changed echo to client_result in cron cartridge (calfonso@redhat.com)
- Modifying cron cartridge to point to correct limits and frequencies location
  (calfonso@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- implementing install and post-install (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 1.5.6-1
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Fixing cron cart issue with the locked files (calfonso@redhat.com)
- Merge pull request #1988 from ironcladlou/dev/v2carts/locked-files-refactor
  (dmcphers@redhat.com)
- Bug 950224: Remove unnecessary Endpoints (ironcladlou@gmail.com)
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Moving root cron configuration out of cartridges and into node
  (calfonso@redhat.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Fri Mar 22 2013 Dan McPherson <dmcphers@redhat.com> 1.4.2-1
- new package built with tito

* Fri Mar 22 2013 Chris Alfonso <calfonso@redhat.com> 1.4.1-1
- new package built with tito

