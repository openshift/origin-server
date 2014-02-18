%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins

Summary:       Provides jenkins-1.x support
Name:          openshift-origin-cartridge-jenkins
Version: 1.18.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.6
Requires:      jenkins
Requires:      jenkins-plugin-openshift
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-jenkins-1.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-jenkins-1.4 <= 1.99.9
BuildArch:     noarch

%description
Provides Jenkins cartridge to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post
service jenkins stop
chkconfig jenkins off

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.17.3-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.17.1-1
- Merge pull request #4532 from bparees/jenkins_by_uuid
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.16.6-1
- Merge pull request #4578 from bparees/jenkins_utf
  (dmcphers+openshiftbot@redhat.com)
- Bug 1056666 - Jenkins cartridge InvalidPathException with é or '
  (bparees@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.16.5-1
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.16.4-1
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.16.3-1
- Give better messaging around starting jenkins (dmcphers@redhat.com)
- bug 993561: WARNING: Failed to broadcast over UDP appears in jenkins.log when
  git push change to a jenkins app (bparees@redhat.com)
