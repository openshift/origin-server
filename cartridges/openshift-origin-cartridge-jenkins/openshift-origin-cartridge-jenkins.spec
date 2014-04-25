%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins

Summary:       Provides jenkins-1.x support
Name:          openshift-origin-cartridge-jenkins
Version: 1.21.2
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
%{cartridgedir}/configuration
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/env
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.21.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.20.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.20.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Fix bash brace expansion (vvitek@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- bump spec to fix versioning between branches (admiller@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump spec to fix versioning between branches (admiller@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.18.3-1
- Remove unused teardowns (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Merge pull request #4907 from bparees/jenkins_mixed
  (dmcphers+openshiftbot@redhat.com)
- Switch jenkins update url to use https to avoid mixed mode blocking in
  browsers (bparees@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

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
