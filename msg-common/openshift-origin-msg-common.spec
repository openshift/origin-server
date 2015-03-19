%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective/
%else
    %global mco_root /usr/libexec/mcollective/mcollective/
%endif

Summary:       Common msg components for OpenShift broker and node
Name:          openshift-origin-msg-common
Version: 1.23.1
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}mcollective-common >= 2.2.3
BuildArch:     noarch

%description
Provides the common dependencies of the msg components
for OpenShift broker and node

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{mco_root}agent
cp -p agent/* %{buildroot}%{mco_root}agent/
chmod 644 %{buildroot}%{mco_root}agent/*

%files
%{mco_root}agent/*

%changelog
* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Thu Feb 19 2015 Adam Miller <admiller@redhat.com> 1.22.2-1
- Fixing typos (dmcphers@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- openshift.ddl: fix gear UUID regexes (lmeyer@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Bug 1119609 - Support vendor in oo-admin-cartridge (jhonce@redhat.com)
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- bump specs to fix tags (admiller@redhat.com)
- Bug 1087964 - Allow move gear from non-districted/districted node to
  districted node. (rpenta@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Adding missing action in mcollective DDL (abhgupta@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4682 from danmcp/cleaning_specs
  (dmcphers+openshiftbot@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Cleanup mco ddl (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Card #185: sending app alias to all web_proxy gears (abhgupta@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- fix tags (admiller@redhat.com)
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com>
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)
