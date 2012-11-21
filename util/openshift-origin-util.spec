Summary:        Utility scripts for the OpenShift Origin broker and node
Name:           openshift-origin-util
Version: 1.0.0
Release:        1%{?dist}
Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

BuildArch:      noarch

%description
This package contains a set of utility scripts for the broker and node. 

%prep
%setup -q

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_sbindir}
cp oo-* %{buildroot}%{_sbindir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) %{_sbindir}/oo-ruby


%changelog
* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.0-1
- Initial commit