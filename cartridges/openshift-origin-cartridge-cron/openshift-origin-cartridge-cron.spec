%global cartridgedir %{_libexecdir}/openshift/cartridges/cron

Summary:       Embedded cron support for OpenShift
Name:          openshift-origin-cartridge-cron
Version: 1.22.0
Release:       2%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-cron-1.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-cron-1.4 <= 1.99.9
BuildArch:     noarch

%description
Cron cartridge for openshift. (Cartridge Format V2)

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
* Fri Apr 25 2014 Adam Miller - 1.22.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.21.2-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5078 from jwhonce/bug/1065276
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Bug 1065276 - Skip *.rpmnew when loading environments (jhonce@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Tue Mar 18 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Bug 1076626 - Fix LD_LIBRARY_PATH for cron_runjobs (mfojtik@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Use SDK functions in rhcsh and cronjob task to build PATH/LD_LIBRARY_PATH
  (mfojtik@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- <cron cart> Load env. vars. recursively (miciah.masters@gmail.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Bug 1065045 - Enforce cronjob timeout (jhonce@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Cleaning specs (dmcphers@redhat.com)
- Increase cron max run time (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.17.3-1
- Merge pull request #4558 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Bump up cartridge versions (bparees@redhat.com)

