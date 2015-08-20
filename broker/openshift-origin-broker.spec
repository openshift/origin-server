%global htmldir %{_var}/www/html
%global brokerdir %{_var}/www/openshift/broker
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global v8_prefix v8314-
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
Version:       1.16.2
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
# Install v8 from its own collection
Requires:      %{?v8_prefix:%v8_prefix}v8
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
Requires:      %{?scl:%scl_prefix}rubygem-net-ssh
Requires:      %{?scl:%scl_prefix}rubygem-origin
Requires:      %{?scl:%scl_prefix}rubygem-polyglot
Requires:      %{?scl:%scl_prefix}rubygem-rack
Requires:      %{?scl:%scl_prefix}rubygem-rack-cache
Requires:      %{?scl:%scl_prefix}rubygem-rack-ssl
Requires:      %{?scl:%scl_prefix}rubygem-rack-test
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-railties
Requires:      %{?scl:%scl_prefix}rubygem-rdoc
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
Requires:      %{?scl:%scl_prefix}rubygem-syslog-logger

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
%attr(0640,-,-) %ghost %{_var}/log/openshift/broker/production.log
%attr(0640,-,-) %ghost %{_var}/log/openshift/broker/development.log
%attr(0640,-,-) %ghost %{_var}/log/openshift/broker/user_action.log
%attr(0640,-,-) %ghost %{_var}/log/openshift/broker/usage.log
%attr(0750,-,-) %{brokerdir}/script
%attr(0750,-,-) %{brokerdir}/tmp
%attr(0750,-,-) %{brokerdir}/tmp/cache
%attr(0750,-,-) %{brokerdir}/tmp/pids
%attr(0750,-,-) %{brokerdir}/tmp/sessions
%attr(0750,-,-) %{brokerdir}/tmp/sockets
%dir %attr(0750,-,-) %{brokerdir}/httpd/conf.d
%{brokerdir}
%{htmldir}/broker
# these are conf files, but we do not usually want users to edit them:
%config %{brokerdir}/httpd/broker.conf
%config %{brokerdir}/httpd/httpd.conf
%config %{brokerdir}/config/environments/production.rb
%config %{brokerdir}/config/environments/development.rb
# these confs are likely to require user editing; updates should not overwrite edits:
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
* Tue Aug 19 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- cloud_user: enable normalization of user logins. (lmeyer@redhat.com)
- fix whitespace (lmeyer@redhat.com)
- Add broker flag to disable user selection of region (cewong@redhat.com)
- Test improvements that were affecting enterprise test scenarios
  (jdetiber@redhat.com)
- Bug 1123371: Fixing issue with setting the cartridge multiplier
  (abhgupta@redhat.com)
- Bug 1122657: Fixing logic to select gear for scaledown (abhgupta@redhat.com)
- Bug 1121971: Validate based on domain owner capabilities during app create
  (jliggitt@redhat.com)
- Update Application Controller Test for ruby-2.0 cartridge
  (j.hadvig@gmail.com)

* Thu Jul 10 2014 Adam Miller <admiller@redhat.com> 1.16.1-1
- bump origin-broker version for origin v4 release (admiller@redhat.com)
- Updated REST API docs (lnader@redhat.com)
- Do not attempt to filter if no conf is provided (decarr@redhat.com)
- Bug 1115274 - Fix 'default' field in /regions REST api (rpenta@redhat.com)
- Bug 1115238 - Add DEFAULT_REGION_NAME param to the broker configuration.
  (rpenta@redhat.com)
- Merge pull request #5559 from derekwaynecarr/restrict_cart_gear_size
  (dmcphers+openshiftbot@redhat.com)
- broker: add PREVENT_ALIAS_COLLISION option. (lmeyer@redhat.com)
- Restrict carts to set of gear sizes (decarr@redhat.com)
- Enables user to specify a region when creating an application
  (lnader@redhat.com)
- Expose region and zones of gears in REST API (lnader@redhat.com)
- Bug 1103131: Remove authorize! check and let Team.accessible() limit which
  global teams a user can see (jliggitt@redhat.com)
