%global cartridgedir %{_libexecdir}/openshift/cartridges/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.37.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mms-agent
Provides:      openshift-origin-cartridge-10gen-mms-agent-0.1 = 2.0.0
Obsoletes:     openshift-origin-cartridge-10gen-mms-agent-0.1 <= 1.99.9
BuildArch:     noarch

%description
Provides 10gen MMS agent cartridge support. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%{cartridgedir}/metadata
%{cartridgedir}/lib
%attr(0755,-,-) %{cartridgedir}/bin/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.37.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Wed Apr 08 2015 Wesley Hearn <whearn@redhat.com> 1.36.3-1
- Bump cartridge versions for 2.0.60 (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.36.2-1
- Card devexp_483 - Obsoleting 10gen cartridge (maszulik@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.36.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.35.2-1
- Bug 1135941 - Finish setup for 10gen cartridge when the agent code is
  missing. (mfojtik@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.35.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.34.4-1
- Merge pull request #5584 from jhadvig/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Bump cartridge versions for 2.0.47 (jhadvig@gmail.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.34.3-1
- Bug 1117163: Fix 10gen-mms-agent action triggering for scaled application
  (jhadvig@redhat.com)

* Mon Jul 07 2014 Adam Miller <admiller@redhat.com> 1.34.2-1
- Bug 1115539: Make 10gen cartridge able to embed with scaled application
  (jhadvig@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.34.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.33.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.33.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.32.4-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.32.3-1
- 10gen-mms-agent version bump, due to the failed migration
  (jhadvig@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Bug 1085128 - Bad grep parameter fix (jhadvig@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Merge pull request #5201 from ironcladlou/logshifter-pipes
  (dmcphers+openshiftbot@redhat.com)
- Bug 1085128 - Add warning message for the unsupported legacy version of the
  mms-agent (jhadvig@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.31.6-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.31.5-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.31.4-1
- correct typo of depricated to deprecated (bparees@redhat.com)
- Merge pull request #5025 from jhadvig/10gen_typo
  (dmcphers+openshiftbot@redhat.com)
- Fixing typo (jhadvig@redhat.com)
- Fixing inconsistency with displaying 10gen cartridge status
  (jhadvig@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.31.3-1
- 10gen cartridge update (jhadvig@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.31.2-1
- Remove unused teardowns (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- Merge pull request #4753 from
  smarterclayton/make_configure_order_define_requires
  (dmcphers+openshiftbot@redhat.com)
- Configure-Order should influence API requires (ccoleman@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1056349 (dmcphers@redhat.com)
