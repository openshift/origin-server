Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-broker-util
Version:        0.0.1
Release:        1%{?dist}
Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       openshift-broker
Requires:       ruby(abi) >= 1.8
%if 0%{?rhel} == 6
BuildRequires:  rubygems
%else
BuildRequires:  rubygems-devel
%endif
BuildArch:      noarch

%description
This package contains a set of utility scripts for the broker.  They must be
run on a broker instance.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
cp ss-* %{buildroot}%{_bindir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0700,-,-) %{_bindir}/ss-*

%changelog
