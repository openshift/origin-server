%global cartridgedir %{_libexecdir}/openshift/cartridges/mock-plugin

Summary:       Mock plugin cartridge for V2 Cartridge SDK
Name:          openshift-origin-cartridge-mock-plugin
Version: 1.20.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides a mock plugin cartridge for use in the V2 Cartridge SDK. Used for integration
test platform functionality.

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
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/conf
%{cartridgedir}/conf.d
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/mock-plugin.conf
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- Cleaning specs (dmcphers@redhat.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.16.1-1
- Add SNI support to mock-plugin for testing and include a simple server.
  (rmillner@redhat.com)
- bump_minor_versions for sprint 35 (admiller@redhat.com)