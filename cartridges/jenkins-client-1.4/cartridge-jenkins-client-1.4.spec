%global cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/jenkins-client-1.4

Name: cartridge-jenkins-client-1.4
Version: 0.26.2
Release: 1%{?dist}
Summary: Embedded jenkins client support for express 
Group: Network/Daemons
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: mysql-devel
Requires: wget
Requires: java-1.6.0-openjdk
Requires: rubygems
Requires: rubygem-json


%description
Provides embedded jenkins client support


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.26.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.26.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.25.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.25.4-1
- new package built with tito
