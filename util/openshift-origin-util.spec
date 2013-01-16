Summary:        Utility scripts for the OpenShift Origin broker and node
Name:           openshift-origin-util
Version:        1.0.3
Release:        1%{?dist}
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:       bind-utils
Requires:       ruby
Requires:       rubygems
BuildArch:      noarch

%description
This package contains a set of utility scripts for the
OpenShift broker and node. 

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_bindir}
cp oo-* %{buildroot}%{_bindir}/
chmod 0755 %{buildroot}%{_bindir}/*

%files
%{_bindir}/oo-ruby
%{_bindir}/oo-exec-ruby
%{_bindir}/oo-diagnostics


%changelog
* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.3-1
- Bumped to new version

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.2-1
- new package built with tito

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.1-1
- new package built with tito

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.0-1
- Initial commit
