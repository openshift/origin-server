%global htmldir %{_var}/www/html
%global brokerdir %{_var}/www/openshift/broker
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%global gemdir /usr/share/rubygems/gems
%else
%global with_systemd 0
%global gemdir /opt/rh/ruby193/root/usr/share/gems/gems
%endif

Summary:       OpenShift Origin broker components
Name:          openshift-origin-broker
Version:       1.15.1.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      httpd
# TODO: We need to audit these requirements.  Some of these are likely not hard
# requirements.
Requires:      mod_ssl
Requires:      %{?scl:%scl_prefix}mod_passenger
%if 0%{?scl:1}
Requires:      %{?scl:%scl_prefix}ruby-wrapper
Requires:      openshift-origin-util-scl
%else
Requires:      openshift-origin-util
%endif
Requires:      policycoreutils-python
Requires:      rubygem-openshift-origin-controller
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}rubygem-bson_ext
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-json_pure
# This gem is required by oo-admin-chk, oo-admin-fix-sshkeys, and
# oo-stats, for OpenShift::DataStore API support
Requires:      %{?scl:%scl_prefix}rubygem-mongo
Requires:      %{?scl:%scl_prefix}rubygem-mongoid
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-parseconfig
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-regin
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
Requires:      %{?scl:%scl_prefix}rubygem-systemu
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple

Requires:      %{?scl:%scl_prefix}rubygem-actionmailer
Requires:      %{?scl:%scl_prefix}rubygem-actionpack
Requires:      %{?scl:%scl_prefix}rubygem-activemodel
Requires:      %{?scl:%scl_prefix}rubygem-activerecord
Requires:      %{?scl:%scl_prefix}rubygem-activeresource
Requires:      %{?scl:%scl_prefix}rubygem-activesupport
Requires:      %{?scl:%scl_prefix}rubygem-arel
Requires:      %{?scl:%scl_prefix}rubygem-bigdecimal
Requires:      %{?scl:%scl_prefix}rubygem-bson
Requires:      %{?scl:%scl_prefix}rubygem-builder
Requires:      %{?scl:%scl_prefix}rubygem-bundler
Requires:      %{?scl:%scl_prefix}rubygem-diff-lcs
Requires:      %{?scl:%scl_prefix}rubygem-dnsruby
Requires:      %{?scl:%scl_prefix}rubygem-erubis
Requires:      %{?scl:%scl_prefix}rubygem-hike
Requires:      %{?scl:%scl_prefix}rubygem-i18n
Requires:      %{?scl:%scl_prefix}rubygem-journey
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-mail
Requires:      %{?scl:%scl_prefix}rubygem-metaclass
Requires:      %{?scl:%scl_prefix}rubygem-mime-types
Requires:      %{?scl:%scl_prefix}rubygem-moped
Requires:      %{?scl:%scl_prefix}rubygem-multi_json
Requires:      %{?scl:%scl_prefix}rubygem-origin
Requires:      %{?scl:%scl_prefix}rubygem-polyglot
Requires:      %{?scl:%scl_prefix}rubygem-rack
Requires:      %{?scl:%scl_prefix}rubygem-rack-cache
Requires:      %{?scl:%scl_prefix}rubygem-rack-ssl
Requires:      %{?scl:%scl_prefix}rubygem-rack-test
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-railties
Requires:      %{?scl:%scl_prefix}rubygem-rdoc
Requires:      %{?scl:%scl_prefix}rubygem-regin
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-state_machine
Requires:      %{?scl:%scl_prefix}rubygem-stomp
Requires:      %{?scl:%scl_prefix}rubygem-systemu
Requires:      %{?scl:%scl_prefix}rubygem-term-ansicolor
Requires:      %{?scl:%scl_prefix}rubygem-thor
Requires:      %{?scl:%scl_prefix}rubygem-tilt
Requires:      %{?scl:%scl_prefix}rubygem-treetop
Requires:      %{?scl:%scl_prefix}rubygem-tzinfo
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple

%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch
Provides:      openshift-broker

%description
This contains the broker 'controlling' components of OpenShift Origin.
This includes the public APIs for the client tools.

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
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{brokerdir}
mkdir -p %{buildroot}%{brokerdir}/httpd/root
mkdir -p %{buildroot}%{brokerdir}/httpd/run
mkdir -p %{buildroot}%{brokerdir}/httpd/conf
mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
mkdir -p %{buildroot}%{brokerdir}/run
mkdir -p %{buildroot}%{brokerdir}/tmp/cache
mkdir -p %{buildroot}%{brokerdir}/tmp/pids
mkdir -p %{buildroot}%{brokerdir}/tmp/sessions
mkdir -p %{buildroot}%{brokerdir}/tmp/sockets
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{_sysconfdir}/openshift/plugins.d

