%define htmldir %{_localstatedir}/www/html
%define brokerdir %{_localstatedir}/www/stickshift/broker

Summary:   StickShift broker components
Name:      stickshift-broker
Version:   0.6.7
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   stickshift-broker-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:  httpd
Requires:  bind
Requires:  mod_ssl
Requires:  mod_passenger
Requires:  mongodb-server
Requires:  rubygem(rails)
Requires:  rubygem(xml-simple)
Requires:  rubygem(bson_ext)
Requires:  rubygem(rest-client)
Requires:  rubygem(thread-dump)
Requires:  rubygem(parseconfig)
Requires:  rubygem(json)
Requires:  rubygem(multimap)
Requires:  rubygem(stickshift-controller)
Requires:  rubygem(passenger)
Requires:  rubygem(rcov)
Requires:  stickshift-abstract
Requires:  rubygem-passenger-native
Requires:  rubygem-passenger-native-libs
BuildArch: noarch

%description
This contains the broker 'controlling' components of StickShift.
This includes the public APIs for the client tools.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_initddir}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{brokerdir}
mkdir -p %{buildroot}%{brokerdir}/httpd/root
mkdir -p %{buildroot}%{brokerdir}/httpd/run
mkdir -p %{buildroot}%{brokerdir}/httpd/logs
mkdir -p %{buildroot}%{brokerdir}/httpd/conf
mkdir -p %{buildroot}%{brokerdir}/log
mkdir -p %{buildroot}%{brokerdir}/run
mkdir -p %{buildroot}%{brokerdir}/tmp/cache
mkdir -p %{buildroot}%{brokerdir}/tmp/pids
mkdir -p %{buildroot}%{brokerdir}/tmp/sessions
mkdir -p %{buildroot}%{brokerdir}/tmp/sockets
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d

