%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/10gen-mms-agent-0.1

Name: cartridge-10gen-mms-agent-0.1
Version: 1.9.0
Release: 1%{?dist}
Summary: Embedded 10gen MMS agent for performance monitoring of MondoDB

Group: Applications/Internet
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-10gen-mms-agent-0.1

Requires: stickshift-abstract
Requires: cartridge-mongodb-2.0
Requires: pymongo
Requires: mms-agent

%description
Provides 10gen MMS agent cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 1.8.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 1.8.4-1
- new package built with tito
