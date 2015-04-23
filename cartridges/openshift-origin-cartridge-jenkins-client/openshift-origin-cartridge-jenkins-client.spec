%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/jenkins-client

Summary:       Embedded jenkins client support for OpenShift 
Name:          openshift-origin-cartridge-jenkins-client
Version: 1.26.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      java-1.6.0-openjdk
%else
Requires:      java-1.7.0-openjdk
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-json
Provides:      openshift-origin-cartridge-jenkins-client-1.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-jenkins-client-1.4 <= 1.99.9
BuildArch:     noarch

%description
Provides plugin jenkins client support. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/configuration
%{cartridgedir}/metadata
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Wed Apr 08 2015 Wesley Hearn <whearn@redhat.com> 1.25.3-1
- Bump cartridge versions for 2.0.60 (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.25.2-1
- Use the net/http library for HTTP requests (ironcladlou@gmail.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Merge pull request #5673 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- bump cart versions for sprint 48 (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.23.4-1
- Bump cartridge versions for 2.0.47 (jhadvig@gmail.com)

* Thu Jul 03 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Merge pull request #5563 from bparees/jenkins_encoding
  (dmcphers+openshiftbot@redhat.com)
- "InvalidByteSequenceError" on the first time do jenkins build for app
  (bparees@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5552 from bparees/update_lts
  (dmcphers+openshiftbot@redhat.com)
- "WARNING: Failed to broadcast over UDP" appears in jenkins.log
  (bparees@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)

* Wed Jun 18 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #5516 from bparees/jenkins_wording
  (dmcphers+openshiftbot@redhat.com)
- Jenkins client description is misleading (bparees@redhat.com)

* Tue Jun 17 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- https://bugzilla.redhat.com/show_bug.cgi?id=1109026 (bparees@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Bump cartridge versions (agoldste@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- support cygwin in jenkins client shell command detect application platform in
  jenkins client and use it to determine if builder should be scalable update
  bash sdk with function to determine node platform (florind@uhurusoftware.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.20.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.19.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Show failure in jenkins log but success in STDOUT when jenkins build aerogear
  app (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- Merge pull request #4532 from bparees/jenkins_by_uuid
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.17.7-1
- Bump up cartridge versions (bparees@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.17.6-1
- Merge pull request #4522 from bparees/jenkins_job_message
  (dmcphers+openshiftbot@redhat.com)
- Bug 1046578 - jenkins-client-1 cartridge add missing build job output on
  first add (bparees@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.17.5-1
- Revert "Bug 995807 - Jenkins builds fail on downloadable cartridges"
  (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.17.4-1
- Merge pull request #4436 from bparees/jenkins_dl_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.17.3-1
- bug 993561: WARNING: Failed to broadcast over UDP appears in jenkins.log when
  git push change to a jenkins app (bparees@redhat.com)
