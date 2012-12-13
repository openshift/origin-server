%define webproxymoduledir %{_prefix}/lib/node_modules/openshift-node-web-proxy

Summary:        Routing proxy for OpenShift Origin Node
Name:           openshift-origin-node-proxy
Version: 0.4.1
Release:        1%{?dist}

Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       nodejs
Requires:       nodejs-async
Requires:       nodejs-optimist
Requires:       nodejs-supervisor
Requires:       nodejs-ws
BuildArch:      noarch

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%define with_systemd 1
%else
%define with_systemd 0
%endif

%if %{with_systemd}
BuildRequires: systemd-units
Requires:  systemd-units
%endif

%description
This package contains a routing proxy (for handling HTTP[S] and Websockets
traffic) for an OpenShift Origin node.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}

#  Runtime directories.
mkdir -p %{buildroot}%{_var}/lock/subsys
mkdir -p %{buildroot}%{_var}/run


%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
install -D -m 644 scripts/systemd/openshift-node-web-proxy.service %{buildroot}%{_unitdir}
install -D -m 644 scripts/systemd/openshift-node-web-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-node-web-proxy

# TO DO: Fix systemd script.
mkdir -p %{buildroot}%{_sbindir}
# install -m 755 scripts/systemd/openshift-node-web-proxy %{buildroot}%{_sbindir}
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

mkdir -p %{buildroot}%{webproxymoduledir}/logger
install -D -m 644 logger/* %{buildroot}%{webproxymoduledir}/logger

mkdir -p %{buildroot}%{webproxymoduledir}/proxy
install -D -m 644 proxy/*  %{buildroot}%{webproxymoduledir}/proxy

mkdir -p %{buildroot}%{webproxymoduledir}/utils
install -D -m 644 utils/*  %{buildroot}%{webproxymoduledir}/utils

mkdir -p %{buildroot}%{webproxymoduledir}/bin
install -D -m 644 bin/*  %{buildroot}%{webproxymoduledir}/bin

mkdir -p %{buildroot}%{_var}/log/node-web-proxy
if [ ! -f %{buildroot}%{_var}/log/node-web-proxy/supervisor_log ]; then
   /bin/touch %{buildroot}%{_var}/log/node-web-proxy/supervisor_log
fi


%post
%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-node-web-proxy.service
%else
/sbin/chkconfig --add openshift-node-web-proxy || :
/sbin/service openshift-node-web-proxy restart || :
%endif

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-node-web-proxy.service
   /bin/systemctl stop openshift-node-web-proxy.service
%else
   /sbin/service openshift-node-web-proxy stop || :
   /sbin/chkconfig --del openshift-node-web-proxy || :
%endif
fi


%clean
rm -rf $RPM_BUILD_ROOT

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
%ghost %attr(0660,root,root) %{_var}/log/node-web-proxy/supervisor_log
%dir %attr(0700,apache,apache) %{_var}/log/node-web-proxy
%dir %attr(0755,-,-) %{webproxymoduledir}
%{webproxymoduledir}

%doc LICENSE
%doc README

%changelog
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


