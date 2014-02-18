%global cartridgedir %{_libexecdir}/openshift/cartridges/switchyard

Summary:       Provides embedded switchyard support
Name:          openshift-origin-cartridge-switchyard
Version: 1.16.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      switchyard-as7-modules
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-switchyard-0.6 = 2.0.0
Obsoletes:     openshift-origin-cartridge-switchyard-0.6 <= 1.99.9
BuildArch:     noarch

%description
Provides switchyard cartridge support to OpenShift


%prep
%setup -q


%build
%__rm %{name}.spec


%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post

alternatives --remove switchyard-0 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0 switchyard-0 /usr/share/switchyard 102
alternatives --set switchyard-0 /usr/share/switchyard

alternatives --remove switchyard-0.6 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0.6 switchyard-0.6 /usr/share/switchyard 100
alternatives --set switchyard-0.6 /usr/share/switchyard

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.15.3-1
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.15.2-1
- Cleaning specs (dmcphers@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)
