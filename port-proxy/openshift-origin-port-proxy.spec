%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Script to configure HAProxy to do port forwarding for OpenShift
Name:          openshift-origin-port-proxy
Version: 1.9.1
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
# The haproxy daemon is used as the functioning tcp proxy
Requires:      haproxy
# OpenShift Origin node configuration and /etc/openshift
Requires:      rubygem(openshift-origin-node)
Requires:      sed
%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch

%description
OpenShift script to configure HAProxy to do port forwarding
from internal to external ports.

%prep
%setup -q

%build

%install
%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sbindir}
%else
mkdir -p %{buildroot}%{_initddir}
%endif
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{_bindir}

%if %{with_systemd}
install -m 644 systemd/openshift-port-proxy.service %{buildroot}%{_unitdir}
install -m 644 systemd/openshift-port-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-port-proxy
install -m 755 systemd/openshift-port-proxy %{buildroot}%{_sbindir}
%else
install -m 755 init-scripts/openshift-port-proxy %{buildroot}%{_initddir}
%endif
install -m 644 config/port-proxy.cfg %{buildroot}%{_sysconfdir}/openshift/
install -m 755 bin/openshift-port-proxy-cfg %{buildroot}%{_bindir}/openshift-port-proxy-cfg

%post
%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-port-proxy.service
%else
/sbin/chkconfig --add openshift-port-proxy || :
/sbin/service openshift-port-proxy condrestart || :
%endif

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-port-proxy.service
   /bin/systemctl stop openshift-port-proxy.service
%else
   /sbin/service openshift-port-proxy stop || :
   /sbin/chkconfig --del openshift-port-proxy || :
%endif
fi

%files
%doc LICENSE
%if %{with_systemd}
%{_unitdir}/openshift-port-proxy.service
%{_sysconfdir}/sysconfig/openshift-port-proxy
%{_sbindir}/openshift-port-proxy
%else
%{_initddir}/openshift-port-proxy
%endif
%{_bindir}/openshift-port-proxy-cfg
%config(noreplace) %{_sysconfdir}/openshift/port-proxy.cfg

%changelog
* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.8.2-1
- Cleaning specs (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)