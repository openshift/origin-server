%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/switchyard-0.6
%global frameworkdir %{_libexecdir}/openshift/cartridges/switchyard-0.6

Name: openshift-origin-cartridge-switchyard-0.6
Version: 1.1.3
Release: 1%{?dist}
Summary: Embedded SwitchYard modules for JBoss
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
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}

%post

alternatives --remove switchyard-0.6 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0.6 switchyard-0.6 /usr/share/switchyard 102
alternatives --set switchyard-0.6 /usr/share/switchyard


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0750,-,-) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon Nov 12 2012 William DeCoste <wdecoste@redhat.com> 1.1.3-1
- added info/configuration

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #855 from bdecoste/master (openshift+bot@redhat.com)
- US3064 - switchyard (bdecoste@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- new package built with tito

* Wed Nov 07 2012 Unknown name <bdecoste@gmail.com> 1.0.1-1
- new package built with tito

* Tue Nov 06 2012 William DeCoste <wdecoste@redhat.com> 
- initial
