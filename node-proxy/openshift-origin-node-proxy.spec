%global webproxymoduledir %{_prefix}/lib/node_modules/openshift-node-web-proxy
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%else
%global with_systemd 0
%endif

Summary:       Routing proxy for OpenShift Origin Node
Name:          openshift-origin-node-proxy
Version: 0.10.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      nodejs
Requires:      nodejs-async
Requires:      nodejs-optimist
Requires:      nodejs-supervisor
Requires:      nodejs-ws
%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch

%description
This package contains a routing proxy (for handling HTTP[S] and Websockets
traffic) for an OpenShift Origin node.

%prep
%setup -q

%build

%install
#  Runtime directories.
mkdir -p %{buildroot}%{_var}/lock/subsys
mkdir -p %{buildroot}%{_var}/run


%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
install -D -m 644 scripts/systemd/openshift-node-web-proxy.service %{buildroot}%{_unitdir}
install -D -m 644 scripts/systemd/openshift-node-web-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-node-web-proxy
%else
mkdir -p %{buildroot}%{_initddir}
install -D -m 755 scripts/init.d/openshift-node-web-proxy %{buildroot}%{_initddir}
%endif

mkdir -p %{buildroot}%{_bindir}
install -m 755 scripts/bin/node-find-proxy-route-files %{buildroot}%{_bindir}

mkdir -p %{buildroot}%{_sysconfdir}/openshift
install -D -m 640 config/web-proxy-config.json  %{buildroot}%{_sysconfdir}/openshift

mkdir -p %{buildroot}%{_sysconfdir}/logrotate.d
install -D -m 644 config/logrotate.d/openshift-node-web-proxy %{buildroot}%{_sysconfdir}/logrotate.d

mkdir -p %{buildroot}%{webproxymoduledir}
install -D -m 644 index.js %{buildroot}%{webproxymoduledir}
install -D -m 644 README   %{buildroot}%{webproxymoduledir}

mkdir -p %{buildroot}%{webproxymoduledir}/lib
install -D -m 644 lib/node-proxy.js %{buildroot}%{webproxymoduledir}/lib

mkdir -p %{buildroot}%{webproxymoduledir}/lib/logger
install -D -m 644 lib/logger/* %{buildroot}%{webproxymoduledir}/lib/logger

mkdir -p %{buildroot}%{webproxymoduledir}/lib/proxy
install -D -m 644 lib/proxy/* %{buildroot}%{webproxymoduledir}/lib/proxy

mkdir -p %{buildroot}%{webproxymoduledir}/lib/utils
install -D -m 644 lib/utils/* %{buildroot}%{webproxymoduledir}/lib/utils

mkdir -p %{buildroot}%{webproxymoduledir}/lib/plugins
install -D -m 644 lib/plugins/* %{buildroot}%{webproxymoduledir}/lib/plugins

mkdir -p %{buildroot}%{webproxymoduledir}/bin
install -D -m 644 bin/*  %{buildroot}%{webproxymoduledir}/bin

mkdir -p %{buildroot}%{_var}/log/node-web-proxy
if [ ! -f %{buildroot}%{_var}/log/node-web-proxy/supervisor.log ]; then
   /bin/touch %{buildroot}%{_var}/log/node-web-proxy/supervisor.log
fi


%post
%if %{with_systemd}
/bin/systemctl --system daemon-reload
%else
/sbin/chkconfig --add openshift-node-web-proxy || :
%endif

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-node-web-proxy.service
%else
   /sbin/chkconfig --del openshift-node-web-proxy || :
%endif
fi


%files
%if %{with_systemd}
%attr(0644,-,-) %{_unitdir}/openshift-node-web-proxy.service
%attr(0644,-,-) %{_sysconfdir}/sysconfig/openshift-node-web-proxy
%else
%attr(0755,-,-) %{_initddir}/openshift-node-web-proxy
%endif
%attr(0755,-,-) %{_bindir}/node-find-proxy-route-files
%attr(0640,-,-) %{_sysconfdir}/openshift/web-proxy-config.json
%attr(0644,-,-) %{_sysconfdir}/logrotate.d/openshift-node-web-proxy
%ghost %attr(0660,root,root) %{_var}/log/node-web-proxy/supervisor.log
%dir %attr(0700,apache,apache) %{_var}/log/node-web-proxy
%dir %attr(0755,-,-) %{webproxymoduledir}
%{webproxymoduledir}

%doc LICENSE
%doc README

%changelog
* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.9.2-1
- <node-proxy,port-proxy> Bug 964212 - Fix init script dependencies
  (jdetiber@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.9.1-1
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.8.2-1
- We don't want the installation of the node-proxy to auto launch the service
  (bleanhar@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.8.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.7.3-1
- bug 922922 - change supervisor_log to supervisor.log for log rotation.
  (rmillner@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.7.2-1
- Origin RHEL & Fedora build fixes. (rmillner@redhat.com)
- use restart instead of reload. (blentz@redhat.com)
- correct openshift-node-web-proxy logrotate to match all log files.
  (blentz@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 0.6.6-1
- BZ 905647: Push down cookies to ws lib. (mrunalp@gmail.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 0.6.5-1
- BZ914838: Fix uri parsing. (mrunalp@gmail.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 0.6.4-1
- Skip migrated directories when finding the new routes. (rmillner@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 0.6.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 0.6.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Fix for node proxy file list getting truncated. (mrunalp@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 0.4.3-1
- Cleanup init script display + handle "whacked" pids on restarts (stop).
  (ramr@redhat.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Case-insensitive vhost routing support. (ramr@redhat.com)
- Plugin work, rearrange bits, add help, fix spec file. (ramr@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 0.3.3-1
- Fix for bugz 886668 - openshift-node-web-proxy sets incorrect header.
  (ramr@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #1050 from ramr/master (openshift+bot@redhat.com)
- Merge pull request #1045 from kraman/f17_fixes (openshift+bot@redhat.com)
- Fix for bugz 885784 - run proxy as apache instead of root. (ramr@redhat.com)
- Fix bugz - log to access.log + websockets.log + log file rollover. And update
  idler's last access script to use the new node-web-proxy access.log file.
  (ramr@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 0.3.1-1
- fix node-proxy versioning (admiller@redhat.com)

* Tue Dec 04 2012 Ram Ranganathan <ramr@redhat.com> 0.3-1
- Add empty readme file. (ramr@redhat.com)

* Tue Dec 04 2012 Ram Ranganathan <ramr@redhat.com> 0.2-1
- Rename to todo list. (ramr@redhat.com)

* Fri Nov 30 2012 Ram Ranganathan <ramr@redhat.com> 0.1-1
- new package built with tito


