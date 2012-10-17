Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-node-util
Version:        0.0.2
Release:        1%{?dist}

Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       oddjob
Requires:       rng-tools
Requires:       rubygem-openshift-origin-node
BuildArch:      noarch

%description
This package contains a set of utility scripts for a node.  They must be
run on a node instance.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
cp bin/oo-* %{buildroot}%{_bindir}/

mkdir -p %{buildroot}/%{_sysconfdir}/httpd/conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/dbus-1/system.d/
mkdir -p %{buildroot}/%{_localstatedir}/www/html/

cp conf/oddjob/openshift-restorer.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp conf/oddjob/oddjobd-restorer.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp www/html/restorer.php %{buildroot}/%{_localstatedir}/www/html/

%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}%{_initddir}
cp init.d/openshift-gears %{buildroot}%{_initddir}/
%else
mkdir -p %{buildroot}/etc/systemd/system
mv services/openshift-gears.service %{buildroot}/etc/systemd/system/openshift-gears.service
%endif

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0750,-,-) %{_bindir}/oo-accept-node
%attr(0750,-,-) %{_bindir}/oo-admin-ctl-gears
%attr(0750,-,-) %{_bindir}/oo-app-idle
%attr(0750,-,-) %{_bindir}/oo-autoidler
%attr(0750,-,-) %{_bindir}/oo-idler
%attr(0750,-,-) %{_bindir}/oo-idler-stats
%attr(0750,-,-) %{_bindir}/oo-init-quota
%attr(0750,-,-) %{_bindir}/oo-last-access
%attr(0750,-,-) %{_bindir}/oo-list-stale
%attr(0750,-,-) %{_bindir}/oo-restorer
%attr(0750,-,apache) %{_bindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_bindir}/oo-setup-node

%doc LICENSE
%doc README-Idler.md

%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/oddjobd.conf.d/oddjobd-restorer.conf
%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/dbus-1/system.d/openshift-restorer.conf

%{_localstatedir}/www/html/restorer.php

%if 0%{?fedora}%{?rhel} <= 6
%attr(0750,-,-) %{_initddir}/openshift-gears
%else
%attr(0750,-,-) /etc/systemd/system
%endif

%post
/sbin/restorecon /usr/bin/oo-restorer* || :

%changelog
* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.2-1
- new package built with tito

