Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-broker-util
Version:        0.0.4
Release:        1%{?dist}
Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       openshift-broker
Requires:       ruby(abi) >= 1.8
%if 0%{?fedora} >= 17
BuildRequires:  rubygems-devel
%else
BuildRequires:  rubygems
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
cp oo-* %{buildroot}%{_bindir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) %{_bindir}/oo-*
%doc LICENSE

%changelog
* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Disable analytics for admin scripts (dmcphers@redhat.com)
- Commiting Rajat's fix for bug#827635 (bleanhar@redhat.com)
- Subaccount user deletion changes (rpenta@redhat.com)
- fixing build requires (abhgupta@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Removing the node profile enforcement from the oo-admin-ctl scripts
  (bleanhar@redhat.com)
- Adding LICENSE file to new packages and other misc cleanup
  (bleanhar@redhat.com)

* Thu Sep 20 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.2-1
- new package built with tito

