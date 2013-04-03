%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins

Summary:       Provides jenkins-1.4 support
Name:          openshift-origin-cartridge-jenkins
Version: 1.7.4
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.6
Requires:      jenkins
Requires:      jenkins-plugin-openshift
Requires:      openshift-origin-node-util
BuildRequires: git
BuildArch:     noarch

%description
Provides Jenkins cartridge to OpenShift


%prep
%setup -q


%build


%post
service jenkins stop
chkconfig jenkins off

%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jenkins


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
#mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE



%changelog
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


