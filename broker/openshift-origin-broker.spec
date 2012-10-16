%define htmldir %{_localstatedir}/www/html
%define brokerdir %{_localstatedir}/www/openshift/broker

Summary:   OpenShift Origin broker components
Name:      openshift-origin-broker
Version:   0.6.14
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   openshift-origin-broker-%{version}.tar.gz

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%define with_systemd 1
%else
%define with_systemd 0
%endif

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
Requires:  rubygem(openshift-origin-controller)
Requires:  rubygem(passenger)
Requires:  rubygem(rcov)
Requires:  rubygem-passenger-native
Requires:  rubygem-passenger-native-libs
%if %{with_systemd}
BuildRequires: systemd-units
Requires:  systemd-units
%endif
Provides:  openshift-broker
BuildArch: noarch
Obsoletes: stickshift-broker

%description
This contains the broker 'controlling' components of OpenShift Origin.
This includes the public APIs for the client tools.

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
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{brokerdir}
mkdir -p %{buildroot}%{brokerdir}/httpd/root
mkdir -p %{buildroot}%{brokerdir}/httpd/run
mkdir -p %{buildroot}%{brokerdir}/httpd/logs
mkdir -p %{buildroot}%{brokerdir}/httpd/conf
mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
mkdir -p %{buildroot}%{brokerdir}/log
mkdir -p %{buildroot}%{brokerdir}/run
mkdir -p %{buildroot}%{brokerdir}/tmp/cache
mkdir -p %{buildroot}%{brokerdir}/tmp/pids
mkdir -p %{buildroot}%{brokerdir}/tmp/sessions
mkdir -p %{buildroot}%{brokerdir}/tmp/sockets
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig

