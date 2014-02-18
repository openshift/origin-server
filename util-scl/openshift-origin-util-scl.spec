Summary:       Utility scripts for the OpenShift Origin broker and node
Name:          openshift-origin-util-scl
Version: 1.17.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildArch:     noarch

%description
This package contains a set of utility scripts for the broker and node. 

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_bindir}
cp oo-* %{buildroot}%{_bindir}/

%files
%attr(0755,-,-) %{_bindir}/oo-ruby
%attr(0755,-,-) %{_bindir}/oo-erb
%attr(0755,-,-) %{_bindir}/oo-exec-ruby
%attr(0755,-,-) %{_bindir}/oo-mco


%changelog
* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- Cleaning specs (dmcphers@redhat.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.16.1-1
- bump_minor_versions for sprint 35 (admiller@redhat.com)