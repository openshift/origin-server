Name:     tuned-profiles-openshift-node
Version:  0.1.0
Release:  1%{?dist}
Summary:  tuned profile for openshift node hosts

Group:    Development/System
License:  ASL 2.0
URL:      https://openshift.com
Source0:  %{name}-%{version}.tar.gz

Requires: tuned

%description
A tuned profile customized for OpenShift Node host roles.

%prep
%setup -q


%build

%install
mkdir -p %{buildroot}/etc/tune-profiles/openshift-node/
cp -r profile/* %{buildroot}/etc/tune-profiles/openshift-node/


%files
/etc/tune-profiles/openshift-node/ktune.sh
/etc/tune-profiles/openshift-node/ktune.sysconfig
/etc/tune-profiles/openshift-node/sysctl.ktune
/etc/tune-profiles/openshift-node/tuned.conf

%post
/usr/sbin/tuned-adm profile openshift-node

%preun
/usr/sbin/tuned-admin profile default

%changelog
* Mon Jan 05 2015 Scott Dodson <sdodson@redhat.com> 0.1.0-1
- new package built with tito

* Mon Jan 05 2015 Scott Dodson <sdodson@redhat.com> - 0.1-1
- Initial packaging
