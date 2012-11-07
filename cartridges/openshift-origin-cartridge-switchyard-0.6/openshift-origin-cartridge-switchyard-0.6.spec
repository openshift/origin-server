%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/switchyard-0.6
%global frameworkdir %{_libexecdir}/openshift/cartridges/switchyard-0.6

Name: openshift-origin-cartridge-jenkins-client-1.4
Version: 1.0.0
Release: 1%{?dist}
Summary: Embedded jenkins client support for express 
Group: Network/Daemons
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: mysql-devel
Requires: wget
Requires: java-1.6.0-openjdk
Requires: rubygems
Requires: rubygem-json
Requires: switchyard-as7-modules

%description
Provides embedded switchyard support for JBoss cartridges


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Tue Nov 06 2012 William DeCoste <wdecoste@redhat.com> 
- initial
