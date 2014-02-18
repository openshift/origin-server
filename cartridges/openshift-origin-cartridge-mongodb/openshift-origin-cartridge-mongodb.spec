%global cartridgedir %{_libexecdir}/openshift/cartridges/mongodb

Summary:       Embedded mongodb support for OpenShift
Name:          openshift-origin-cartridge-mongodb
Version: 1.18.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mongodb-server
Requires:      mongodb-devel
Requires:      libmongodb
Requires:      mongodb
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-mongodb-2.2 = 2.0.0
Obsoletes:     openshift-origin-cartridge-mongodb-2.2 <= 1.99.9
BuildArch:     noarch

%description
Provides mongodb cartridge support to OpenShift

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%__mkdir -p %{buildroot}%{cartridgedir}/usr/journal-cache


%post
%{cartridgedir}/bin/mkjournal %{cartridgedir}/usr/journal-cache/journal.tar.gz


%preun
if [ $1 -eq 0 ]; then
  %__rm -f %{cartridgedir}/usr/journal-cache/journal.tar.gz
fi


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
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
- MongoDB version update to 2.4 (jhadvig@redhat.com)

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 1.17.1-1
- bump_minor_versions for sprint 36 (admiller@redhat.com)
