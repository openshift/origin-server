%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins

Summary:       Provides jenkins-1.4 support
Name:          openshift-origin-cartridge-jenkins
Version: 1.11.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.6
Requires:      jenkins
Requires:      jenkins-plugin-openshift
Requires:      openshift-origin-node-util
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-jenkins-1.4

%description
Provides Jenkins cartridge to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post
service jenkins stop
chkconfig jenkins off
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- WIP Cartridge - Updated manifest.yml versions for compatibility
  (jhonce@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Bug 975255 (dmcphers@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Use -z with quotes (dmcphers@redhat.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- Various cleanup (dmcphers@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Bug 963156 (dmcphers@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- Bug 962805 (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Bug 962354 (dmcphers@redhat.com)
- Bug 961227 (dmcphers@redhat.com)
- Bug 960812 (dmcphers@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Bug 961661 - Limit scalability of Jenkins v2 cart (jdetiber@redhat.com)
- cron cleanup (dmcphers@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- moving templates to usr (dmcphers@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Special file processing (fotios@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- 956570 (dmcphers@redhat.com)
- fixing tests (dmcphers@redhat.com)
- Merge pull request #2208 from ironcladlou/dev/v2carts/post-configure
  (dmcphers+openshiftbot@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- adding install and post install for jenkins (dmcphers@redhat.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 1.7.7-1
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.6-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- jenkins WIP (dmcphers@redhat.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- delete all calls to remove_ssh_key, and remove_domain_env_vars
  (rchopra@redhat.com)
- Merge pull request #1943 from bdecoste/master (dmcphers@redhat.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Bug 947092 (bdecoste@gmail.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Bug 947092 (bdecoste@gmail.com)
- wait for Jenkins to come up fully (bdecoste@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.9-1
- Remove threaddump from jenkins control (dmcphers@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.8-1
- Getting jenkins working (dmcphers@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- using erbs (dmcphers@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- adding openshift node util (dmcphers@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- adding jenkins teardown (dmcphers@redhat.com)
- Jenkins client WIP (dmcphers@redhat.com)
- Merge pull request #1709 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- more jenkins WIP (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- v2 cart cleanup (bdecoste@gmail.com)
- add jenkins cart (dmcphers@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.6.4-1
- new package built with tito

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.6.3-1
- new package built with tito


