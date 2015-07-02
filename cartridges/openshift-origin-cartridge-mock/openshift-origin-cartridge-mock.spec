%global cartridgedir %{_libexecdir}/openshift/cartridges/mock

Summary:       Mock cartridge for V2 Cartridge SDK
Name:          openshift-origin-cartridge-mock
Version: 1.22.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides a mock cartridge for use in the V2 Cartridge SDK. Used to integration
test platform functionality. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__cp .mock_hidden.erb %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/conf
%{cartridgedir}/conf.d
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/template
%{cartridgedir}/usr
%{cartridgedir}/mock.conf
%{cartridgedir}/.mock_hidden.erb
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.22.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.21.2-1
- Incorrect self-documents link in README.md for markers and cron under
  .openshift (bparees@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.19.0-2
- bumpspec to mass fix tags

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Merge pull request #5200 from ncdc/metrics (dmcphers+openshiftbot@redhat.com)
- Metrics (andy.goldstein@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.17.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.16.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- Cleaning specs (dmcphers@redhat.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.16.1-1
- Explicitly set protocols on endpoints that provide a frontend mapping
  (rmillner@redhat.com)
- Merge pull request #3747 from rmillner/frontend-sni-proxy
  (dmcphers+openshiftbot@redhat.com)
- Create HAProxy SNI proxy plugin package and use endpoint protocols
  (rmillner@redhat.com)
- Fix build-dependencies Fix scaling_functional_test (pmorie@gmail.com)
- Build & deployment improvements (andy.goldstein@gmail.com)
- Build & deployment improvements (andy.goldstein@gmail.com)
- bump_minor_versions for sprint 35 (admiller@redhat.com)
