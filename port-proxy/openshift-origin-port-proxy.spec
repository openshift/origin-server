Summary:       Script to configure HAProxy to do port forwarding from internal to external port
Name:          openshift-origin-port-proxy
Version: 0.3.4
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       openshift-origin-port-proxy-%{version}.tar.gz
BuildArch:     noarch

# The haproxy daemon is used as the functioning tcp proxy
Requires:      haproxy

# Stickshift node configuration and /etc/openshift
Requires:      rubygem(openshift-origin-node)


%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%define with_systemd 1
%else
%define with_systemd 0
%endif


%description
Script to configure HAProxy to do port forwarding from internal to external port

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT

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
install -m 644 systemd/openshift-origin-port-proxy.service %{buildroot}%{_unitdir}
install -m 644 systemd/openshift-origin-port-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-origin-port-proxy
install -m 755 systemd/openshift-origin-port-proxy %{buildroot}%{_sbindir}
%else
install -m 755 init-scripts/openshift-origin-port-proxy %{buildroot}%{_initddir}
%endif
install -m 644 config/openshift-origin-port-proxy.cfg %{buildroot}%{_sysconfdir}/openshift/
install -m 755 bin/openshift-origin-port-proxy-cfg %{buildroot}%{_bindir}/openshift-origin-port-proxy-cfg

%post
%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-origin-port-proxy.service
%else
/sbin/chkconfig --add openshift-origin-port-proxy || :
/sbin/service openshift-origin-port-proxy condrestart || :
%endif

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-origin-port-proxy.service
   /bin/systemctl stop openshift-origin-port-proxy.service
%else
   /sbin/service openshift-origin-port-proxy stop || :
   /sbin/chkconfig --del openshift-origin-port-proxy || :
%endif
fi

%files
%defattr(-,root,root,-)
%doc LICENSE
%if %{with_systemd}
%{_unitdir}/openshift-origin-port-proxy.service
%{_sysconfdir}/sysconfig/openshift-origin-port-proxy
%{_sbindir}/openshift-origin-port-proxy
%else
%{_initddir}/openshift-origin-port-proxy
%endif
%{_bindir}/openshift-origin-port-proxy-cfg
%config(noreplace) %{_sysconfdir}/openshift/openshift-origin-port-proxy.cfg

%changelog
* Thu Oct 04 2012 Krishna Raman <kraman@gmail.com> 0.3.4-1
- new package built with tito

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.3.3-1
- add license information, as requested by Fedora packages guidelines
  (mscherer@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.3.2-1
- Fedora review feedback: Get rid of .openshift-origin-port-proxy.d (rmillner@redhat.com)
- Fedora review feedback: Fix requires and use of "/var". (rmillner@redhat.com)
- BZ 856910: haproxy is found in /usr/sbin. (rmillner@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.2.4-1
- Merge pull request #474 from rmillner/proxy-fedora (openshift+bot@redhat.com)
- Fedora 17 systemd support requres a wrapper which is LSB compliant.
  (rmillner@redhat.com)

* Tue Sep 11 2012 Troy Dawson <tdawson@redhat.com> 0.2.3-1
- Move configuration file to /etc; leave lock files and reload requests in
  /var/lib/openshift. (rmillner@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.2.2-1
- fixing OpenShift Origin port proxy for fedora (abhgupta@redhat.com)
- fixing OpenShift Origin port proxy rpm for fedora (abhgupta@redhat.com)
- Merge pull request #426 from rmillner/f17proxy (openshift+bot@redhat.com)
- Add systemd version of openshift-origin-port-proxy. (rmillner@redhat.com)
- Shuffle responsibilities so that the systemd script and init script follow
  the same flow. (rmillner@redhat.com)

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
- Automatic commit of package [openshift-origin-port-proxy] release [0.0.1-1].
  (kraman@gmail.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

