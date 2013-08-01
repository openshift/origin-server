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
%global rubyabi 1.9.1

Summary:       The OpenShift Management Console
Name:          openshift-origin-console
Version:       1.10.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem-openshift-origin-console
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}mod_passenger

%if 0%{?scl:1}
Requires:      %{?scl:%scl_prefix}ruby-wrapper
Requires:      %{?scl:%scl_prefix}rubygem-minitest
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      openshift-origin-util-scl
%endif
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-compass-rails
Requires:      %{?scl:%scl_prefix}rubygem-test-unit
Requires:      %{?scl:%scl_prefix}rubygem-ci_reporter
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-rdiscount
Requires:      %{?scl:%scl_prefix}rubygem-formtastic
Requires:      %{?scl:%scl_prefix}rubygem-net-http-persistent
Requires:      %{?scl:%scl_prefix}rubygem-haml
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      %{?scl:%scl_prefix}rubygem-minitest
Requires:      %{?scl:%scl_prefix}rubygems-devel
Requires:      %{?scl:%scl_prefix}rubygem-coffee-rails
Requires:      %{?scl:%scl_prefix}rubygem-jquery-rails
Requires:      %{?scl:%scl_prefix}rubygem-uglifier
Requires:      %{?scl:%scl_prefix}rubygem-poltergeist
Requires:      %{?scl:%scl_prefix}rubygem-webmock
Requires:      %{?scl:%scl_prefix}rubygem-capybara

%if 0%{?fedora}
Requires:      openshift-origin-util
Requires:      v8-devel
Requires:      gcc-c++
%endif

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires: %{?scl:%scl_prefix}rubygem-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-compass-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-test-unit
BuildRequires: %{?scl:%scl_prefix}rubygem-ci_reporter
BuildRequires: %{?scl:%scl_prefix}rubygem-sprockets
BuildRequires: %{?scl:%scl_prefix}rubygem-rdiscount
BuildRequires: %{?scl:%scl_prefix}rubygem-formtastic
BuildRequires: %{?scl:%scl_prefix}rubygem-net-http-persistent
BuildRequires: %{?scl:%scl_prefix}rubygem-haml
BuildRequires: %{?scl:%scl_prefix}rubygem-therubyracer
BuildRequires: %{?scl:%scl_prefix}rubygem-minitest
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildRequires: %{?scl:%scl_prefix}rubygem-coffee-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-jquery-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-uglifier
BuildRequires: %{?scl:%scl_prefix}rubygem-poltergeist
BuildRequires: %{?scl:%scl_prefix}rubygem-webmock
BuildRequires: %{?scl:%scl_prefix}rubygem-capybara

%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: rubygem-openshift-origin-console

BuildArch:     noarch
Provides:      openshift-origin-console = %{version}
Obsoletes:     openshift-console

%description
This contains the console configuration components of OpenShift.
This includes the configuration necessary to run the console with mod_passenger.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}

set -e
%if 0%{?fedora}%{?rhel} <= 6
rm -f Gemfile.lock
bundle install --local

mkdir -p %{buildroot}%{_var}/log/openshift/console/
mkdir -p -m 770 %{buildroot}%{_var}/log/openshift/console/httpd/
touch %{buildroot}%{_var}/log/openshift/console/production.log
chmod 0666 %{buildroot}%{_var}/log/openshift/console/production.log

CONSOLE_CONFIG_FILE=etc/openshift/console.conf \
  RAILS_ENV=production \
  RAILS_LOG_PATH=%{buildroot}%{_var}/log/openshift/console/production.log \
  RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
echo > %{buildroot}%{_var}/log/openshift/console/production.log

find . -name .gitignore -delete
find . -name .gitkeep -delete

