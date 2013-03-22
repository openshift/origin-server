%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins

Summary:       Provides jenkins-1.4 support
Name:          openshift-origin-cartridge-jenkins
Version: 1.6.6
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
* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- adding openshift node util (dmcphers@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- adding jenkins teardown (dmcphers@redhat.com)
- Jenkins client WIP (dmcphers@redhat.com)
- Merge pull request #1709 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- more jenkins WIP (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- v2 cart cleanup (bdecoste@gmail.com)
- add jenkins cart (dmcphers@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.6.4-1
- new package built with tito

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.6.3-1
- new package built with tito


