Summary:       Daemon to create and maintain CNAME records for Avahi MDNS service
Name:          avahi-cname-manager
Version:       0.0.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      ruby
Requires:      rubygems
Requires:      rubygem(ruby-dbus)
Requires:      rubygem(sinatra)
Requires:      avahi 
Requires:      avahi-autoipd
Requires:      avahi-compat-libdns_sd
Requires:      avahi-glib
Requires:      avahi-gobject
Requires:      avahi-tools
Requires:      nss-mdns
Requires:      systemd-units
Requires(pre): shadow-utils
Requires(pre): coreutils
Requires(pre): /usr/bin/getent
Requires(pre): /usr/sbin/groupadd
BuildRequires: systemd-units
BuildArch:     noarch

%description
This package contains the avahi-cname-manager demon which can be used to configure and maintain CNAME entries for the
Avahi MDNS service. It exposes a REST based API to add and remove CNAME entries.

%prep
%setup -q

%build

%install
#  Runtime directories.
mkdir -p %{buildroot}%{_var}/lock/subsys
mkdir -p %{buildroot}%{_var}/run
mkdir -p %{buildroot}%{_var}/lib/avahi-cname-manager
mkdir -p %{buildroot}/etc/avahi
install -D -m 644 conf/cname-manager.conf %{buildroot}/etc/avahi/

mkdir -p %{buildroot}%{_unitdir}
install -D -m 644 systemd/avahi-cname-manager.service %{buildroot}%{_unitdir}
install -D -m 644 systemd/avahi-cname-manager.env %{buildroot}%{_sysconfdir}/sysconfig/avahi-cname-manager

mkdir -p %{buildroot}%{_bindir}
install -m 755 bin/avahi-cname-manager %{buildroot}%{_bindir}
touch %{buildroot}%{_var}/lib/avahi-cname-manager/aliases

%pre
/usr/bin/getent group avahi-cname >/dev/null 2>&1 || /usr/sbin/groupadd --system avahi-cname >/dev/null 2>&1 || :
/usr/bin/getent passwd avahi-cname >/dev/null 2>&1 || /usr/sbin/useradd --system --no-log-init -g avahi-cname \
        -d %{_localstatedir}/lib/avahi-cname-manager -s /sbin/nologin -c "Avahi mDNS/DNS-SD CNAME alias manager" \
        avahi-cname >/dev/null 2>&1 || :

%post
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart avahi-cname-manager.service

%preun
/bin/systemctl --no-reload disable avahi-cname-manager.service
/bin/systemctl stop avahi-cname-manager.service

%files
%attr(0644,-,-) %{_unitdir}/avahi-cname-manager.service
%attr(0644,-,-) %{_sysconfdir}/sysconfig/avahi-cname-manager
%attr(0755,-,-) %{_bindir}/avahi-cname-manager
%attr(0744,avahi-cname,avahi-cname) %{_var}/lib/avahi-cname-manager
%config %attr(0640,avahi-cname,avahi-cname) %{_var}/lib/avahi-cname-manager/aliases
%config /etc/avahi/cname-manager.conf

%doc LICENSE
%doc README

%changelog
* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.0.2-1
- Fix for add_alias on avahi-cname-manager (kraman@gmail.com)

* Sat Mar 09 2013 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

