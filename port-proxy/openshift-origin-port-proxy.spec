%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Script to configure HAProxy to do port forwarding for OpenShift
Name:          openshift-origin-port-proxy
Version: 1.8.1
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
* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Bug 973984 - Inheriting the lock file FDs was causing AVC denials.
  (rmillner@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- <node-proxy,port-proxy> Bug 964212 - Fix init script dependencies
  (jdetiber@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Bug 928675 (asari.ruby@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Cleanup tmpfile usage (rmillner@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Bug 912819 (bdecoste@gmail.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.2.2-1
- remove BuildRoot: (tdawson@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ876939 - Return "FAILED" if trying to stop openshift-port-proxy which is
  already stopped (bleanhar@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- updated spec file to be in line with fedora (tdawson@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.3.6-1
- Fix 'Obsoletes' for jbosseap6, port-proxy, mongodb-2.2, and diy
  (pmorie@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.3.5-1
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.3.4-1
- new package built with tito

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.3.3-1
- add license information, as requested by Fedora packages guidelines
  (mscherer@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.3.2-1
- Fedora review feedback: Get rid of .openshift-port-proxy.d (rmillner@redhat.com)
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
- Add systemd version of openshift-port-proxy. (rmillner@redhat.com)
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
- Automatic commit of package [openshift-port-proxy] release [0.0.1-1].
  (kraman@gmail.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