- Ensure at least one scope's conditions are met, even when combined with
  complex queries (jliggitt@redhat.com)
- Bug 1102273: Make domain scopes additive (jliggitt@redhat.com)
- Change GroupOverride.empty? so group overrides with 1 component is not
  considered empty. Change logic that splits group overrides up if their
  component don't belong to the same platform. (vlad.iovanov@uhurusoftware.com)
- Add Team management UI (jliggitt@redhat.com)
- updates for RHSCL 1.1 (admiller@redhat.com)
- Bug 1094541 - check for null values (lnader@redhat.com)
- Added REST API docs for version 1.7 (lnader@redhat.com)
- Updated REST API docs version 1.6 (lnader@redhat.com)
- Merge pull request #5375 from ironcladlou/scalable-unidling
  (dmcphers+openshiftbot@redhat.com)
- Bug 1093804: Validating the node returned by the gear-placement plugin
  (abhgupta@redhat.com)
- Support unidling scalable apps (ironcladlou@gmail.com)
- added DEFAULT_MAX_UNTRACKED_ADDTL_STORAGE_PER_GEAR and
  DEFAULT_MAX_TRACKED_ADDTL_STORAGE_PER_GEAR (lnader@redhat.com)
- Bug 1091044 (lnader@redhat.com)
- Bug 1091940 - DEFAULT_ALLOW_HA must be a bool (bleanhar@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- Merge pull request #5331 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- X-Remote-User must be blocked at the toplevel apache (bleanhar@redhat.com)
- switch to using .empty? instead of str != "" (kraman@gmail.com)
- Changes to enable running origin broker in docker image * Fix openssl
  requirement in Dockerfile * Remove unused gem * Modify mongoid config to be
  capable of running unauthenticated (kraman@gmail.com)
- Adding test coverage (dmcphers@redhat.com)
- Adding test cases (dmcphers@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- Add test coverage (dmcphers@redhat.com)
- Merge pull request #5309 from liggitt/abhgupta-abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- Add run_jobs tests, fix timeout query (jliggitt@redhat.com)
- Update access_controlled_test for new run_jobs behavior (jliggitt@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- Merge pull request #5262 from
  liggitt/bug_1083544_reentrant_membership_change_ops
  (dmcphers+openshiftbot@redhat.com)
- Bug 1088941: Exclude non-member global teams from index (jliggitt@redhat.com)
- Merge pull request #5287 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Adding a config flag in the broker to selectively manage HA DNS entries
  (abhgupta@redhat.com)
- Bug 1083544: Make member change ops re-entrant (jliggitt@redhat.com)
- Fix access_controlled_test to save explicit_role in app before testing
  propagation (jliggitt@redhat.com)
- Bug 1086094: Multiple changes for cartridge colocation We are:  - taking into
  account the app's complete group overrides  - allowing only plugin carts to
  colocate with web/service carts  - blocking plugin (except sparse) carts from
  responding to scaling min/max changes (abhgupta@redhat.com)
- Adding test coverage for to_xml (dmcphers@redhat.com)
- Updated REST API docs (lnader@redhat.com)
- Bug 1087710: Removing explicit role with implicit role present leaves higher
  role in place (jliggitt@redhat.com)
- Bug 1086567: Handle implicit members leaving (jliggitt@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Add test for elevating and lowering the explicit role of a member who also
  has an implicit grant (jliggitt@redhat.com)
- Bug 1086370: removing one team removes all explicit members
  (jliggitt@redhat.com)
- Merge pull request #5187 from pravisankar/dev/ravi/fix-testcases
  (dmcphers+openshiftbot@redhat.com)
- Fix test cases:  - Ensure one test/testcase does not depend or affect other
  test/testcase (our tests are run concurrently)  - Use
  assert_equal/assert_not_equal instead of assert to provide better error
  messages in case of failures (rpenta@redhat.com)
- Merge pull request #5164 from sosiouxme/remove-vhost-directives
  (dmcphers+openshiftbot@redhat.com)
- Fixing error message around submodule repo (dmcphers@redhat.com)
- Bug 1071272 - oo-admin-repair: Only allow node removal from its district when
  no apps are referencing that node (rpenta@redhat.com)
- httpd conf: set better defaults (lmeyer@redhat.com)
- Enable global team view for functional tests (jliggitt@redhat.com)
- Add global_teams capability (jliggitt@redhat.com)
- Formatting fixes (dmcphers@redhat.com)
- Adding user create tracking event (dmcphers@redhat.com)
- Removed global flag - using owner_id=nil as indicator for global team
  (lnader@redhat.com)
- Require global flag on search (lnader@redhat.com)
- fixed test to nil owner_id (lnader@redhat.com)
- fixed validation and tests (lnader@redhat.com)
- cleaned up team validation (lnader@redhat.com)
- escape search string (lnader@redhat.com)
- added test to make sure validation does not prevent save (lnader@redhat.com)
- Global teams (lnader@redhat.com)
- Analytics Tracker (dmcphers@redhat.com)
- Add app to domain member tests (jliggitt@redhat.com)
- Merge pull request #5089 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- REST API docs for team (lnader@redhat.com)
- Bug 989941: preventing colocation of cartridges that independently scale
  (abhgupta@redhat.com)
- Merge pull request #5069 from pravisankar/dev/ravi/bug1078008
  (dmcphers+openshiftbot@redhat.com)
- Bug 1078008 - Restrict cloning app if storage requirements are not matched
  (rpenta@redhat.com)
- Bug 1078814: Adding more validations for cartridge manifests
  (abhgupta@redhat.com)
- Merge pull request #5048 from liggitt/oauth_test
  (dmcphers+openshiftbot@redhat.com)
- Fix oauth test for remote_user auth plugin (jliggitt@redhat.com)
- Fix oo-admin-ctl-* functional test's usage of /tmp/openshift
  (bleanhar@redhat.com)
- Fixing oo-broker for environments not using docker containers
  (bleanhar@redhat.com)
- Add test for scope param in Authorizations#destroy_all (jliggitt@redhat.com)
- Use rails http basic auth parsing, reuse controller, correctify comments
  (jliggitt@redhat.com)
- Test temporary timeout (jliggitt@redhat.com)
- Update tests (jliggitt@redhat.com)
- Return errors other than client_id or redirect_uri (jliggitt@redhat.com)
- SSO OAuth support (jliggitt@redhat.com)
- Merge pull request #5030 from liggitt/teams_api_includes_members
  (dmcphers+openshiftbot@redhat.com)
- Include members in /team/:id, and optionally in /teams (jliggitt@redhat.com)
- Broker spec file fix (bleanhar@redhat.com)
- Update tests to not use any installed gems and use source gems only Add
  environment wrapper for running broker util scripts (jforrest@redhat.com)
- fixed broker extended test - test cases covered by functional tests
  (lnader@redhat.com)
- Fix typo (dmcphers@redhat.com)
- Remove show/create/update implementations from team_members_controller.
  Require role param when adding team members. Test for missing/empty role
  param (jliggitt@redhat.com)
- Make sure pending ops are run before tests, reinitialize the controller to
  pick up models modified by testcase (jliggitt@redhat.com)
- Distinguish between non-members and indirect members in warning messages. Do
  not include login field for members of type 'team' (jliggitt@redhat.com)
- User can only add teams to domain that he owns (lnader@redhat.com)
- Added allowed_roles/member_types, removed team add by name, refactored
  removed_ids (lnader@redhat.com)
- Added validate_role and validate_type to base class and overide
  (lnader@redhat.com)
- fixed test failure (lnader@redhat.com)
- team member update should only allow roles view and none (lnader@redhat.com)
- Revised members controller to type qualify (lnader@redhat.com)
- Removed update ability from teams.  Teams cannot be renamed
  (lnader@redhat.com)
- Delete user teams on force_delete (lnader@redhat.com)
- Bug 1075048 - null checking on role to update (lnader@redhat.com)
- Teams API (lnader@redhat.com)
- Added User pending-op-group/pending-op functionality Added pending op groups
  for user add_ssh_keys/remove_ssh_keys (rpenta@redhat.com)
- Modify some test setups to work correctly in Origin context
  (hripps@redhat.com)
- Merge pull request #4944 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Adding test coverage (dmcphers@redhat.com)
- Fix "create scalable app with custom web_proxy" test expectation. Fix getting
  cart from CartridgeCache in the context of an application.
  (vlad.iovanov@uhurusoftware.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Fix formatting (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Removing f19 logic (dmcphers@redhat.com)
- Merge pull request #4840 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Added max_teams capability (lnader@redhat.com)
- Clean up model objects after test (jliggitt@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Enable docker builds of openshift-origin-broker (jforrest@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Surface owner storage capabilities and storage rates (jliggitt@redhat.com)
- Revert "Multiple fixes for stability" (dmcphers@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Improve finding a member in a members collection (jliggitt@redhat.com)
- Test explicit/implicit role interaction (jliggitt@redhat.com)
- Handle duplicate removes, removal of non-members (jliggitt@redhat.com)
- Code review comments (jliggitt@redhat.com)
- Team object, team membership (jliggitt@redhat.com)
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- Bug 1066945 - Fixing urls (dmcphers@redhat.com)
- Merge pull request #4786 from smarterclayton/bug_1065318_multiplier_lost
  (dmcphers+openshiftbot@redhat.com)
- Bug 1065318 - Multiplier being reset (ccoleman@redhat.com)
- Speeding up broker tests (dmcphers@redhat.com)
- Merge pull request #4767 from pravisankar/dev/ravi/bug1055475
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055475 - Mark require_district = true when zones are required in
  rpc_find_all_available (rpenta@redhat.com)
- Bug 1065318 - Multiplier overrides lost during deserialization
  (ccoleman@redhat.com)
- Bug 1064720 - Group overrides lost during scale (ccoleman@redhat.com)
- Merge pull request #4753 from
  smarterclayton/make_configure_order_define_requires
  (dmcphers+openshiftbot@redhat.com)
- Configure-Order should influence API requires (ccoleman@redhat.com)
- Gear size conflicts should be covered by a unit test (ccoleman@redhat.com)
- Merge pull request #4732 from
  smarterclayton/bug_1062852_cant_remove_shared_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 1062852 - Can't remove mysql from shared gear (ccoleman@redhat.com)
- Bug 1063654 - Prevent obsolete cartridge use except for builders
  (ccoleman@redhat.com)
- Merge pull request #4708 from smarterclayton/bug_1063109_trim_required_carts
  (dmcphers+openshiftbot@redhat.com)
- Bug 1060339 - Move blacklisted check for domain/application to the controller
  layer. oo-admin-ctl-domain/oo-admin-ctl-app will use domain/application model
  and will be able to create/update blacklisted name. (rpenta@redhat.com)
- Bug 1063109 - Required carts should be handled higher in the model
  (ccoleman@redhat.com)
- Merge pull request #4688 from
  smarterclayton/bug_1059858_expose_requires_to_clients
  (dmcphers+openshiftbot@redhat.com)
- Support changing categorizations (ccoleman@redhat.com)
- Rename config param REGIONS_REQUIRE_FOR_APP_CREATE to
  ZONES_REQUIRE_FOR_APP_CREATE (rpenta@redhat.com)
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4668 from sosiouxme/custom-app-templates-2
  (dmcphers+openshiftbot@redhat.com)
- Bug 1060834 (dmcphers@redhat.com)
- <broker func tests> for custom default templates (lmeyer@redhat.com)
- <broker unit tests> for config readers (lmeyer@redhat.com)
- <broker> enable customizing default app templates (lmeyer@redhat.com)
- Merge pull request #4454 from pravisankar/dev/ravi/card178
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4649 from ncdc/dev/rails-syslog
  (dmcphers+openshiftbot@redhat.com)
- Use flexible array of optional parameters for find_available and underlying
  methods (rpenta@redhat.com)
- Get zones count for the current region from cached districts instead of
  querying Region collection (rpenta@redhat.com)
- Removed REGIONS_ENABLED config param and preferred zones fixes
  (rpenta@redhat.com)
- Allow alphanumeric, underscore, hyphen, dot chars for district/region/zone
  name (rpenta@redhat.com)
- Resolve merge conflicts and fix broken tests (rpenta@redhat.com)
- When region/zones present, allocate gears evenly among the available zones.
  (rpenta@redhat.com)
- Added test for validating min zones per gear group (rpenta@redhat.com)
- Rake tests: use glob to find remaining bunch for functional/functional_ext
  tests (rpenta@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Fix broken tests (rpenta@redhat.com)
- Added test case for set/unset region (rpenta@redhat.com)
- Reorganize broker rake tests (rpenta@redhat.com)
- Reuse loaded districts instead of querying mongo again to find Server object
  (rpenta@redhat.com)
- Add set-region/unset-region options to oo-admin-ctl-distict to allow
  set/unset of region/zone after node addition to district (rpenta@redhat.com)
- Added oo-admin-ctl-region script to manipulate regions/zones
  (rpenta@redhat.com)
- Fix typo (andy.goldstein@gmail.com)
- Add/correct syslog-logger in Gemfiles (andy.goldstein@gmail.com)
- Merge pull request #4602 from jhadvig/mongo_update
  (dmcphers+openshiftbot@redhat.com)
- Adding explanation comments for two broker configurations
  (abhgupta@redhat.com)
- Add syslog support (andy.goldstein@gmail.com)
- Add optional syslog support to Rails apps (andy.goldstein@gmail.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Add mongo write replicas option (dmcphers@redhat.com)
- Bug 1048139 - Adding missing setting to broker.conf (bleanhar@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)
- Fix failing test, add an LRU cache for cart by id (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Support --node correctly on oo-admin-ctl-cartridge (ccoleman@redhat.com)
- Preventing multiple web proxies for an app to live on the same node
  (abhgupta@redhat.com)
- Broker should allow version to be specified in Content-Type as well
  (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Merge pull request #4532 from bparees/jenkins_by_uuid
  (dmcphers+openshiftbot@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- <broker> always prevent alias conflicts with app names (lmeyer@redhat.com)
- <broker> conf to allow alias under cloud domain - bug 1040257
  (lmeyer@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Bug 1056349 (dmcphers@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)
- Add more tests around downloadable cartridges (ccoleman@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)
- Moving test to functional tests and adding request_time to send to plugin
  (abhgupta@redhat.com)
- Separating out node selection algorithm (abhgupta@redhat.com)
- Give better messaging around starting jenkins (dmcphers@redhat.com)
- Mongoid error on app.save results in gear counts being out of sync
  (ccoleman@redhat.com)
- Add default user capability to create HA apps (filirom1@gmail.com)
- allow custom ha prefix and suffix (filirom1@gmail.com)
- Add --quiet, --create, and --logins-file to oo-admin-ctl-user
  (jliggitt@redhat.com)
- rename jee to java_ee_6 (bparees@redhat.com)
- Merge pull request #4355 from smarterclayton/use_local_namespace
  (dmcphers+openshiftbot@redhat.com)
- don't hard code %%{_libdir}, this is breaking ARM (admiller@redhat.com)
- Use denormalized domain_namespace (ccoleman@redhat.com)
- Ensuring consistency for atomically adding/removing
  pending_op_groups/ssh_keys (abhgupta@redhat.com)
- fixed style for terminal class (lnader@redhat.com)
- improve rest api docs generation script (lnader@redhat.com)
- Fix Bugz#960805. Removed comments from JSON. Made cart names more generic.
  (kraman@gmail.com)
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
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)
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
