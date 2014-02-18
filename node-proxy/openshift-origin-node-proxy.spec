%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
  %global with_systemd 1
  %global webproxymoduledir %{nodejs_sitelib}/openshift-node-web-proxy
%else
  %global with_systemd 0
  %global scl nodejs010
  %global scl_prefix nodejs010-
  %global webproxymoduledir /opt/rh/nodejs010/root%{nodejs_sitelib}/openshift-node-web-proxy
%endif
%{!?scl:%global pkg_name %{name}}

Summary:       Routing proxy for OpenShift Origin Node
Name:          openshift-origin-node-proxy
Version: 1.20.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}nodejs
Requires:      %{?scl:%scl_prefix}nodejs-async
Requires:      %{?scl:%scl_prefix}nodejs-optimist
Requires:      %{?scl:%scl_prefix}nodejs-supervisor
Requires:      %{?scl:%scl_prefix}nodejs-ws
%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: nodejs010-build
BuildRequires: scl-utils-build
%else
BuildRequires: nodejs-devel
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
install -D -p -m 644 scripts/systemd/openshift-node-web-proxy.service %{buildroot}%{_unitdir}
install -D -p -m 644 scripts/systemd/openshift-node-web-proxy.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-node-web-proxy
%else
mkdir -p %{buildroot}%{_initddir}
install -D -p -m 755 scripts/init.d/openshift-node-web-proxy %{buildroot}%{_initddir}
%endif

mkdir -p %{buildroot}%{_bindir}
install -p -m 755 scripts/bin/node-find-proxy-route-files %{buildroot}%{_bindir}

mkdir -p %{buildroot}%{_sysconfdir}/openshift
install -D -p -m 640 config/web-proxy-config.json  %{buildroot}%{_sysconfdir}/openshift

mkdir -p %{buildroot}%{_sysconfdir}/logrotate.d
%if %{with_systemd}
install -D -p -m 644 config/logrotate.d/openshift-node-web-proxy.systemd %{buildroot}%{_sysconfdir}/logrotate.d/%{name}
%else
install -D -p -m 644 config/logrotate.d/openshift-node-web-proxy.service %{buildroot}%{_sysconfdir}/logrotate.d/%{name}
%endif

mkdir -p %{buildroot}%{webproxymoduledir}
install -D -p -m 644 index.js %{buildroot}%{webproxymoduledir}
install -D -p -m 644 README   %{buildroot}%{webproxymoduledir}

mkdir -p %{buildroot}%{webproxymoduledir}/lib
install -D -p -m 644 lib/node-proxy.js %{buildroot}%{webproxymoduledir}/lib

mkdir -p %{buildroot}%{webproxymoduledir}/lib/logger
install -D -p -m 644 lib/logger/* %{buildroot}%{webproxymoduledir}/lib/logger

mkdir -p %{buildroot}%{webproxymoduledir}/lib/proxy
install -D -p -m 644 lib/proxy/* %{buildroot}%{webproxymoduledir}/lib/proxy

mkdir -p %{buildroot}%{webproxymoduledir}/lib/utils
install -D -p -m 644 lib/utils/* %{buildroot}%{webproxymoduledir}/lib/utils

mkdir -p %{buildroot}%{webproxymoduledir}/lib/plugins
install -D -p -m 644 lib/plugins/* %{buildroot}%{webproxymoduledir}/lib/plugins

mkdir -p %{buildroot}%{webproxymoduledir}/bin
install -D -p -m 644 bin/*  %{buildroot}%{webproxymoduledir}/bin

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
%attr(0644,-,-) %{_sysconfdir}/logrotate.d/%{name}
%ghost %attr(0660,root,root) %{_var}/log/node-web-proxy/supervisor.log
%dir %attr(0700,apache,apache) %{_var}/log/node-web-proxy
%dir %attr(0755,-,-) %{webproxymoduledir}
%{webproxymoduledir}

%doc LICENSE
%doc README

%changelog
* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Don't override supervisor log on restart. (mrunalp@gmail.com)
- Cleaning specs (dmcphers@redhat.com)
- Changes for supporting frontend paths in node web proxy. (mrunalp@gmail.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Bug 1032599: Set the headers on the original request. (mrunalp@gmail.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- fix node-proxy version to resolve tag conflicts (admiller@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.17.4-1
- Merge pull request #4445 from vbatts/bz1042938
  (dmcphers+openshiftbot@redhat.com)
- catching an exception if the proxy connection is closed (vbatts@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.17.3-1
- Merge pull request #4269 from debug-ito/master
  (dmcphers+openshiftbot@redhat.com)
- Add support for passing through Origin header. (debug.ito@gmail.com)