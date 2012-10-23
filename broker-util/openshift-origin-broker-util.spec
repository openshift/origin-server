Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-broker-util
Version:        0.0.6.2
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
cp complete-origin-setup %{buildroot}%{_bindir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) %{_bindir}/oo-admin-chk
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-app
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-district
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-domain
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-template
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-user
%attr(0755,-,-) %{_bindir}/oo-admin-move
%attr(0755,-,-) %{_bindir}/oo-register-dns
%attr(0755,-,-) %{_bindir}/oo-setup-bind
%attr(0755,-,-) %{_bindir}/oo-setup-broker
%attr(0755,-,-) %{_bindir}/oo-accept-broker
%attr(0755,-,-) %{_bindir}/complete-origin-setup
%doc LICENSE

%changelog
* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.0.6.2-1
- Port admin scripts for on-premise (jhonce@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Tue Oct 09 2012 Krishna Raman <kraman@gmail.com> 0.0.6.1-1
- Removing old build scripts Moving broker/node setup utilities into util
  packages (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- Bug 864005 (dmcphers@redhat.com)
- Bug: 861346 - fixing ss-admin-ctl-domain script (abhgupta@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.0.5-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

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

