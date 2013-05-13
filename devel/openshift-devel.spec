%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}

Summary:       OpenShift Origin development dependencies
Name:          openshift-origin-devel
Version:       0.0.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(simplecov)
Requires:      %{?scl:%scl_prefix}rubygem(ci_reporter)
Requires:      %{?scl:%scl_prefix}rubygem(mocha)
Requires:      %{?scl:%scl_prefix}rubygem(test-unit)
Requires:      %{?scl:%scl_prefix}rubygem(webmock)
Requires:      %{?scl:%scl_prefix}rubygem(poltergeist)
Requires:      %{?scl:%scl_prefix}rubygem(konacha)
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(rspec-core)

# unknown
Requires:      %{?scl:%scl_prefix}rubygem(uglifier)

BuildArch:     noarch

%description
This is a meta-package that pull in requirements from running the OpenShift
Origin test suites.

%prep
%setup -q

%build

%install

%files

%changelog
* Wed May 1 2013 Brenton Leanhardt <bleanhar@redhat.com> 0.0.1-1
- Initial package
