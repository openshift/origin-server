%global cartridgedir %{_libexecdir}/openshift/cartridges/mariadb

Summary:       Provides embedded mariadb support
Name:          openshift-origin-cartridge-mariadb
Version:       0.0.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mariadb-server
Requires:      mariadb-devel
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides mariadb cartridge support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed May 08 2013 Krishna Raman <kraman@gmail.com> 0.0.2-1
- new package built with tito


