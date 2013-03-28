%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mysql
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 0.1.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mysql-server
Requires:      mysql-devel
BuildArch:     noarch


%description
Provides mysql cartridge support to OpenShift


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


%changelog
* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Dan McPherson <dmcphers@redhat.com> 0.0.5-1
- 

* Wed Mar 20 2013 Adam Miller <admiller@redhat.com> 0.0.4-1
- new package built with tito

* Wed Mar 20 2013 Paul Morie <pmorie@gmail.com> 0.0.3-1
- new package built with tito

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.2-1
- WIP: mysql v2 (pmorie@gmail.com)

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.1-1
- new package built with tito

