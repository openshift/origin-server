%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/mock-plugin
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/mock-plugin

Name: openshift-origin-cartridge-mock-plugin
Version: 0.0.5
Release: 1%{?dist}
Summary: Mock plugin cartridge for V2 Cartridge SDK
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Provides a mock plugin cartridge for use in the V2 Cartridge SDK. Used to integration
test platform functionality.


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
%dir %{cartridgedir}/conf.d
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/opt
%config(noreplace) %{cartridgedir}/conf/
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%config(noreplace) %{cartridgedir}/mock-plugin.conf


%changelog
* Tue Feb 19 2013 Paul Morie <pmorie@gmail.com> 0.0.5-1
- new package built with tito

