%define webproxymoduledir %{_prefix}/lib/node_modules/openshift-node-web-proxy

Summary:        Routing proxy for OpenShift Origin Node
Name:           openshift-origin-node-proxy
Version:        0.2
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

mkdir -p %{buildroot}%{webproxymoduledir}/logger
install -D -m 644 logger/* %{buildroot}%{webproxymoduledir}/logger

mkdir -p %{buildroot}%{webproxymoduledir}/proxy
install -D -m 644 proxy/*  %{buildroot}%{webproxymoduledir}/proxy

mkdir -p %{buildroot}%{webproxymoduledir}/utils
install -D -m 644 utils/*  %{buildroot}%{webproxymoduledir}/utils

mkdir -p %{buildroot}%{webproxymoduledir}/bin
install -D -m 644 bin/*  %{buildroot}%{webproxymoduledir}/bin

mkdir -p %{buildroot}%{_var}/log/node-web-proxy
if [ ! -f %{buildroot}%{_var}/log/node-web-proxy/supervisor.log ]; then
   /bin/touch %{buildroot}%{_var}/log/node-web-proxy/supervisor.log
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
%attr(0755,-,-) %{_initddir}/openshift-node-web-proxy
%attr(0755,-,-) %{_bindir}/node-find-proxy-route-files
%attr(0640,-,-) %{_sysconfdir}/openshift/web-proxy-config.json
%ghost %attr(0660,root,root) %{_var}/log/node-web-proxy/supervisor.log
%dir %attr(0644,-,-) %{webproxymoduledir}
%{webproxymoduledir}

%doc LICENSE
%doc README

%changelog
* Tue Dec 04 2012 Ram Ranganathan <ramr@redhat.com> 0.2-1
- Rename to todo list. (ramr@redhat.com)

* Fri Nov 30 2012 Ram Ranganathan <ramr@redhat.com> 0.1-1
- new package built with tito


