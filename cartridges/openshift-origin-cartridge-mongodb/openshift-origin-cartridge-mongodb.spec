%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mongodb
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mongodb

Summary:       Embedded mongodb support for OpenShift
Name:          openshift-origin-cartridge-mongodb
Version: 1.6.5
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mongodb-server
Requires:      mongodb-devel
Requires:      libmongodb
Requires:      mongodb
Requires:      git
BuildArch:     noarch


%description
Provides mongodb cartridge support to OpenShift


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}


%clean
rm -rf %{buildroot}


%post
%{_sbindir}/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/mongodb

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/conf
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%config(noreplace) %{cartridgedir}/conf/
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Tue Apr 02 2013 Dan McPherson <dmcphers@redhat.com> 1.6.4-1
- new package built with tito

* Tue Apr 02 2013 Chris Alfonso <calfonso@redhat.com> 1.6.3-1
- new package built with tito


