%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins

Summary:       Provides jenkins-1.x support
Name:          openshift-origin-cartridge-jenkins
Version: 1.29.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
#https://issues.jenkins-ci.org/browse/JENKINS-15047
Requires:      java >= 1.7
Requires:      jenkins
Requires:      jenkins-plugin-openshift
Requires:      openshift-origin-node-util
Requires:      unzip
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
if service jenkins status > /dev/null 2>&1; then
  service jenkins stop
fi
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
* Thu Sep 17 2015 Unknown name 1.29.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.28.2-1
- Require java7 for latest jenkins (tiwillia@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.28.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Wed Jul 01 2015 Wesley Hearn <whearn@redhat.com> 1.27.3-1
- Bump cartridge versions for Sprint 64 (j.hadvig@gmail.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.27.2-1
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.26.4-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Dec 01 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Unify `-x' shell attribute in cartridge scripts (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Merge pull request #5949 from VojtechVitek/upgrade_scrips
  (dmcphers+openshiftbot@redhat.com)
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- Merge pull request #5931 from bparees/clear_jenkins_upgrade
  (dmcphers+openshiftbot@redhat.com)
- remove old upgrade logic (bparees@redhat.com)
- Jenkins cart: Add "unzip" dependency (jolamb@redhat.com)
- Merge pull request #5898 from mfojtik/jenkins_ssh
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)
- Bug 1153557 - Disable strict known_hosts checking in Jenkins
  (mfojtik@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Add markers to disable bad ciphers for rhel6.6 (bparees@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- bump cart versions for sprint 48 (bparees@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- Merge pull request #5585 from
  vbalazs/bvarga/origin_cartridge_214_jvm_heap_opts
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)
- JVM heap optimization settings and remove SerialGC (bvarga@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Bump cartridge versions for 2.0.47 (jhadvig@gmail.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- "WARNING: Failed to broadcast over UDP" appears in jenkins.log
  (bparees@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- bz1092161 - conditionally stop jenkins service (admiller@redhat.com)

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
