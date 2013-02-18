%global htmldir %{_var}/www/html
%global openshiftconfigdir %{_var}/www/.openshift
%global consoledir %{_var}/www/openshift/console
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global with_systemd 0
    %global gemdir /opt/rh/ruby193/root/usr/share/gems/gems
%else
    %global with_systemd 1
    %global gemdir /usr/share/rubygems/gems
%endif
%{!?scl:%global pkg_name %{name}}

Summary:       The OpenShift Management Console
Name:          openshift-origin-console
Version:       0.4.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem-openshift-origin-console
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}mod_passenger
%if 0%{?rhel}
Requires:      %{?scl:%scl_prefix}rubygem-minitest
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      openshift-origin-util-scl
%endif
%if 0%{?fedora}
Requires:      openshift-origin-util
Requires:      v8-devel
Requires:      gcc-c++
%endif
BuildArch:     noarch
Provides:      openshift-origin-console = %{version}
Obsoletes:     openshift-console

%description
This contains the console configuration components of OpenShift.
This includes the configuration necessary to run the console with mod_passenger.

%prep
%setup -q

%build

%install
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
mkdir -p %{buildroot}%{consoledir}/httpd/conf
mkdir -p %{buildroot}%{consoledir}/httpd/conf.d
mkdir -p %{buildroot}%{consoledir}/tmp
mkdir -p %{buildroot}%{consoledir}/tmp/cache
mkdir -p %{buildroot}%{consoledir}/tmp/pids
mkdir -p %{buildroot}%{consoledir}/tmp/sessions
mkdir -p %{buildroot}%{consoledir}/tmp/sockets
mkdir -p %{buildroot}%{consoledir}/run
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{_var}/log/openshift/console/httpd

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

%if 0%{?fedora}
rm %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf
%endif
%if 0%{?rhel}
rm %{buildroot}%{consoledir}/httpd/console.conf
mv %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf %{buildroot}%{consoledir}/httpd/conf/console.conf
%endif

%if 0%{?fedora} >= 18
mv %{buildroot}%{consoledir}/httpd/httpd.conf.apache-2.4 %{buildroot}%{consoledir}/httpd/httpd.conf
%else
mv %{buildroot}%{consoledir}/httpd/httpd.conf.apache-2.3 %{buildroot}%{consoledir}/httpd/httpd.conf
%endif
rm %{buildroot}%{consoledir}/httpd/httpd.conf.apache-*

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
%{openshiftconfigdir}
%attr(0750,-,-) %{_var}/log/openshift/console/httpd
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/production.log
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/development.log
%attr(0750,-,-) %{consoledir}/script
%attr(0750,-,-) %{consoledir}/tmp
%attr(0750,-,-) %{consoledir}/tmp/cache
%attr(0750,-,-) %{consoledir}/tmp/pids
%attr(0750,-,-) %{consoledir}/tmp/sessions
%attr(0750,-,-) %{consoledir}/tmp/sockets
%dir %attr(0750,-,-) %{consoledir}/httpd/conf.d
%{consoledir}
%{htmldir}/console
%config %{consoledir}/config/environments/production.rb
%config %{consoledir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/openshift/console.conf

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
/bin/touch %{_var}/log/openshift/console/httpd/error_log
/bin/touch %{_var}/log/openshift/console/httpd/access_log

%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-console.service
%else
/sbin/chkconfig --add openshift-console || :
/sbin/service openshift-console condrestart || :
%endif

/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
%changelog
* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- finishing touches of move from openshift-console to openshift-origin-console
  (tdawson@redhat.com)

* Wed Jan 30 2013 Troy Dawson <tdawson@redhat.com> 0.4.1-1
- Change name from openshift-console to openshift-origin-console

* Tue Jan 22 2013 Troy Dawson <tdawson@redhat.com> 0.0.4-1
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)
- Marking the console configs as noreplace (bleanhar@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)
- BZ876937 - Return "FAILED" if trying to stop openshift-console which is
  already stopped (bleanhar@redhat.com)
- BZ878754 No CSRF attack protection in console (calfonso@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- ldap sample config was out of date on the passthrough name
  (calfonso@redhat.com)
- BZ874520 - There is no domain_suffix displayed at the end of app url...
  (calfonso@redhat.com)
- Removing version from minitest in openshift-console gemspec
  (calfonso@redhat.com)
- Merge pull request #853 from calfonso/master (openshift+bot@redhat.com)
- Merge pull request #851 from brenton/no_trace (openshift+bot@redhat.com)
- Removing unused boiler plate index.html from console (calfonso@redhat.com)
- BZ873970, BZ873966 - disabling HTTP TRACE for the Broker, Nodes and Console
  (bleanhar@redhat.com)
- BZ873940 - The rpm package openshift-console should delete the temp file
  (calfonso@redhat.com)
- BZ872492 - Should stop openshfit-console service when uninstall openshift-
  console package. (calfonso@redhat.com)
- Merge pull request #797 from calfonso/master (openshift+bot@redhat.com)
- Adding - to spec to make tito releasers work (calfonso@redhat.com)
- Setting the gemdir in the rpm spec (calfonso@redhat.com)
- BZ871786 - The urls of "My Applications","Create Application","Help","My
  Account" are not correct. *Modifying the app context path for the error pages
  (calfonso@redhat.com)

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

