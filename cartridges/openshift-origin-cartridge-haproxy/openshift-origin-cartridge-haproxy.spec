%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/haproxy
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/haproxy

Name:          openshift-origin-cartridge-haproxy
Version: 0.2.4
Release:       1%{?dist}
Summary:       Provides HA Proxy
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      haproxy
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
BuildRequires: git
BuildArch:     noarch

%description
HAProxy cartridge for OpenShift.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/


%clean
rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/haproxy

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/hooks
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md

%changelog
* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Fix haproxy v2 path construction (ironcladlou@gmail.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- HAProxy deploy wip. (mrunalp@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- new package built with tito

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com>
- new package built with tito

* Tue Mar 26 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

