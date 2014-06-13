%global cartridgedir %{_libexecdir}/openshift/cartridges/java-openjdk

Summary:       Provides OpenJDK 8 support
Name:          openshift-origin-cartridge-java-openjdk
Version: 1.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      bc
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      java-1.8.0-openjdk
Requires:      java-1.8.0-openjdk-devel
BuildArch:     noarch

%description
Provides OpenJDK 8 support to OpenShift. (Cartridge Format V2)

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
%{cartridgedir}/env
%{cartridgedir}/metadata
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jun 12 2014 Severin Gehwolf <sgehwolf@redhat.com> 1.0-1
- Initial package.
