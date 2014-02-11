%global cartridgedir %{_libexecdir}/openshift/cartridges/10gen-mms-agent

Summary:       Embedded 10gen MMS agent for performance monitoring of MondoDB
Name:          openshift-origin-cartridge-10gen-mms-agent
Version: 1.30.3
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-mongodb
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mms-agent

Obsoletes: openshift-origin-cartridge-10gen-mms-agent-0.1


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
