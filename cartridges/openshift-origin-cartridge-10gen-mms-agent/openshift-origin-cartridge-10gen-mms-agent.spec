%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.21.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb-2.2
Requires:      pymongo
Requires:      mms-agent
BuildArch:     noarch

%description
Provides 10gen MMS agent cartridge support


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
cp -r * %{buildroot}%{cartridgedir}/

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/metadata
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)