cp -r . %{buildroot}%{brokerdir}
mv %{buildroot}%{brokerdir}/init.d/* %{buildroot}%{_initddir}
ln -s %{brokerdir}/public %{buildroot}%{htmldir}/broker
ln -s %{brokerdir}/public %{buildroot}%{brokerdir}/httpd/root/broker
touch %{buildroot}%{brokerdir}/log/production.log
touch %{buildroot}%{brokerdir}/log/development.log
ln -sf /usr/lib64/httpd/modules %{buildroot}%{brokerdir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{brokerdir}/httpd/conf/magic
mv %{buildroot}%{brokerdir}/httpd/000000_stickshift_proxy.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

mkdir -p %{buildroot}%{_localstatedir}/log/stickshift
touch %{buildroot}%{_localstatedir}/log/stickshift/user_action.log

cp script/ss-* %{buildroot}%{_bindir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0640,apache,apache,0750)
%attr(0666,-,-) %{brokerdir}/log/production.log
%attr(0666,-,-) %{brokerdir}/log/development.log
%attr(0666,-,-) %{_localstatedir}/log/stickshift/user_action.log
%attr(0750,-,-) %{brokerdir}/script
%attr(0750,-,-) %{brokerdir}/tmp
%attr(0750,-,-) %{brokerdir}/tmp/cache
%attr(0750,-,-) %{brokerdir}/tmp/pids
%attr(0750,-,-) %{brokerdir}/tmp/sessions
%attr(0750,-,-) %{brokerdir}/tmp/sockets
%{brokerdir}
%{htmldir}/broker
%config(noreplace) %{brokerdir}/config/environments/production.rb
%config(noreplace) %{brokerdir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000000_stickshift_proxy.conf

%defattr(0640,root,root,0750)
%{_initddir}/stickshift-broker
%attr(0750,-,-) %{_initddir}/stickshift-broker
%attr(0700,-,-) %{_bindir}/ss-*

%doc %{brokerdir}/COPYRIGHT
%doc %{brokerdir}/LICENSE

%post
/bin/touch %{brokerdir}/log/production.log
/bin/touch %{brokerdir}/log/development.log
/bin/touch %{brokerdir}/httpd/logs/error_log
/bin/touch %{brokerdir}/httpd/logs/access_log
/bin/touch %{_localstatedir}/log/stickshift/user_action.log

#selinux updated
systemctl --system daemon-reload

semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
fcontext -a -t httpd_var_run_t '%{brokerdir}/httpd/run(/.*)?'
fcontext -a -t httpd_tmp_t '%{brokerdir}/tmp(/.*)?'
fcontext -a -t httpd_log_t '%{brokerdir}/httpd/logs(/.*)?'
fcontext -a -t httpd_log_t '%{brokerdir}/log(/.*)?'
fcontext -a -t httpd_log_t '%{_localstatedir}/log/stickshift/user_action.log'
_EOF

chcon -R -t httpd_log_t %{brokerdir}/httpd/logs %{brokerdir}/log
chcon -R -t httpd_tmp_t %{brokerdir}/httpd/run
chcon -R -t httpd_var_run_t %{brokerdir}/httpd/run
/sbin/fixfiles -R rubygem-passenger restore
/sbin/fixfiles -R mod_passenger restore
/sbin/restorecon -R -v /var/run
/sbin/restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-*
/sbin/restorecon -rv %{brokerdir}/tmp
/sbin/restorecon -v '%{_localstatedir}/log/stickshift/user_action.log'

%postun
/usr/sbin/semodule -e passenger -r stickshift-common
/sbin/fixfiles -R rubygem-passenger restore
/sbin/fixfiles -R mod_passenger restore
/sbin/restorecon -R -v /var/run

%changelog
* Wed May 30 2012 Krishna Raman <kraman@gmail.com> 0.6.7-1
- Fixing /etc/httpd/conf.d/stickshift link to be conpatible with typeless gears
  change Fixing context of action log file (kraman@gmail.com)
- Merge pull request #75 from abhgupta/bz817172 (mmcgrath+openshift@redhat.com)
- Fix for bug 817172 - adding gear profile on gear_groups rest call
  (abhgupta@redhat.com)

* Wed May 30 2012 Krishna Raman <kraman@gmail.com> 0.6.6-1
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Merge pull request #66 from abhgupta/agupta-dev (dmcphers@redhat.com)
- Fix for Bugz 825366, 825340. SELinux changes to allow access to
  user_action.log file. Logging authentication failures and user creation for
  OpenShift Origin (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #46 from rajatchopra/master (kraman@gmail.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #56 from pravisankar/master (admiller@redhat.com)
- disable mongo unit tests temporarily to avoid build issues
  (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fixed mongo data store unit tests (rpenta@redhat.com)
- changing user action log file path (abhgupta@redhat.com)
- changes for logging user actions to a separate log file (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- fixup gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- code for min_gear setting (rchopra@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- more timeout tweaking (dmcphers@redhat.com)
- try a bigger timeout (dmcphers@redhat.com)
- try a bigger timeout (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #40 from kraman/dev/kraman/features/livecd
  (admiller@redhat.com)
- Re-include all OpenShift components in rcov run. (rmillner@redhat.com)
- Adding livecd build scripts Adding a text only minimal version of livecd
  Added ability to access livecd dns from outside VM (kraman@gmail.com)
- allow syslog output for gear usage (dmcphers@redhat.com)
- proper usage of StickShift::Model and beginnings of usage tracking
  (dmcphers@redhat.com)
- Add rcov testing to the Stickshift broker, common and controller.
  (rmillner@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #28 from abhgupta/abhgupta-dev2 (dmcphers@redhat.com)
- adding test cases for gear_groups rest api and changing tag from cartridge to
  cartridges as it is a list (abhgupta@redhat.com)
- We already validate the gear size elswhere based on the user information.
  Remove the hard-coded list of node types.  As a side effect; we can't check
  invalid gear sizes in unit tests. (rmillner@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Small is the only gear size guaranteed to be accepted by the broker.
  (rmillner@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)
- update gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)

* Wed Apr 25 2012 Krishna Raman <kraman@gmail.com> 0.6.5-1
- Updating gem versions (admiller@redhat.com)
- fix gem version (dmcphers@redhat.com)
- Modifed SELinux policy to allow connection to DB. (mpatel@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (rpenta@redhat.com)
- Fixes + README file for REST api version unit tests (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Stickshift broker Unit tests to verify REST api version compatibility
  (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fixing stickshift-broker.spec to load rubygem-passenger.pp SELinux policy
  (kraman@gmail.com)
- Adding missing initializer to load Mongo datastore (kraman@gmail.com)
- Updating gem versions (admiller@redhat.com)

* Mon Apr 23 2012 Krishna Raman <kraman@gmail.com> 0.6.4-1
- Updated SELinux policies (kraman@gmail.com)
- Adding pasenger dependencies which provide required selinux policies.
  (kraman@gmail.com)
- Updating gem versions (admiller@redhat.com)
- cleaning up spec files (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- fix hanging comma (dmcphers@redhat.com)
- move crankcase mongo datastore (dmcphers@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.6.3-1
- new package built with tito
