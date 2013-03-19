%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins

Summary:       Provides jenkins-1.4 support
Name:          openshift-origin-cartridge-jenkins
Version: 1.6.3
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.6
Requires:      jenkins
Requires:      jenkins-plugin-openshift
BuildRequires: git
BuildArch:     noarch

%description
Provides Jenkins cartridge to OpenShift


%prep
%setup -q


%build


%post
service jenkins stop
chkconfig jenkins off


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
#mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE



%changelog
* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.6.3-1
- new package built with tito


