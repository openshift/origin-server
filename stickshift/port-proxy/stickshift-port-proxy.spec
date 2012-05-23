Summary:       Script to configure HAProxy to do port forwarding from internal to external port
Name:          stickshift-port-proxy
Version:       0.0.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       stickshift-port-proxy-%{version}.tar.gz

BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:      haproxy
Requires:      procmail
BuildArch:     noarch

%description
Script to configure HAProxy to do port forwarding from internal to external port

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p %{buildroot}%{_initddir}
mkdir -p %{buildroot}%{_localstatedir}/lib/stickshift/.stickshift-proxy.d
mkdir -p %{buildroot}%{_sysconfdir}/stickshift

mv init-scripts/stickshift-proxy %{buildroot}%{_initddir}
mv config/stickshift-proxy.cfg %{buildroot}%{_sysconfdir}/stickshift/

%clean
rm -rf $RPM_BUILD_ROOT

%post
# Enable proxy and fix if the config file is missing
/sbin/chkconfig --add stickshift-proxy || :
if ! [ -f /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg ]; then
   cp /etc/stickshift/stickshift-proxy.cfg /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg
   restorecon /var/lib/stickshift/.stickshift-proxy.d/stickshift-proxy.cfg || :
fi
/sbin/restorecon /var/lib/stickshift/.stickshift-proxy.d/ || :
/sbin/service stickshift-proxy condrestart || :

%preun
if [ "$1" -eq "0" ]; then
   /sbin/chkconfig --del stickshift-proxy || :
fi

%triggerin -- haproxy
/sbin/service stickshift-proxy condrestart

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{_initddir}/stickshift-proxy
%dir %attr(0750,root,root) %{_localstatedir}/lib/stickshift/.stickshift-proxy.d
%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/stickshift/stickshift-proxy.cfg

%changelog
