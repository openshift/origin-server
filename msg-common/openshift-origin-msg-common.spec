%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%if 0%{?fedora}
    %global mco_root /usr/libexec/mcollective/mcollective/
%endif
%if 0%{?rhel}
    %global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective/
%endif

Summary:        Common dependencies of the msg components for OpenShift server and node
Name:           openshift-origin-msg-common
Version:        1.0.1
Release:        1%{?dist}
Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz
Requires:       %{?scl:%scl_prefix}mcollective-common

BuildArch: noarch

%description
Provides the common dependencies of the msg components for OpenShift server and node

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{mco_root}agent
mkdir -p %{buildroot}%{mco_root}validator
cp agent/* %{buildroot}%{mco_root}agent/
cp validator/* %{buildroot}%{mco_root}validator/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0644,-,-) %{mco_root}agent/*
%attr(0644,-,-) %{mco_root}validator/*

%changelog
* Mon Dec 03 2012 Dan McPherson <dmcphers@redhat.com> 1.0.1-1
- new package built with tito

* Mon Dec 3 2012 Dan McPherson <dmcphers@redhat.com> 1.0.0-1
- Initial commit