%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins-client

Summary:       Embedded jenkins client support for OpenShift 
Name:          openshift-origin-cartridge-jenkins-client
Version: 1.6.4
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           https://openshift.redhat.com
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

%description
Provides plugin jenkins client support


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
cp -r * %{buildroot}%{cartridgedir}/
#mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
#ln -s %{cartridgedir}/versions/1.4/configuration %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}-1.4

%clean
rm -rf %{buildroot}


%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/jenkins-client

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
#%{_sysconfdir}/openshift/cartridges/v2/%{name}-1.4
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE



%changelog
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