cp -r . %{buildroot}%{brokerdir}
%if %{with_systemd}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.service %{buildroot}%{_unitdir}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-broker
%else
mv %{buildroot}%{brokerdir}/init.d/* %{buildroot}%{_initddir}
%endif
ln -s %{brokerdir}/public %{buildroot}%{htmldir}/broker
ln -s %{brokerdir}/public %{buildroot}%{brokerdir}/httpd/root/broker
ln -sf %{_libdir}/httpd/modules %{buildroot}%{brokerdir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{brokerdir}/httpd/conf/magic
mv %{buildroot}%{brokerdir}/httpd/000002_openshift_origin_broker_proxy.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/
mv %{buildroot}%{brokerdir}/httpd/000002_openshift_origin_broker_servername.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

mkdir -p %{buildroot}%{_var}/log/openshift/broker/httpd
touch %{buildroot}%{_var}/log/openshift/broker/user_action.log
touch %{buildroot}%{_var}/log/openshift/broker/production.log
touch %{buildroot}%{_var}/log/openshift/broker/development.log
touch %{buildroot}%{_var}/log/openshift/broker/usage.log

cp conf/broker.conf %{buildroot}%{_sysconfdir}/openshift/broker.conf
cp conf/broker.conf %{buildroot}%{_sysconfdir}/openshift/broker-dev.conf
cp conf/quickstarts.json %{buildroot}%{_sysconfdir}/openshift/quickstarts.json
cp conf/plugins.d/README %{buildroot}%{_sysconfdir}/openshift/plugins.d/README

# BZ986300
rm -f %{buildroot}%{brokerdir}/COPYRIGHT
rm -f %{buildroot}%{brokerdir}/.gitignore
rm -f %{buildroot}%{brokerdir}/LICENSE
rm -f %{buildroot}%{brokerdir}/openshift-origin-broker.spec
rm -f %{buildroot}%{brokerdir}/tmp/cache/.gitkeep
rm -rf %{buildroot}%{brokerdir}/conf
rm -rf %{buildroot}%{brokerdir}/doc
rm -rf %{buildroot}%{brokerdir}/init.d
rm -rf %{buildroot}%{brokerdir}/lib
rm -rf %{buildroot}%{brokerdir}/test

%if 0%{?fedora} >= 18
mv %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-2.4 %{buildroot}%{brokerdir}/httpd/httpd.conf
%else
mv %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-2.3 %{buildroot}%{brokerdir}/httpd/httpd.conf
%endif
rm %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-*

%if 0%{?scl:1}
rm %{buildroot}%{brokerdir}/httpd/broker.conf
mv %{buildroot}%{brokerdir}/httpd/broker-scl-ruby193.conf %{buildroot}%{brokerdir}/httpd/broker.conf
%else
rm %{buildroot}%{brokerdir}/httpd/broker-scl-ruby193.conf
%endif

# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' %{buildroot}%{brokerdir}/Gemfile

%files
%doc LICENSE COPYRIGHT
%defattr(0640,apache,apache,0750)
%attr(0750,-,-) %{_var}/log/openshift/broker
%attr(0750,-,-) %{_var}/log/openshift/broker/httpd
%attr(0750,-,-) %{brokerdir}/script
%attr(0750,-,-) %{brokerdir}/tmp
%attr(0750,-,-) %{brokerdir}/tmp/cache
%attr(0750,-,-) %{brokerdir}/tmp/pids
%attr(0750,-,-) %{brokerdir}/tmp/sessions
%attr(0750,-,-) %{brokerdir}/tmp/sockets
%dir %attr(0750,-,-) %{brokerdir}/httpd/conf.d
%{brokerdir}
%{htmldir}/broker
%config %{brokerdir}/config/environments/production.rb
%config %{brokerdir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000002_openshift_origin_broker_proxy.conf
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000002_openshift_origin_broker_servername.conf
%config(noreplace) %{_sysconfdir}/openshift/broker.conf
%config(noreplace) %{_sysconfdir}/openshift/broker-dev.conf
%doc %{_sysconfdir}/openshift/plugins.d/README
%dir %{_sysconfdir}/openshift/plugins.d
%config(noreplace) %{_sysconfdir}/openshift/quickstarts.json
%{_sysconfdir}/openshift/broker-dev.conf

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


%post
%if %{with_systemd}
systemctl --system daemon-reload
# if under sysv, hopefully we don't need to reload anything
%endif

# We are forced to create these log files if they don't exist because we have
# command line tools that will load the Rails environment and create the logs
# as root.  We need the files labeled %ghost because we don't want these log
# files overwritten on RPM upgrade.
for l in %{_var}/log/openshift/broker/{development,production,user_action}.log; do
  if [ ! -f $l ]; then
    touch $l
  fi
  chown apache:apache $l
  chmod 640 $l
done

#selinux updated
semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
fcontext -a -t httpd_var_run_t '%{brokerdir}/httpd/run(/.*)?'
fcontext -a -t httpd_tmp_t '%{brokerdir}/tmp(/.*)?'
fcontext -a -t httpd_log_t '%{_var}/log/openshift/broker(/.*)?'
_EOF

chcon -R -t httpd_log_t %{_var}/log/openshift/broker
chcon -R -t httpd_tmp_t %{brokerdir}/httpd/run
chcon -R -t httpd_var_run_t %{brokerdir}/httpd/run
/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
#/sbin/restorecon -rv %{_datarootdir}/rubygems/gems/passenger-*
/sbin/restorecon -rv %{brokerdir}/tmp
/sbin/restorecon -v '%{_var}/log/openshift/broker/user_action.log'

%postun
/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run

%changelog
* Fri Dec 06 2013 Krishna Raman <kraman@gmail.com> 1.15.1.1-1
- Bumping versions for OpenShift Origin Release 3 (kraman@gmail.com)
- Bug 1032436 (lnader@redhat.com)
- Temporarily disable code that breaks test (andy.goldstein@gmail.com)
- Flatten 'gears' in application mongo record i.e. 'gears' field will be
  sibling of 'group_instances'. (rpenta@redhat.com)
- Merge pull request #4213 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4237 from lnader/card_169
  (dmcphers+openshiftbot@redhat.com)
- Added ; to list of chars not allowed (lnader@redhat.com)
- Added checking for git ref according to git-check-ref-format rules
  (lnader@redhat.com)
- Changed deprecated to obsolete (lnader@redhat.com)
- node: we do not want %%ghost-ed log files (mmahut@redhat.com)
- card_169 (lnader@redhat.com)
- Bug 1025691 - can't add member to a domain when authenticate with token
  (jforrest@redhat.com)
- Merge pull request #4106 from pravisankar/dev/ravi/card639
  (dmcphers+openshiftbot@redhat.com)
- updated REST API docs to include binary deployment (lnader@redhat.com)
- Rest API Deployment support for passing the artifact url parameter with
  associated tests in the broker and node.  Enabling the artifact url param in
  the rest models. (jajohnso@redhat.com)
- Allow adding large gear size to users irrespective of their plan If the user
  is enrolled into a plan, do not store capabilites in cloud user mongo record
  instead get the capabilities based on their plan. Any explicitly set
  capabilities will be stored in user record. Fix test cases
  (rpenta@redhat.com)
- Remove max domains (jliggitt@redhat.com)
- Fixing broker extended tests (abhgupta@redhat.com)
- Fix for bug 1024669 (abhgupta@redhat.com)
- Merge pull request #4049 from detiber/fixSystemd
  (dmcphers+openshiftbot@redhat.com)
- Update systemd service definitions to rebuild Gemfile.lock
  (jdetiber@redhat.com)
- Merge pull request #3958 from detiber/fixTests
  (dmcphers+openshiftbot@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- <tests> Update test tags and enable REMOTE_USER auth for tests
  (jdetiber@redhat.com)
- Merge pull request #4002 from smarterclayton/app_metadata_field
  (dmcphers+openshiftbot@redhat.com)
- Add application metadata and validators (ccoleman@redhat.com)
- Merge pull request #3972 from liggitt/bug_1020009_max_domains_capability
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3989 from kraman/bugfix3
  (dmcphers+openshiftbot@redhat.com)
- Mark /etc/openshift/broker-dev.conf as config-noreplace. (kraman@gmail.com)
- Fix reloading for broker unit test failure (kraman@gmail.com)
- Add config value (jliggitt@redhat.com)
- kerberos work for broker and console (jliggitt@redhat.com)
- Merge pull request #3770 from mfojtik/bugzilla/1015187
  (dmcphers+openshiftbot@redhat.com)
- updated the REST API docs with addition of gear size (lnader@redhat.com)
- Added HTTP_PROXY and CONN_TIMEOUT to broker.conf (mfojtik@redhat.com)
- Bug 1015187: Replace curl with httpclient when downloading cartridges
  (mfojtik@redhat.com)
- Merge pull request #3893 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- <capacity suggestions> bug 1004686 (lmeyer@redhat.com)
- Fixing origin extended tests (abhgupta@redhat.com)
- Merge pull request #3878 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3880 from brenton/BZ1017676
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3874 from brenton/remove_test_deps3
  (dmcphers+openshiftbot@redhat.com)
- Adding test case (abhgupta@redhat.com)
- Bug 1017676 - Adding default configurations for team collaboration settings
  (bleanhar@redhat.com)
- Removing test dependencies from Broker/Console build and runtime.
  (bleanhar@redhat.com)
- Test case fixes for Origin: (kraman@gmail.com)
- Fix deployment test (dmcphers@redhat.com)
- Updated REST API docs (lnader@redhat.com)
- Required deployment_id for activate (lnader@redhat.com)
- updated REST API docs (lnader@redhat.com)
- ensure you return the last activated deployment (dmcphers@redhat.com)
- Fixing extended tests (dmcphers@redhat.com)
- Bug 1017005 - Fixing the Broker's AUTH_* settings that have been renamed
  (bleanhar@redhat.com)
- Fix typos and NPE discovered in newrelic logs (jliggitt@redhat.com)
- Fixing broker extended (dmcphers@redhat.com)
- Adding deploy migration for broker auth (dmcphers@redhat.com)
- store and return times as times (dmcphers@redhat.com)
- Fixing tests and resolving remaining communication between broker and node
  for deployments (dmcphers@redhat.com)
- Stop using a deployment as a creation mechanism for a deployment
  (dmcphers@redhat.com)
- Allow for floats with time storage (dmcphers@redhat.com)
- activation validations (dmcphers@redhat.com)
- Adding activations to deployments (dmcphers@redhat.com)
- rollback -> activate (dmcphers@redhat.com)
- add update deployments scope (dmcphers@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- Fix bson hash error (dmcphers@redhat.com)
- Rollback to last deployment and tests (lnader@redhat.com)
- Fixing tests and squashing bugs (dmcphers@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- collapse the git refs into 1 (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Added tests and links for application config update (lnader@redhat.com)
- Adding application config WIP (dmcphers@redhat.com)
- Broker Build and Deployment (lnader@redhat.com)
- Merge pull request #3757 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3759 from kraman/test_case_fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 980306 (lnader@redhat.com)
- Fix for broker functional extended tests which run against prod env.
  (kraman@gmail.com)
- Have CloudUser create a new CapabilityProxy every time to fix
  application_test.rb#test_scaling_and_storage_events_on_application on F19.
  (kraman@gmail.com)
- Updating tests to register mongo-auth based user in the correct database
  based on Rails environment. (kraman@gmail.com)
- moved system tests to origin (lnader@redhat.com)
- Fix integration extended tests (rpenta@redhat.com)
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- <sub_user_test.rb> Added logic to make tests work with remote-user auth
  (jolamb@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)
- Add rake test for extended integration tests (rpenta@redhat.com)
- Use MONGO_TEST_DB=openshift_broker_test for broker tests (rpenta@redhat.com)
- optimize find all district scenarios (dmcphers@redhat.com)
- First draft of changes to create subclasses for pending ops
  (abhgupta@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- Adding oo-mco and updating oo-diagnostics to support the SCL'd mcollective
  (bleanhar@redhat.com)

* Wed Dec 04 2013 Krishna Raman <kraman@gmail.com> 1.15.1.1-1
- Bug 1032436 (lnader@redhat.com)
- Temporarily disable code that breaks test (andy.goldstein@gmail.com)
- Flatten 'gears' in application mongo record i.e. 'gears' field will be
  sibling of 'group_instances'. (rpenta@redhat.com)
- Merge pull request #4213 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4237 from lnader/card_169
  (dmcphers+openshiftbot@redhat.com)
- Added ; to list of chars not allowed (lnader@redhat.com)
- Added checking for git ref according to git-check-ref-format rules
  (lnader@redhat.com)
- Changed deprecated to obsolete (lnader@redhat.com)
- node: we do not want %%ghost-ed log files (mmahut@redhat.com)
- card_169 (lnader@redhat.com)
- Bug 1025691 - can't add member to a domain when authenticate with token
  (jforrest@redhat.com)
- Merge pull request #4106 from pravisankar/dev/ravi/card639
  (dmcphers+openshiftbot@redhat.com)
- updated REST API docs to include binary deployment (lnader@redhat.com)
- Rest API Deployment support for passing the artifact url parameter with
  associated tests in the broker and node.  Enabling the artifact url param in
  the rest models. (jajohnso@redhat.com)
- Allow adding large gear size to users irrespective of their plan If the user
  is enrolled into a plan, do not store capabilites in cloud user mongo record
  instead get the capabilities based on their plan. Any explicitly set
  capabilities will be stored in user record. Fix test cases
  (rpenta@redhat.com)
- Remove max domains (jliggitt@redhat.com)
- Fixing broker extended tests (abhgupta@redhat.com)
- Fix for bug 1024669 (abhgupta@redhat.com)
- Merge pull request #4049 from detiber/fixSystemd
  (dmcphers+openshiftbot@redhat.com)
- Update systemd service definitions to rebuild Gemfile.lock
  (jdetiber@redhat.com)
- Merge pull request #3958 from detiber/fixTests
  (dmcphers+openshiftbot@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- <tests> Update test tags and enable REMOTE_USER auth for tests
  (jdetiber@redhat.com)
- Merge pull request #4002 from smarterclayton/app_metadata_field
  (dmcphers+openshiftbot@redhat.com)
- Add application metadata and validators (ccoleman@redhat.com)
- Merge pull request #3972 from liggitt/bug_1020009_max_domains_capability
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3989 from kraman/bugfix3
  (dmcphers+openshiftbot@redhat.com)
- Mark /etc/openshift/broker-dev.conf as config-noreplace. (kraman@gmail.com)
- Fix reloading for broker unit test failure (kraman@gmail.com)
- Add config value (jliggitt@redhat.com)
- kerberos work for broker and console (jliggitt@redhat.com)
- Merge pull request #3770 from mfojtik/bugzilla/1015187
  (dmcphers+openshiftbot@redhat.com)
- updated the REST API docs with addition of gear size (lnader@redhat.com)
- Added HTTP_PROXY and CONN_TIMEOUT to broker.conf (mfojtik@redhat.com)
- Bug 1015187: Replace curl with httpclient when downloading cartridges
  (mfojtik@redhat.com)
- Merge pull request #3893 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- <capacity suggestions> bug 1004686 (lmeyer@redhat.com)
- Fixing origin extended tests (abhgupta@redhat.com)
- Merge pull request #3878 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3880 from brenton/BZ1017676
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3874 from brenton/remove_test_deps3
  (dmcphers+openshiftbot@redhat.com)
- Adding test case (abhgupta@redhat.com)
- Bug 1017676 - Adding default configurations for team collaboration settings
  (bleanhar@redhat.com)
- Removing test dependencies from Broker/Console build and runtime.
  (bleanhar@redhat.com)
- Test case fixes for Origin: (kraman@gmail.com)
- Fix deployment test (dmcphers@redhat.com)
- Updated REST API docs (lnader@redhat.com)
- Required deployment_id for activate (lnader@redhat.com)
- updated REST API docs (lnader@redhat.com)
- ensure you return the last activated deployment (dmcphers@redhat.com)
- Fixing extended tests (dmcphers@redhat.com)
- Bug 1017005 - Fixing the Broker's AUTH_* settings that have been renamed
  (bleanhar@redhat.com)
- Fix typos and NPE discovered in newrelic logs (jliggitt@redhat.com)
- Fixing broker extended (dmcphers@redhat.com)
- Adding deploy migration for broker auth (dmcphers@redhat.com)
- store and return times as times (dmcphers@redhat.com)
- Fixing tests and resolving remaining communication between broker and node
  for deployments (dmcphers@redhat.com)
- Stop using a deployment as a creation mechanism for a deployment
  (dmcphers@redhat.com)
- Allow for floats with time storage (dmcphers@redhat.com)
- activation validations (dmcphers@redhat.com)
- Adding activations to deployments (dmcphers@redhat.com)
- rollback -> activate (dmcphers@redhat.com)
- add update deployments scope (dmcphers@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- Fix bson hash error (dmcphers@redhat.com)
- Rollback to last deployment and tests (lnader@redhat.com)
- Fixing tests and squashing bugs (dmcphers@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- collapse the git refs into 1 (dmcphers@redhat.com)
- Deploy WIP (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Added tests and links for application config update (lnader@redhat.com)
- Adding application config WIP (dmcphers@redhat.com)
- Broker Build and Deployment (lnader@redhat.com)
- Merge pull request #3757 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3759 from kraman/test_case_fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 980306 (lnader@redhat.com)
- Fix for broker functional extended tests which run against prod env.
  (kraman@gmail.com)
- Have CloudUser create a new CapabilityProxy every time to fix
  application_test.rb#test_scaling_and_storage_events_on_application on F19.
  (kraman@gmail.com)
- Updating tests to register mongo-auth based user in the correct database
  based on Rails environment. (kraman@gmail.com)
- moved system tests to origin (lnader@redhat.com)
- Fix integration extended tests (rpenta@redhat.com)
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- <sub_user_test.rb> Added logic to make tests work with remote-user auth
  (jolamb@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)
- Add rake test for extended integration tests (rpenta@redhat.com)
- Use MONGO_TEST_DB=openshift_broker_test for broker tests (rpenta@redhat.com)
- optimize find all district scenarios (dmcphers@redhat.com)
- First draft of changes to create subclasses for pending ops
  (abhgupta@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- Adding oo-mco and updating oo-diagnostics to support the SCL'd mcollective
  (bleanhar@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Fixing test case to allow multiple domains before checking for duplicate
  namespace (kraman@gmail.com)
- Merge pull request #3589 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix enable_ha with respect to max gear limits of web cart + config fixes
  (rchopra@redhat.com)
- <broker> compile assets in all envs (lmeyer@redhat.com)
- <admin suggestions> allow 1-node districts (lmeyer@redhat.com)
- <admin suggestions> fix bug 1004297 (lmeyer@redhat.com)
- <admin suggestions> fix bug 1004157 (lmeyer@redhat.com)
- <admin console> capacity planning (jforrest@redhat.com)
- <admin suggestions> library to suggest admin changes (lmeyer@redhat.com)
- <admin stats> refactor and mods for admin console (lmeyer@redhat.com)
- Remove environment variables support from REST 1.0 api version
  (rpenta@redhat.com)
- enable ha feature (rchopra@redhat.com)
- Fix Origin quickstarts. (steven.merrill@gmail.com)
- Bug 1002685 - Downcase domain names when fetching applications by domain
  (ccoleman@redhat.com)
- cleanup (dmcphers@redhat.com)
- Updated broker/docs for the phpmyadmin-4 (mfojtik@redhat.com)
- Updated docs after bug fixes (lnader@redhat.com)
- Bug 999826 and 999892 (lnader@redhat.com)
- Bug 999891 (lnader@redhat.com)
- Set mongoid logging to warn (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Handle .resultset.json (dmcphers@redhat.com)
- Fix for bug 997008 (abhgupta@redhat.com)
- origin_broker_77 (lnader@redhat.com)
- Merge pull request #3435 from
  smarterclayton/bug_997848_capabilities_not_shown_via_api
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3378 from Miciah/delete-references-to-obsolete-
  MONGO_REPLICA_SETS (dmcphers+openshiftbot@redhat.com)
- Bug 997848 - Inherited capabilities not in REST API (ccoleman@redhat.com)
- Bug 986300 - Pulling in a few cleanup commits from Fedora
  (bleanhar@redhat.com)
- Merge pull request #3413 from sosiouxme/admin-stats-fixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3410 from pravisankar/dev/ravi/card86
  (dmcphers+openshiftbot@redhat.com)
- <Admin::Stats> use only strings for hash keys (lmeyer@redhat.com)
- <Admin::Stats> exclude inactive nodes from eff avail gears
  (lmeyer@redhat.com)
- Added User environment variables support in broker (rpenta@redhat.com)
- Fix for bug 995034 (abhgupta@redhat.com)
- Merge pull request #3382 from smarterclayton/builder_scope_incorrect
  (dmcphers+openshiftbot@redhat.com)
- additional version changes (dmcphers@redhat.com)
- Merge pull request #3369 from lnader/improve_test_coverage
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3387 from
  smarterclayton/bug_997831_domain_scope_not_in_config
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3370 from
  smarterclayton/bug_997246_prohibit_blank_domains
  (dmcphers+openshiftbot@redhat.com)
- Bug 997831 - Domain scope not in Rails config (ccoleman@redhat.com)
- Fix builder scope by introducing a domain builder scope (ccoleman@redhat.com)
- Merge pull request #3376 from brenton/BZ986300_BZ981148
  (dmcphers+openshiftbot@redhat.com)
- Broker AUTH_KEY config variables don't match style (ccoleman@redhat.com)
- Merge pull request #3358 from sosiouxme/oo-stats-mods
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3368 from smarterclayton/find_by_user_broken_on_app
  (dmcphers+openshiftbot@redhat.com)
- Remove references to deprecated MONGO_REPLICA_SETS (miciah.masters@gmail.com)
- Bug 986300 - Remove the unused Broker configuration directory
  (bleanhar@redhat.com)
- <Admin::Stats tests> work around test problems (lmeyer@redhat.com)
- <oo-stats> ability to read results from file; more (lmeyer@redhat.com)
- <Admin::Stats> refactor classes and tests (lmeyer@redhat.com)
- Bug 997246 - Prohibit blank domains (ccoleman@redhat.com)
- improve test coverage on rest models (lnader@redhat.com)
- Unable to scale up or snapshot an app (ccoleman@redhat.com)
- <broker> Fix problem with plugin loading from source (lmeyer@redhat.com)
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- <broker> improve Gemfile loading + bug 993250 (lmeyer@redhat.com)
- Default to test mode membership off (ccoleman@redhat.com)
- Default to membership off in development mode (ccoleman@redhat.com)
- Review comments (ccoleman@redhat.com)
- Review - add comment to test (ccoleman@redhat.com)
- Bug 995371 - Direct parameters to members were ignored (ccoleman@redhat.com)
- Ensure only users with ssh access are added with keys (ccoleman@redhat.com)
- * Implement a membership model for OpenShift that allows an efficient query
  of user access based on each resource. * Implement scope limitations that
  correspond to specific permissions * Expose membership info via the REST API
  (disableable via config) * Allow multiple domains per user, controlled via a
  configuration flag * Support additional information per domain
  (application_count and gear_counts) to improve usability * Let domains
  support the allowed_gear_sizes option, which limits the gear sizes available
  to apps in that domain * Simplify domain update interactions - redundant
  validation removed, and behavior of responses differs slightly. * Implement
  migration script to enable data (ccoleman@redhat.com)
- Bug 992464 - Authorization token needs to raise when checking eventual
  consistency (ccoleman@redhat.com)
- Merge pull request #3272 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- <admin/stats> functional test to cover db scan method (lmeyer@redhat.com)
- <admin/stats> add unit tests, fix a bug (lmeyer@redhat.com)
- added more tests to improve coverage (lnader@redhat.com)
- Merge pull request #3227 from kraman/docs (dmcphers+openshiftbot@redhat.com)
- Adding missing activemq config templates Fixing console spec to require gems
  Additional fixes to comprehensive deployment guide (kraman@gmail.com)
- Fix for bug 989650 (abhgupta@redhat.com)
- Merge pull request #3229 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3233 from jwforres/admin_console_testcase_coverage
  (dmcphers+openshiftbot@redhat.com)
- fix in scope for scaling issues (rchopra@redhat.com)
- Admin console test framework and initial functional tests
  (jforrest@redhat.com)
- Bug 956859 (dmcphers@redhat.com)
- Merge pull request #3210 from
  jwforres/admin_console_testcase_coverage_exclusion
  (dmcphers+openshiftbot@redhat.com)
- Exclude admin console from test coverage for now (jforrest@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Adding missing rubygem requires to broker, console and admin-console packages
  (kraman@gmail.com)
- <admin-console> broker proxy RPP change + filling in README
  (lmeyer@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- <broker> Add mocking for Cartridge.categories in unit test
  (jolamb@redhat.com)
- <application.rb> Add feature to carts to handle wildcard ENV variable
  subscriptions (jolamb@redhat.com)
- origin_broker_25 (lnader@redhat.com)
- Simplify capabilities to be more model like, and support clean proxying of
  inherited properties (ccoleman@redhat.com)
- Support running broker tests directly Force scopes to use checked ids and
  avoid symbolizing arbitrary strings Use .present? instead of .count > 0 (for
  performance) Handle ValidationExceptions globally (ccoleman@redhat.com)
- Bug 985656 - minor improvement for consistency in broker and console spec
  files (bleanhar@redhat.com)
- Admin console framework (jforrest@redhat.com)
- Merge pull request #3111 from pravisankar/dev/ravi/bug983038
  (dmcphers+openshiftbot@redhat.com)
- Remove ecdsa ssh key type from supported list. Rationale: Due to patent
  concerns, ECC support is not bundled in fedora/rhel(needed for ecdsa key
  generation).            So even if someone has a valid ecdsa keys, sshd
  server on our node won't be able to authenticate the user.
  (rpenta@redhat.com)
- <broker> make parallel passenger baseuri change in SCL conf file
  (lmeyer@redhat.com)
- <broker> fix tests against broker base URI change (lmeyer@redhat.com)
- <broker> re-base the broker URI from /broker => / (lmeyer@redhat.com)
- Merge pull request #3083 from smarterclayton/strong_consistency_is_default
  (dmcphers+openshiftbot@redhat.com)
- Authorization test case was wrong (ccoleman@redhat.com)
- Bug 973796 - PassengerPreStart points at root which logs errors
  (bleanhar@redhat.com)
- Strong consistency is the default for mongoid (ccoleman@redhat.com)
- Merge pull request #3044 from brenton/BZ973796
  (dmcphers+openshiftbot@redhat.com)
- Bug 973796 - PassengerPreStart points at root which logs errors
  (bleanhar@redhat.com)
- Changing error message to make it more clear (abhgupta@redhat.com)
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Remove Online specific references: -Remove hard-coded cart name references.
  -Remove login validations from CloudUser model, login validation must be done
  by authentication plugin. -Remove 'medium' gear size references -All 'small'
  gear size references must be from configuration files. -Remove stale
  application_observer.rb and its references -Remove stale 'abstract' cart
  references -Remove duplicate code from rest controllers -Move all
  get_rest_{user,domain,app,cart} methods in RestModelHelper module. -Cleanup
  unnecessary TODO/FIXME comments in broker. (rpenta@redhat.com)
- Merge pull request #2927 from smarterclayton/bug_970257_support_git_at_urls
  (dmcphers+openshiftbot@redhat.com)
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
- Merge pull request #2946 from maxamillion/dev/maxamillion/enable_rhcl
  (dmcphers+openshiftbot@redhat.com)
- Tests pass fully (add initial_git_url for earlier api versions).  Control
  what values of URI get persisted to DB (passwords and userinfo from clone
  specs should not be) (ccoleman@redhat.com)
- Broker source mode should reload classes, only load plugins in
  broker_plugins.rb (ccoleman@redhat.com)
- enable rhscl repos - add wrapper (admiller@redhat.com)
- bz969696 - download cart settings (rchopra@redhat.com)
- First pass at removing v1 cartridges (dmcphers@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-0
- Bump up version to 1.15

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- <broker.conf> default to usage db tracking on (lmeyer@redhat.com)
- Print warning instead of failing tests if there is an unknown auth plugin
  configured (kraman@gmail.com)
- Include psych gem only on F19 systems where it has been split out
  (kraman@gmail.com)
- Update broker tests with new versions of packages for F19 Fix bug where test
  was not creating user on before using it (kraman@gmail.com)
- Create usage.log when broker is installed (kraman@gmail.com)
- Relax rake and mocha gem version dependencies (kraman@gmail.com)
- origin_runtime_138 - Add SSL_ENDPOINT variable and filter whether carts use
  ssl_to_gear. (rmillner@redhat.com)
- Merge pull request #2740 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- fix sanity tests (dmcphers@redhat.com)
- return HTTP Status code 200 from DELETE instead of 204 (lnader@redhat.com)
- Fixing alias tests (abhgupta@redhat.com)
- vendoring of cartridges (rchopra@redhat.com)
- Merge pull request #2576 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix to cartridge cache test (rchopra@redhat.com)
- Removing externally_reserved_uids_size attribute from districts
  (abhgupta@redhat.com)
- enable downloading of cartridges (rchopra@redhat.com)
- Bug 963981 - Fix app events controller Use canonical_name/canonical_namespace
  for application/domain respectively when using find_by op.
  (rpenta@redhat.com)
- Add fault tolerance code to UsageRecord model (rpenta@redhat.com)
- Merge pull request #2481 from smarterclayton/add_param_for_downloadable_carts
  (dmcphers@redhat.com)
- Mocha should be constrained (ccoleman@redhat.com)
- Bug 963156 (dmcphers@redhat.com)
- Merge pull request #2424 from smarterclayton/upgrade_to_mocha_0_13_3
  (admiller@redhat.com)
- Add 'cartridges[][url]' as an optional parameter on ADD_APPLICATION and 'url'
  as an optional parameter on ADD_CARTRIDGE (ccoleman@redhat.com)
- Merge pull request #2450 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2426 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Added API for cartridge search (lnader@redhat.com)
- Switching v2 to be the default (dmcphers@redhat.com)
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)
- Upgrade to mocha 0.13.3 (compatible with Rails 3.2.12) (ccoleman@redhat.com)
- Allow broker to be run in source mode and load source plugins
  (ccoleman@redhat.com)
- Broker requires parse config newer than 1.0.1 (ccoleman@redhat.com)
- <broker><oo-accept-broker> Bug 958674 - Fix Mongo SSL support
  (jdetiber@redhat.com)
- Remove last external reference (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Rename "external cartridge" to "downloaded cartridge".  UI should call them
  "personal" cartridges (ccoleman@redhat.com)
- Merge pull request #2300 from pravisankar/dev/ravi/card21
  (dmcphers+openshiftbot@redhat.com)
- Broker changes for supporting unsubscribe connection event. Details: When one
  of the component is removed from the app and if it has published some content
  to other components located on different gears, we issue unsubscribe event on
  all the subscribing gears to cleanup the published content.
  (rpenta@redhat.com)
- Merge pull request #2306 from
  smarterclayton/bug_958192_document_auth_scope_config
  (dmcphers+openshiftbot@redhat.com)
- Bug 958192 - Document scopes in config (ccoleman@redhat.com)
- Use standard name for boolean (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Card 551 (lnader@redhat.com)
- <broker> Bug 956351 - Add mongo rubygem dependency, docs (jolamb@redhat.com)
- Merge pull request #2282 from rajatchopra/url_story
  (dmcphers+openshiftbot@redhat.com)
- support for external cartridge through urls (rchopra@redhat.com)
- Removed 'setmaxstorage' option for oo-admin-ctl-user script. Added
  'setmaxtrackedstorage' and 'setmaxuntrackedstorage' options for oo-admin-ctl-
  user script. Updated oo-admin-ctl-user man page. Max allowed additional fs
  storage for user will be 'max_untracked_addtl_storage_per_gear' capability +
  'max_tracked_addtl_storage_per_gear' capability. Don't record usage for
  additional fs storage if it is less than
  'max_untracked_addtl_storage_per_gear' limit. Fixed unit tests and models to
  accommodate the above change. (rpenta@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Bug 956670 - Fix static references to small gear size (jdetiber@redhat.com)
- Merge pull request #2219 from detiber/useractionlogfix
  (dmcphers+openshiftbot@redhat.com)
- Add broker config for external cartridges (ccoleman@redhat.com)
- <broker> Updated spec file for correct user_action.log location <oo-accept-
  broker> Added permission check for rest api logs (jdetiber@redhat.com)
- General REST API clean up - centralizing log tags and getting common objects
  (lnader@redhat.com)
- Merge pull request #2062 from Miciah/move-plugins.d-README-from-node-to-
  broker (dmcphers+openshiftbot@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Merge pull request #2111 from brenton/specs3
  (dmcphers+openshiftbot@redhat.com)
- Removing the MongoDB dependency from the Broker rpm spec
  (bleanhar@redhat.com)
- Merge pull request #2080 from brenton/specs2
  (dmcphers+openshiftbot@redhat.com)
- Move to minitest 3.5.0, webmock 1.8.11, and mocha 0.12.10
  (ccoleman@redhat.com)
- Cucumber is not a runtime requirement for the Broker (bleanhar@redhat.com)
- Move plugins.d/README from the node to the broker (miciah.masters@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.5.2-1
- Fixing broker and nsupdate plugin deps (bleanhar@redhat.com)
- Replace zend with ruby in broker function test as zend is not available on
  origin. (kraman@gmail.com)
- Gear Move changes: Keep same uid for the gear When changing the gear from one
  district to another. (rpenta@redhat.com)
- Card 534 (lnader@redhat.com)
- Merge pull request #1926 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Part 2 of Card 536 (lnader@redhat.com)
- Part 1 of Card 536 (lnader@redhat.com)
- Ensuring district UID randmoization check does not report false negatives
  (abhgupta@redhat.com)
- broker does not depend on bind (markllama@gmail.com)
- Merge pull request #1878 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Fixing broker functional tests:   - PHP version selection based on OS   -
  Creating user account for functional test on Origin (kraman@gmail.com)
- Merge pull request #1867 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- default read should be from primary (rchopra@redhat.com)
- Randomizing UIDs in available_uids list for district (abhgupta@redhat.com)
- Card 515 - Improve test coverage (lnader@redhat.com)
- Merge pull request #1789 from brenton/master (dmcphers@redhat.com)
- updated unit test (lnader@redhat.com)
- Read values from node.conf for origin testing. (rmillner@redhat.com)
- Update docs generation and add node/cartridge guides [WIP]
  https://trello.com/c/yUMBZ0P9 (kraman@gmail.com)
- Adding SESSION_SECRET settings to the broker and console
  (bleanhar@redhat.com)
- Merge pull request #1702 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)
- US506 : Broker rails flag to enable/disable broker in maintenance mode
  (rpenta@redhat.com)
- Merge pull request #1633 from lnader/revert_pull_request_1486
  (dmcphers+openshiftbot@redhat.com)
- Changed private_certificate to private_ssl_certificate (lnader@redhat.com)
- Add SNI upload support to API (lnader@redhat.com)
- Support cache config (ccoleman@redhat.com)
- Merge pull request #1637 from brenton/BZ921257 (dmcphers@redhat.com)
- Replacing get_value() with config['param'] style calls for new version of
  parseconfig gem. (kraman@gmail.com)
- Removing parseconfig version (dmcphers@redhat.com)
- Bug 921257 - Warn users to change the default AUTH_SALT (bleanhar@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.1-1
- Bug 911322 (lnader@redhat.com)
- Merge pull request #1535 from brenton/gemfile_lock_fixes
  (dmcphers+openshiftbot@redhat.com)
- Skip Usage capture for sub-account users (rpenta@redhat.com)
- Merge pull request #1512 from rajatchopra/master (dmcphers@redhat.com)
- Merge pull request #1536 from
  smarterclayton/bug_916559_existing_broker_keys_broken (dmcphers@redhat.com)
- Merge pull request #1532 from smarterclayton/bug_916132_fix_prodrb_for_broker
  (dmcphers@redhat.com)
- force stop - fix bug#915587 (rchopra@redhat.com)
- Bug 916559 - Existing broker keys broken after stage upgrade
  (ccoleman@redhat.com)
- Gemfile.lock ownership fixes (bleanhar@redhat.com)
- Bug 916132 - Fix production.rb for scope loading (ccoleman@redhat.com)
- adding coverage (dmcphers@redhat.com)
- add coverage for domain observer being called (dmcphers@redhat.com)
- Merge pull request #1441 from pravisankar/dev/ravi/us3409
  (dmcphers+openshiftbot@redhat.com)
- reverted US2448 (lnader@redhat.com)
- Added index on 'login' for usage_record and usage mongoid models Added
  separate usage audit log, /var/log/openshift/broker/usage.log instead of
  syslog. Moved user action log from /var/log/openshift/user_action.log to
  /var/log/openshift/broker/user_action.log Added Distributed lock used in oo-
  admin-ctl-usage script Added Billing Service interface Added oo-admin-ctl-
  usage script to list and sync usage records to billing vendor Added oo-admin-
  ctl-usage to broker-util spec file Fixed distributed lock test Add billing
  service to origin-controller Some more bug fixes (rpenta@redhat.com)
- ignore errors in teardown (lnader@redhat.com)
- Added certificate_added_at to alias (lnader@redhat.com)
- Added validation for SSL certificate and private key (lnader@redhat.com)
- Added unit tests for alias and domain (lnader@redhat.com)
- US2448 (lnader@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- Implement authorization support in the broker (ccoleman@redhat.com)
- Revert to original RAILS_LOG_PATH behavior (ccoleman@redhat.com)
- Bug 913816 - Fix log tailer to pick up the correct config
  (ccoleman@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- Removing references to cgconfig/all (kraman@gmail.com)
- Move the broker-only configuration below node in priority.
  (rmillner@redhat.com)
- fix rake test:sanity (rchopra@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- broker unit testcases (rchopra@redhat.com)
- Fixes to get builds and tests running on RHEL: (kraman@gmail.com)
- Apply changes from comments. Fix diffs from brenton/origin-server.
  (john@ibiblio.org)
- Fix dependency on openshift rubygem (john@ibiblio.org)
- Fixes for ruby193 (john@ibiblio.org)
- Broker and broker-util spec files (john@ibiblio.org)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.0-1
- Update to version 1.5.0

* Fri Feb 15 2013 Troy Dawson <tdawson@redhat.com> 1.4.1-1
- Bump up version (tdawson@redhat.com)
- Added missing create for broker httpd logs dir. Updated owner of broker and
  broker httpd logs to apache:apache. (kraman@gmail.com)
- Fixing bad merge (kraman@gmail.com)
- Fixing bad merge (kraman@gmail.com)
- move logs to a more standard location (admiller@redhat.com)
- Merge pull request #1289 from
  smarterclayton/isolate_api_behavior_from_base_controller
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1288 from smarterclayton/improve_action_logging
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1339 from tdawson/tdawson/cleanup-spec-headers
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'improve_action_logging' into
  isolate_api_behavior_from_base_controller (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into improve_action_logging
  (ccoleman@redhat.com)
- change %%define to %%global (tdawson@redhat.com)
- Bug 884934 (asari.ruby@gmail.com)
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- Setting namespace and canonical_namespace for the domain together and doing
  the same for the application (abhgupta@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)
- remove BuildRoot: (tdawson@redhat.com)
- move rest api tests to functionals (dmcphers@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)
- Improving coverage tooling (dmcphers@redhat.com)
- Merge pull request #1303 from pravisankar/dev/ravi/app-lock-timeout
  (dmcphers+openshiftbot@redhat.com)
- fix issue with reserve given not taking the valid uid (dmcphers@redhat.com)
- - Added Application Lock Timeout (default: 10 mins) - Unit tests for Lock
  model (rpenta@redhat.com)
- Ensure lib directory is in the autoload path, do not require rubygems when
  developing from source (ccoleman@redhat.com)
- Do not use a global variable to initialize a RestReply - use a controller
  helper method. (ccoleman@redhat.com)
- netrc should only be loaded in source mode (test env loads it via a patched
  gem) (ccoleman@redhat.com)
- Allow broker to be started using source directly (ccoleman@redhat.com)
- working on testing coverage (dmcphers@redhat.com)
- Handle numbers for users and passwords (dmcphers@redhat.com)
- US2626 changes based on feedback - Add application name in Usage and
  UsageRecord models - Change 'price' to 'usage_rate_usd' in rest cartridge
  model - Change 'charges' to 'usage_rates' in rails configuration - Rails
  configuration stores usage_rates for different currencies (currently only
  have usd) (rpenta@redhat.com)
- Merge pull request #1260 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 906266, bug 906230, and bug 906233 (abhgupta@redhat.com)
- US3350 - Expose a plan_upgrade_enabled capability that indicates whether
  users can select a plan (ccoleman@redhat.com)
- Merge pull request #1230 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1232 from pravisankar/dev/ravi/fix-broker-extended-tests
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1233 from danmcp/master (dmcphers@redhat.com)
- Fix Broker extended tests, Don't call observers for cloud user model if the
  record is already persisted. (rpenta@redhat.com)
- remove consumed_gear_sizes (dmcphers@redhat.com)
- removing legacy broker rest api (abhgupta@redhat.com)

* Fri Feb 08 2013 Troy Dawson <tdawson@redhat.com> 1.4.0-1
- Update to version 1.4.0

* Mon Jan 28 2013 Krishna Raman <kraman@gmail.com> 1.1.2-1
- Merge pull request #1212 from brenton/misc5
  (dmcphers+openshiftbot@redhat.com)
- Bug 873180 (dmcphers@redhat.com)
- Disable test that doesnt work with concurrency (dmcphers@redhat.com)
- BZ888056 - production.rb should not be marked as a conf file
  (bleanhar@redhat.com)
- fixing rebase/merge issue that caused missing comma in test rails env
  configuration (abhgupta@redhat.com)
- using openshift_broker_test db in test rails env for origin broker
  (abhgupta@redhat.com)
- Fix SSL option in mongoid.yml (rpenta@redhat.com)
- bumping rest api version to handle change in rest user model
  (abhgupta@redhat.com)
- Fix usage model unit test (rpenta@redhat.com)
- Fix Usage: Through an error instead of bailing out when gear was created with
  usage-tracking disabled and later on gear was destroyed with usage-tracking
  enabled (rpenta@redhat.com)
- District unit test: clear all districts that were created during teardown
  phase (rpenta@redhat.com)
- Remove old mongo datastore test (rpenta@redhat.com)
- Added system, subuser, usage tests from li repo (rpenta@redhat.com)
- Fix district model and district unit tests rework (rpenta@redhat.com)
- fixing broker integration tests (abhgupta@redhat.com)
- minor cleanup (rpenta@redhat.com)
- Populate mongoid.yml config from Rails datastore configuration.
  (rpenta@redhat.com)
- uncommenting app_cart_delete_v1 rest unit test (abhgupta@redhat.com)
- uncommenting scale down unit test (abhgupta@redhat.com)
- uncommenting app scale down unit tests (abhgupta@redhat.com)
- fixing integration test (abhgupta@redhat.com)
- Bug 889947 (lnader@redhat.com)
- Fix for bug 889978 (abhgupta@redhat.com)
- commenting out broken tests for now - were always broke but error was hidden
  before (dmcphers@redhat.com)
- fixing broker tests again after rebase (abhgupta@redhat.com)
- fixing mongoid.yml for broker tests (abhgupta@redhat.com)
- fix mongoid.yml username (dmcphers@redhat.com)
- add dynect migration (dmcphers@redhat.com)
- removed debug statements (lnader@redhat.com)
- add random number to app alias (lnader@redhat.com)
- removing app templates and other changes (dmcphers@redhat.com)
- fixing rest_api_test and fixing backward compatibility bugs
  (lnader@redhat.com)
- fix broker integration tests (dmcphers@redhat.com)
- fix create domain breakage (dmcphers@redhat.com)
- fix broker functional tests (dmcphers@redhat.com)
- fix functional tests (dmcphers@redhat.com)
- fixing cloud user test cases (dmcphers@redhat.com)
- test case fixes + typo fixes (dmcphers@redhat.com)
- fixup cloud user usages (dmcphers@redhat.com)
- fix db for test (dmcphers@redhat.com)
- add bson_ext (dmcphers@redhat.com)
- Added support for thread dump. Fixed default username in mongoid.yml file
  (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Ensure write to at least 2 mongo instances (dmcphers@redhat.com)
- Merge pull request #1192 from Miciah/bz-902630-failed-to-reload-openshift-
  broker-service (dmcphers@redhat.com)
- Bug 902630: fix `service openshift-broker reload` (miciah.masters@gmail.com)
- Adding support for broker to mongodb connections over SSL
  (calfonso@redhat.com)

* Fri Jan 11 2013 Troy Dawson <tdawson@redhat.com> 1.1.1-1
- BZ876324 resolve ServerName/NameVirtualHost situation for
  node/broker/ssl.conf (lmeyer@redhat.com)
- Minor tweak to the broker log owner/mode issue (bleanhar@redhat.com)
- BZ888671 -  oo-accept-broker or oo-accept-systems will create production.log,
  the file's permission is wrong. (bleanhar@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)
- BZ876937 - Return "FAILED" if trying to stop openshift-console which is
  already stopped (bleanhar@redhat.com)
- create :default_gear_capabilities conf key for setting default gear
  capabilities a user has at creation (lmeyer@redhat.com)
- fixing mongo connection issues for build (dmcphers@redhat.com)
- Bug 880370 (dmcphers@redhat.com)
- Bug 878270 - everyone read user_action.log (bleanhar@redhat.com)
- fix elif typos (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- Bug 878328 - Drupal and Wordpress should be tagged 'instant_app'
  (ccoleman@redhat.com)
- F18 compatibility fixes   - apache 2.4   - mongo journaling   - JDK 7   -
  parseconfig gem update Bugfix for Bind DNS plugin (kraman@gmail.com)
- Fix tests to work with remote-user auth (miciah.masters@gmail.com)
- add additional gem deps (dmcphers@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- update Gemfile version (dmcphers@redhat.com)
- use version 0.12.0 (dmcphers@redhat.com)
- remove mocha version (dmcphers@redhat.com)
- fixing tests (dmcphers@redhat.com)
- getting tests working (dmcphers@redhat.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- Implement all templates as the base quickstarts, and make quickstart.rb a bit
  more flexible (ccoleman@redhat.com)
- Support COMMUNITY_QUICKSTARTS_URL parameter for serving hardcoded quickstarts
  vs. public quickstarts, and test that these values are returned.
  (ccoleman@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)
- specifying mocha gem version and fixing tests (abhgupta@redhat.com)
- BZ873970, BZ873966 - disabling HTTP TRACE for the Broker, Nodes and Console
  (bleanhar@redhat.com)
- Adding rewrites to / to go to /console for http and https vhosts Added
  NamedVirtualHost for the 443 vhost to avoid conflict with ssl.conf
  (calfonso@redhat.com)
- Set ENV["RAILS_ENV"] in boot.rb (miciah.masters@gmail.com)
- Removing node gem requirement from broker script (kraman@gmail.com)
- Bug 871436 - moving the default path for AUTH_PRIVKEYFILE and AUTH_PUBKEYFILE
  under /etc (bleanhar@redhat.com)
- OpenShift Origin console package (calfonso@redhat.com)
- BZ870385 - Remove unnecessary %%post logfile touching from the Broker
  (bleanhar@redhat.com)
- Removing a useless semanage command from the broker's %%postun
  (bleanhar@redhat.com)
- openshift-origin-broker rpmdiff errors (bleanhar@redhat.com)
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)
- fixing file name typo in usage and fixing domain name in test environment
  file (abhgupta@redhat.com)
- Bug 868331 - corrected test (lnader@redhat.com)
- remove various hardcoded usage of file in /tmp (mscherer@redhat.com)

* Mon Oct 22 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.17-1
- Merge pull request #737 from sosiouxme/master (dmcphers@redhat.com)
- Merge pull request #734 from danmcp/master (openshift+bot@redhat.com)
- have openshift-broker report bundler problems rather than silently fail. also
  fix typo in oo-admin-chk usage (lmeyer@redhat.com)
- Bug 868858 (dmcphers@redhat.com)
- Bug 868782 - [Installation]Prompt "semanage: command not found"
  (bleanhar@redhat.com)
- Merge pull request #728 from kraman/build_script_updates
  (openshift+bot@redhat.com)
- Merge pull request #730 from kraman/848255 (openshift+bot@redhat.com)
- removing remaining cases of SS and config.ss (dmcphers@redhat.com)
- Fixing Origin build scripts (kraman@gmail.com)
- Fix for Bugz#848255 (kraman@gmail.com)

* Thu Oct 18 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.16-1
- Merge pull request #657 from Miciah/drop-openshift-origin-node-from-broker-
  Gemfile-3 (openshift+bot@redhat.com)
- Drop openshift-origin-node from broker's Gemfile (miciah.masters@gmail.com)

* Tue Oct 16 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.6.15-1
- Merge pull request #681 from pravisankar/dev/ravi/bug/821107
  (openshift+bot@redhat.com)
- BZ866854 - Removing abstract cartridge dep from broker spec
  (bleanhar@redhat.com)
- Support more ssh key types (rpenta@redhat.com)
- Merge pull request #636 from pravisankar/dev/ravi/bug/863973
  (openshift+bot@redhat.com)
- Fix for bug# 863973 (rpenta@redhat.com)

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