cp -r . %{buildroot}%{brokerdir}
%if %{with_systemd}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.service %{buildroot}%{_unitdir}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-broker
%else
mv %{buildroot}%{brokerdir}/init.d/* %{buildroot}%{_initddir}
%endif
ln -s %{brokerdir}/public %{buildroot}%{htmldir}/broker
ln -s %{brokerdir}/public %{buildroot}%{brokerdir}/httpd/root/broker
touch %{buildroot}%{brokerdir}/log/production.log
touch %{buildroot}%{brokerdir}/log/development.log
ln -sf /usr/lib64/httpd/modules %{buildroot}%{brokerdir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{brokerdir}/httpd/conf/magic
mv %{buildroot}%{brokerdir}/httpd/000000_openshift_origin_broker_proxy.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

mkdir -p %{buildroot}%{_localstatedir}/log/openshift
touch %{buildroot}%{_localstatedir}/log/openshift/user_action.log

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0640,apache,apache,0750)
%attr(0666,-,-) %{brokerdir}/log/production.log
%attr(0666,-,-) %{brokerdir}/log/development.log
%attr(0666,-,-) %{_localstatedir}/log/openshift/user_action.log
%attr(0750,-,-) %{brokerdir}/script
%attr(0750,-,-) %{brokerdir}/tmp
%attr(0750,-,-) %{brokerdir}/tmp/cache
%attr(0750,-,-) %{brokerdir}/tmp/pids
%attr(0750,-,-) %{brokerdir}/tmp/sessions
%attr(0750,-,-) %{brokerdir}/tmp/sockets
%dir %attr(0750,-,-) %{brokerdir}/httpd/conf.d
%{brokerdir}
%{htmldir}/broker
%config(noreplace) %{brokerdir}/config/environments/production.rb
%config(noreplace) %{brokerdir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000000_openshift_origin_broker_proxy.conf

%defattr(0640,root,root,0750)
%if %{with_systemd}
%{_unitdir}/openshift-broker.service
%attr(0644,-,-) %{_unitdir}/openshift-broker.service
%{_sysconfdir}/sysconfig/openshift-broker
%attr(0644,-,-) %{_sysconfdir}/sysconfig/openshift-broker
%else
%{_initddir}/openshift-broker
%attr(0750,-,-) %{_initddir}/openshift-broker
%endif


%doc %{brokerdir}/COPYRIGHT
%doc %{brokerdir}/LICENSE

%post
/bin/touch %{brokerdir}/log/production.log
/bin/touch %{brokerdir}/log/development.log
/bin/touch %{brokerdir}/httpd/logs/error_log
/bin/touch %{brokerdir}/httpd/logs/access_log
/bin/touch %{_localstatedir}/log/openshift/user_action.log

%if %{with_systemd}
systemctl --system daemon-reload
# if under sysv, hopefully we don't need to reload anything
%endif

#selinux updated
semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
fcontext -a -t httpd_var_run_t '%{brokerdir}/httpd/run(/.*)?'
fcontext -a -t httpd_tmp_t '%{brokerdir}/tmp(/.*)?'
fcontext -a -t httpd_log_t '%{brokerdir}/httpd/logs(/.*)?'
fcontext -a -t httpd_log_t '%{brokerdir}/log(/.*)?'
fcontext -a -t httpd_log_t '%{_localstatedir}/log/openshift/user_action.log'
_EOF

chcon -R -t httpd_log_t %{brokerdir}/httpd/logs %{brokerdir}/log
chcon -R -t httpd_tmp_t %{brokerdir}/httpd/run
chcon -R -t httpd_var_run_t %{brokerdir}/httpd/run
/sbin/fixfiles -R rubygem-passenger restore
/sbin/fixfiles -R mod_passenger restore
/sbin/restorecon -R -v /var/run
/sbin/restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-*
/sbin/restorecon -rv %{brokerdir}/tmp
/sbin/restorecon -v '%{_localstatedir}/log/openshift/user_action.log'

%postun
/usr/sbin/semodule -e passenger -r openshift-origin-common
/sbin/fixfiles -R rubygem-passenger restore
/sbin/fixfiles -R mod_passenger restore
/sbin/restorecon -R -v /var/run

%changelog
* Thu Oct 11 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.14-1
- Merge pull request #635 from Miciah/etc-plugin-conf12
  (openshift+bot@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)

* Wed Oct 10 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.13-1
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Tue Oct 09 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.12-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.6.11-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 2: variables, modules, classes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

* Thu Sep 13 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.10-1
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' into tdawson/fixes (tdawson@redhat.com)
- remove rubygem(multimap) requirement (tdawson@redhat.com)
- Updating gem versions (tdawson@redhat.com)
- Updating gem versions (admiller@redhat.com)
- broker and node Gemfile.lock update (admiller@redhat.com)
- update gem version (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Gemfile.lock updates (admiller@redhat.com)
- Add <broker>/rest/environment REST call to expose env variables like
  domain_suffix, etc. (rpenta@redhat.com)
- Expose capabilities in the Rest user model (rpenta@redhat.com)
- Merge pull request #433 from danmcp/master (openshift+bot@redhat.com)
- optimize nolinks (dmcphers@redhat.com)

* Thu Aug 23 2012 Adam Miller <admiller@redhat.com> 0.6.9-1
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- need systemd-units in BuildRequires for _unitdir rpm macro
  (admiller@redhat.com)
- cleanup based on test case additions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)

* Mon Aug 20 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.8-1
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #391 from sosiouxme/master (openshift+bot@redhat.com)
- Updating gem versions (admiller@redhat.com)
- shield systemctl on non-systemd system (lmeyer@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #380 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- Updating gem versions (admiller@redhat.com)
- adding rest api to fetch and update quota on gear group (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Bug 846555 (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- broker spec fixes for systemd (jason.detiberus@redhat.com)
- Merge pull request #318 from pravisankar/dev/ravi/story/US1896
  (kraman@gmail.com)
- Updating gem versions (admiller@redhat.com)
- Added 'nolinks' parameter to suppress link generation in the REST API replies
  to make the output terse and improve general processing speed
  (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Don't allow more than one domain for the user (rpenta@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Mongo deleted_gears fix (rpenta@redhat.com)
- Fixes for Bug 806824 (kraman@gmail.com)
- Add missing systemu dependency. (mpatel@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- broker sanity test reorg (dmcphers@redhat.com)
- Merge pull request #242 from ramr/master (smitram@gmail.com)
- fixing build (abhgupta@redhat.com)
- fixed test failure (lnader@redhat.com)
- Fixes for bugz 840030 - Apache blocks access to /icons. Remove these as
  mod_autoindex has now been turned OFF (see bugz 785050 for more details).
  (ramr@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #224 from kraman/dev/kraman/bugs/838611
  (rpenta@redhat.com)
- Bump API version to 1.1. New version returns framework cartridge and related
  properties when listing cartridges for an app
  (.../applications/<id>/cartridges) Builds upon cartridge metadata which was
  added in 47d1b813a1a74228c9c95734043487d681f799d4. (kraman@gmail.com)
- Fix for bug 839151 (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #214 from kraman/dev/kraman/bugs/testfix
  (dmcphers@redhat.com)
- Adding test user to mongo to allow tests to run (kraman@gmail.com)
- Merge pull request #209 from lnader/master (rmillner@redhat.com)
- Merge pull request #198 from brenton/master (kraman@gmail.com)
- Updating gem versions (admiller@redhat.com)
- Handling registration for the rest api tests cases when run outside of
  openshift.com (bleanhar@redhat.com)
- Adding missing mongodb collection for the rest api tests
  (bleanhar@redhat.com)
- Copying the development mongo datastore config to test (bleanhar@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Bug 837926 - changed application_template to application_templates
  (lnader@redhat.com)
- blocking requires/conflicts/suggests/depends from RestCartridge model until
  further agreement on cartridge metadata is made (rchopra@redhat.com)
- Updating gem versions (admiller@redhat.com)
- update tests for RestUser (lnader@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- changing categories to tags for site functional tests (rchopra@redhat.com)
- Updating gem versions (admiller@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- More fixes to bug# 808425 (rpenta@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)
- Updating gem versions (admiller@redhat.com)
- Removing application unit test, rationale: More than 90%% of the code is
  stubbed and more time is spent in fixing this useless test
  (rpenta@redhat.com)
- Revert "Updating gem versions" (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fixes for bug 827337, 830309, 811066, and 832374 Exposing initial public ip
  in the rest response for application creation (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fix for bug 812046 (abhgupta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Strip out the unnecessary gems from rcov reports and focus it on just the
  OpenShift code. (rmillner@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Updated gem info for rails 3.0.13 (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- add beginnings of broker integration tests (dmcphers@redhat.com)
- Merge pull request #102 from pravisankar/master (dmcphers@redhat.com)
- Broker: Fixed Application unit tests (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fixed template tests  - Needed to loop through results  - Needed to add links
  attribute to class (fotioslindiakos@gmail.com)
- Updating gem versions (admiller@redhat.com)
- Merge pull request #86 from pravisankar/master
  (mmcgrath+openshift@redhat.com)
- Enable mongo datastore unit tests (rpenta@redhat.com)
- Fix for bug 823675 - Exposing gear count in application and consumed gears in
  user object via rest calls (abhgupta@redhat.com)

* Wed May 30 2012 Krishna Raman <kraman@gmail.com> 0.6.7-1
- Fixing /etc/httpd/conf.d/openshift link to be conpatible with typeless gears
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
- proper usage of OpenShift::Model and beginnings of usage tracking
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
- Merge branch 'master' of github.com:openshift/origin-server (rpenta@redhat.com)
- Fixes + README file for REST api version unit tests (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Stickshift broker Unit tests to verify REST api version compatibility
  (rpenta@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Fixing openshift-origin-broker.spec to load rubygem-passenger.pp SELinux policy
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
- move origin-server mongo datastore (dmcphers@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.6.3-1
- new package built with tito
