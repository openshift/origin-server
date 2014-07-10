%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

Summary:       Utility scripts for the OpenShift Origin broker and node
Name:          openshift-origin-util
Version:       1.16.0
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      bind-utils
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      lsof
BuildArch:     noarch

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
%{_bindir}/oo-erb
%{_bindir}/oo-exec-ruby
%{_bindir}/oo-mco


%changelog
* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Adding lsof dependency (kraman@gmail.com)