rm -rf %{buildroot}%{_var}/log/openshift/*
rm -f Gemfile.lock
%endif
%{?scl:EOF}


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
%endif
rm -rf %{buildroot}%{consoledir}/init.d
rm -rf %{buildroot}%{consoledir}/systemd

ln -s %{consoledir}/public %{buildroot}%{htmldir}/console
mv %{buildroot}%{consoledir}/etc/openshift/* %{buildroot}%{_sysconfdir}/openshift
cp %{buildroot}%{_sysconfdir}/openshift/console.conf %{buildroot}%{_sysconfdir}/openshift/console-dev.conf
rm -rf %{buildroot}%{consoledir}/etc
mv %{buildroot}%{consoledir}/.openshift/api.yml %{buildroot}%{openshiftconfigdir}
ln -sf /usr/lib64/httpd/modules %{buildroot}%{consoledir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{consoledir}/httpd/conf/magic

%if 0%{?fedora}
rm %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf
%endif
%if 0%{?rhel}
rm %{buildroot}%{consoledir}/httpd/console.conf
mv %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf %{buildroot}%{consoledir}/httpd/console.conf
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
%attr(0750,-,-) %{_var}/log/openshift/console
%attr(0750,-,-) %{_var}/log/openshift/console/httpd
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/production.log
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/development.log
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/httpd/error_log
%attr(0644,-,-) %ghost %{_var}/log/openshift/console/httpd/access_log
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
%config(noreplace) %{_sysconfdir}/openshift/console-dev.conf

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

#selinux updated
/usr/sbin/semanage -i - <<_EOF
fcontext -a -t httpd_log_t '%{_var}/log/openshift/console(/.*)?'
fcontext -a -t httpd_log_t '%{_var}/log/openshift/console/httpd(/.*)?'
fcontext -a -t httpd_var_run_t '%{consoledir}/httpd/run(/.*)?'
_EOF
/sbin/restorecon -R %{_var}/log/openshift/console
/sbin/restorecon -R %{consoledir}

/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
%changelog
* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- Bump up version (tdawson@redhat.com)
- Added psych dependency to openshift-console if psych has been split into a
  separate gem. (kraman@gmail.com)
- Loosen requirements on ci_reporter and minitest gems to we can use the
  version distributed with fedora (kraman@gmail.com)
- Relax rake and mocha gem version dependencies (kraman@gmail.com)
- Bug 968834: fix `service openshift-console reload` (tbielawa@redhat.com)
- <openshift-console> - Run restorecon on ${consoledir} in %%post
  (jdetiber@redhat.com)
- <openshift-console> Bug 961888 - Fix SELinux context for httpd run dir
  (jdetiber@redhat.com)
- <console> Bug 959162 - Fix display issues (jdetiber@redhat.com)
- <openshift-console> - Bug 957818 Update boot.rb to default to production env
  (jdetiber@redhat.com)
- Bug 956625 - Cleanup some BuildRequires that were added for this bug
  (jdetiber@redhat.com)
- Bug 956625 - Updating to precompile the origin console assets during RPM
  build (jdetiber@redhat.com)
- Bug 956561 - No available console log file generated. (bleanhar@redhat.com)
- Fix find/delete command for openshift-console and console packages. Bug
  888714. (kraman@gmail.com)
- Bug 888714 - Remove .gitkeep and .gitignore (ccoleman@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.5.18-1
- Add a few base URLs and helpers for fetching assets during static page
  compilation (ccoleman@redhat.com)
- Merge pull request #1814 from smarterclayton/helpers_out_of_date
  (dmcphers+openshiftbot@redhat.com)
- Helpers in openshift-console out of date (ccoleman@redhat.com)
- Adding SESSION_SECRET settings to the broker and console
  (bleanhar@redhat.com)
- Origin RHEL & Fedora build fixes. (rmillner@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.17-1
- Fixing console log file SELinux context and permissions (kraman@gmail.com)
- Merge pull request #1456 from rclsilver/master
  (dmcphers+openshiftbot@redhat.com)
- BZ913376 - The favicon cannot be displayed (calfonso@redhat.com)
- BZ896363 - 'the User Guide' link should redirect to an existing url
  (calfonso@redhat.com)
- Merge pull request #1535 from brenton/gemfile_lock_fixes
  (dmcphers+openshiftbot@redhat.com)
- Gemfile.lock ownership fixes (bleanhar@redhat.com)
- Bug 916495 - Community still points incorrectly to some incorrect URLs
  (ccoleman@redhat.com)
- Configuration file 'console.conf' was placed in the wrong location:
  httpd/conf instead of httpd (thomas@betrancourt.net)
- Add the PassengerRuby parameter to avoid an error while searching libruby
  1.9.3 (thomas@betrancourt.net)
- Set logs location in /var/log/openshift/console/httpd as the broker httpd
  (thomas@betrancourt.net)
- The community URL is not available for some operations - use the default
  config if that is true (ccoleman@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Apply changes from comments. Fix diffs from brenton/origin-server.
  (john@ibiblio.org)
- Fixes for ruby193 (john@ibiblio.org)
- move logs to a more standard location (admiller@redhat.com)
- change %%define to %%global (tdawson@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)
- remove BuildRoot: (tdawson@redhat.com)
- Fix FireSass support in origin (ccoleman@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.16-1
- Update to version 1.5.16

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

