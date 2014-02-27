%global debug_package   %{nil}
%global __strip /bin/true
%global import_path github.com/openshift

Name:          openshift-origin-logshifter
Version:       1.2
Release:       1%{?dist}
Summary:       Log transport for OpenShift gear processes.
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: golang
ExclusiveArch: %{ix86} x86_64 %{arm}

%description
A simple log pipe designed to maintain consistently high input consumption rates, preferring to
drop old messages rather than block the input producer.

%prep
%setup -q

%build
mkdir _build
pushd _build
mkdir -p src/%{import_path}
ln -s $(dirs +1 -l) src/%{import_path}/logshifter
export GOPATH=$(pwd)
go install %{import_path}/logshifter
popd

%install
install -d %{buildroot}%{_bindir}
install -p -m 755 _build/bin/logshifter %{buildroot}%{_bindir}/logshifter

%files
%defattr(-,root,root,-)
%{_bindir}/logshifter

%changelog
* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.2-1
- new package built with tito

* Thu Feb 27 2014 Dan Mace <ironcladlou@gmail.com> 1.1-1
- new package built with tito

