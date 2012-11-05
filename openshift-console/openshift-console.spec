%define htmldir %{_localstatedir}/www/html
%define openshiftconfigdir %{_localstatedir}/www/.openshift
%define consoledir %{_localstatedir}/www/openshift/console
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}

Summary:   The OpenShift Enterprise Management Console
Name:      openshift-console
Version:   0.0.3
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   openshift-console-%{version}.tar.gz

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%define with_systemd 1
%global gemdir /usr/share/rubygems/gems
%else
%define with_systemd 0
%global gemdir /opt/rh/ruby193/root/usr/share/gems/gems
%endif

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:  rubygem-openshift-origin-console
Requires:  %{?scl:%scl_prefix}rubygem-passenger
Requires:  %{?scl:%scl_prefix}rubygem-passenger-native
Requires:  %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:  %{?scl:%scl_prefix}mod_passenger
Requires:  %{?scl:%scl_prefix}rubygem-minitest
Requires:  %{?scl:%scl_prefix}rubygem-therubyracer
BuildArch: noarch

%description
This contains the console configuration components of OpenShift.
This includes the configuration necessary to run the console with mod_passenger.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
%else
mkdir -p %{buildroot}%{_initddir}
%endif
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{openshiftconfigdir}
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{consoledir}
mkdir -p %{buildroot}%{consoledir}/httpd/root
mkdir -p %{buildroot}%{consoledir}/httpd/run
mkdir -p %{buildroot}%{consoledir}/httpd/logs
mkdir -p %{buildroot}%{consoledir}/httpd/conf
mkdir -p %{buildroot}%{consoledir}/httpd/conf.d
mkdir -p %{buildroot}%{consoledir}/log
mkdir -p %{buildroot}%{consoledir}/tmp
mkdir -p %{buildroot}%{consoledir}/run
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sysconfdir}/openshift

cp -r . %{buildroot}%{consoledir}
%if %{with_systemd}
mv %{buildroot}%{consoledir}/systemd/openshift-console.service %{buildroot}%{_unitdir}
mv %{buildroot}%{consoledir}/systemd/openshift-console.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-console
%else
mv %{buildroot}%{consoledir}/init.d/* %{buildroot}%{_initddir}
rm -rf %{buildroot}%{consoledir}/init.d
%endif

ln -s %{consoledir}/public %{buildroot}%{htmldir}/console
mv %{buildroot}%{consoledir}/etc/openshift/* %{buildroot}%{_sysconfdir}/openshift
rm -rf %{buildroot}%{consoledir}/etc
mv %{buildroot}%{consoledir}/.openshift/api.yml %{buildroot}%{openshiftconfigdir}
ln -sf /usr/lib64/httpd/modules %{buildroot}%{consoledir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{consoledir}/httpd/conf/magic

%clean
rm -rf $RPM_BUILD_ROOT

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-console.service
   /bin/systemctl stop openshift-console.service
%else
   /sbin/service openshift-console stop || :
   /sbin/chkconfig --del openshift-console || :
%endif
fi

%files
%defattr(0640,apache,apache,0750)
%attr(0750,apache,apache) %{consoledir}/script
%{consoledir}
%{htmldir}/console
%{openshiftconfigdir}
%{_sysconfdir}/openshift/console.conf

%defattr(0640,root,root,0750)
%if %{with_systemd}
%{_unitdir}/openshift-console.service
%attr(0644,-,-) %{_unitdir}/openshift-console.service
%{_sysconfdir}/sysconfig/openshift-console
%attr(0644,-,-) %{_sysconfdir}/sysconfig/openshift-console
%else
%{_initddir}/openshift-console
%attr(0750,-,-) %{_initddir}/openshift-console
%endif

%post
/bin/touch %{consoledir}/httpd/logs/error_log
/bin/touch %{consoledir}/httpd/logs/access_log

%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-console.service
%else
/sbin/chkconfig --add openshift-console || :
/sbin/service openshift-console condrestart || :
%endif

#selinux updated
semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
boolean -m --on httpd_execmem
fcontext -a -t httpd_var_run_t '%{consoledir}/httpd/run(/.*)?'
fcontext -a -t httpd_log_t '%{consoledir}/httpd/logs(/.*)?'
_EOF

chcon -R -t httpd_log_t %{consoledir}/httpd/logs
chcon -R -t httpd_tmp_t %{consoledir}/httpd/run
chcon -R -t httpd_var_run_t %{consoledir}/httpd/run
/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
/sbin/restorecon -rv %{gemdir}/passenger*
%changelog
* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Bug 871705 - renaming a sample conf file for consistency
  (bleanhar@redhat.com)
- Restorecon takes scl into consideration (calfonso@redhat.com)

* Mon Oct 29 2012 Chris Alfonso <calfonso@redhat.com> 0.0.2-1
- new package built with tito

* Fri Oct 26 2012 Unknown name 0.0.1-1
- new package built with tito

* Fri Oct 26 2012 Unknown name 0.0.1-1
- new package built with tito

