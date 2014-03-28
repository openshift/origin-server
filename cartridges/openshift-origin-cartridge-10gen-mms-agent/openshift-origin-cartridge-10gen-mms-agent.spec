%global cartridgedir %{_libexecdir}/openshift/cartridges/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.32.0
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
%{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
