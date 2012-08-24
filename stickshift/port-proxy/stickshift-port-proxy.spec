Summary:       Script to configure HAProxy to do port forwarding from internal to external port
Name:          stickshift-port-proxy
Version: 0.2.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       stickshift-port-proxy-%{version}.tar.gz

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%define with_systemd 1
%else
%define with_systemd 0
%endif

BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:      haproxy
Requires:      procmail
%if %{with_systemd}
BuildRequires: systemd-units
Requires:  systemd-units
%endif
BuildArch:     noarch



%description
Script to configure HAProxy to do port forwarding from internal to external port

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT

%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig/stickshift-proxy
%else
mkdir -p %{buildroot}%{_initddir}
%endif
mkdir -p %{buildroot}%{_localstatedir}/lib/stickshift/.stickshift-proxy.d
mkdir -p %{buildroot}%{_sysconfdir}/stickshift
mkdir -p %{buildroot}%{_bindir}

%if %{with_systemd}
install -m 644 systemd/stickshift-proxy.service %{buildroot}%{_unitdir}
install -m 644 systemd/stickshift-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/stickshift-proxy
%else
install -m 755 init-scripts/stickshift-proxy %{buildroot}%{_initddir}
%endif
install -m 644 config/stickshift-proxy.cfg %{buildroot}%{_sysconfdir}/stickshift/
install -m 755 bin/stickshift-proxy-cfg %{buildroot}%{_bindir}/stickshift-proxy-cfg

%clean
rm -rf $RPM_BUILD_ROOT

%post
# Enable proxy and fix if the config file is missing
if ! [ -f /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg ]; then
   cp /etc/stickshift/stickshift-proxy.cfg /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg
   restorecon /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg || :
fi
/sbin/restorecon /var/lib/stickshift/.stickshift-proxy.d/ || :

%if %{with_systemd}
systemctl --system daemon-reload
%else
/sbin/chkconfig --add stickshift-proxy || :
/sbin/service stickshift-proxy condrestart || :
%endif

%preun
if [ "$1" -eq "0" ]; then
   /sbin/chkconfig --del stickshift-proxy || :
fi

%triggerin -- haproxy
/sbin/service stickshift-proxy condrestart

%files
%defattr(-,root,root,-)
%if %{with_systemd}
%attr(0644,-,-) %{_unitdir}/stickshift-proxy.service
%attr(0644,-,-) %{_sysconfdir}/sysconfig/stickshift-proxy
%else
%attr(0750,-,-) %{_initddir}/stickshift-proxy
%endif
%attr(0755,-,-) %{_bindir}/stickshift-proxy-cfg
%dir %attr(0750,root,root) %{_localstatedir}/lib/stickshift/.stickshift-proxy.d
%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/stickshift/stickshift-proxy.cfg

%changelog
* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.1.4-1
- BZ 848500: Isolate hiccups during editing. (rmillner@redhat.com)
- Coalesce the reload requests and force reload to finish after 30 seconds.
  Use flock instead of lockfile so locks die if the script does.
  (rmillner@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.1.3-1
- Restart proxy if its been stopped. (rmillner@redhat.com)
- BZ 845332: Separate out configuration file management from the init script so
  that systemd properly interprets the daemon restart. (rmillner@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.1.2-1
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Automatic commit of package [stickshift-port-proxy] release [0.0.1-1].
  (kraman@gmail.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

