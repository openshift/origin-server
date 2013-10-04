%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-controller
%global rubyabi 1.9.1

Summary:       Cloud Development Controller
Name:          rubygem-%{gem_name}
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(state_machine)
Requires:      %{?scl:%scl_prefix}rubygem(dnsruby)
Requires:      rubygem(openshift-origin-common)
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
This contains the Cloud Development Controller packaged as a rubygem.

%package doc
Summary: Cloud Development Controller docs

%description doc
Cloud Development Controller ri documentation 

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/
mkdir -p %{buildroot}/etc/openshift/


%files
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/LICENSE 
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/COPYRIGHT
%{gem_instdir}
%{gem_cache}
%{gem_spec}

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Fri Oct 04 2013 Adam Miller <admiller@redhat.com> 1.15.10-1
- Merge pull request #3768 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3739 from smarterclayton/move_new_domain_fields_to_api_13
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1014837 (abhgupta@redhat.com)
- Isolate new domain attributes to API 1.3 and above (ccoleman@redhat.com)

* Thu Oct 03 2013 Adam Miller <admiller@redhat.com> 1.15.9-1
- Merge pull request #3298 from Miciah/bug-993440-restapplication-initialize-
  check-if-cart-is-nil (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3757 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3759 from kraman/test_case_fixes
  (dmcphers+openshiftbot@redhat.com)
- fix cart order calculations (rchopra@redhat.com)
- Add and use find_cartridge_or_raise_exception (miciah.masters@gmail.com)
- Bug 980306 (lnader@redhat.com)
- Remove gear removed checks which were added before just for extra safety.
  (rpenta@redhat.com)
- Have CloudUser create a new CapabilityProxy every time to fix
  application_test.rb#test_scaling_and_storage_events_on_application on F19.
  (kraman@gmail.com)
- Fix PHP cartridge to wait upto 5 sec for Apache to start and create a pid
  file before returning. This is needed because Apache 2.4 on F19 does a
  reverse DNS lookup on the server hostname and causes a race condition in
  runtime-cartridge-php.feature testcase. (kraman@gmail.com)

* Wed Oct 02 2013 Adam Miller <admiller@redhat.com> 1.15.8-1
- Merge pull request #3756 from pravisankar/dev/ravi/rename-node-removed
  (dmcphers+openshiftbot@redhat.com)
- Renamed field 'node_removed' to 'removed' in gear model (rpenta@redhat.com)
- Merge pull request #3742 from pravisankar/dev/ravi/misc-bugfixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3748 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz1012709 - remove gear's ssh keys. add debugging to admin-clear-pending-
  ops (rchopra@redhat.com)
- Bug 1012970 - Fix pending op group: ReplaceAllSshKeysOpGroup.
  (rpenta@redhat.com)

* Tue Oct 01 2013 Adam Miller <admiller@redhat.com> 1.15.7-1
- Merge pull request #3746 from
  jwforres/bug_998396_no_api_response_member_delete
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3744 from detiber/bz1013788
  (dmcphers+openshiftbot@redhat.com)
- Bug 998396 - member remove api doesnt return a message (jforrest@redhat.com)
- Bug 1013788 - Remove first_uid from district model (jdetiber@redhat.com)
- Bug 1013429 (asari.ruby@gmail.com)

* Mon Sep 30 2013 Troy Dawson <tdawson@redhat.com> 1.15.6-1
- oo-admin-repair changes (rpenta@redhat.com)
- Remove skip_node_ops flag from user/domain/app/district models.
  (rpenta@redhat.com)
- Bug 1012297 - Pass gear_id instead of gear_uuid to application remove_gear()
  (rpenta@redhat.com)
- Merge pull request #3732 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz1012901 - observer needs to be called (rchopra@redhat.com)
- Merge pull request #3727 from smarterclayton/fix_environment_variable_routes
  (dmcphers+openshiftbot@redhat.com)
- fix bz1012374 - extra check for expose port for sparse-carts
  (rchopra@redhat.com)
- Update singular routes to use singular_path (ccoleman@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.5-1
- Force resolving domains to avoid double query (jliggitt@redhat.com)
- Membership changes (jliggitt@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3712 from teddythetwig/ssl_to_gear_tests
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Feature tests for ssl_to_gear, V3 of mock cart serves https at primary
  endpoint on port 8123 (teddythetwig@gmail.com)
- Fix for bug 1012138 (abhgupta@redhat.com)

* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge pull request #3691 from BanzaiMan/idle_websockets
  (dmcphers+openshiftbot@redhat.com)
- Add Node.js 0.10 tests to runtime-cartridge-nodejs.feature
  (asari.ruby@gmail.com)
- Merge pull request #3693 from pravisankar/dev/ravi/card98
  (dmcphers+openshiftbot@redhat.com)
- Added skip_node_ops flag to app/domain/user/district models.
  (rpenta@redhat.com)
- typo fix (rchopra@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3696 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- endpoints included for rest call to gear_groups (rchopra@redhat.com)
- <README.auth_plugin.md> Fixed typo (jolamb@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Merge pull request #3686 from rajatchopra/new_master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3682 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- routing spi changes (rchopra@redhat.com)
- Fix for bug 1010632 (abhgupta@redhat.com)
- Fixing AddCompOp code (abhgupta@redhat.com)
- Fixes for pending_op changes (abhgupta@redhat.com)
- Merge pull request #3673 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3667 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- fix indexing (rchopra@redhat.com)
- optimize find all district scenarios (dmcphers@redhat.com)
- Add index to district uuid (dmcphers@redhat.com)
- Fix tests to use ruby193-mcollective only on RHEL. Fix nodejs cart to work on
  F19 and RHEL. (kraman@gmail.com)
- Merge pull request #3666 from jwhonce/wip/secret_token
  (dmcphers+openshiftbot@redhat.com)
- Creating the app secret token and sending to gear creation requests
  (abhgupta@redhat.com)
- Card origin_runtime_102 - Support OPENSHIFT_SECRET_TOKEN (jhonce@redhat.com)
- Merge pull request #3578 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3656 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- First draft of changes to create subclasses for pending ops
  (abhgupta@redhat.com)
- Rescue OOException and include result_io in message (lnader@redhat.com)
- Merge pull request #3654 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3646 from ironcladlou/dev/test-fixes
  (dmcphers+openshiftbot@redhat.com)
- Handle categories not used (dmcphers@redhat.com)
- fix configure order calculation - bz1008609 (rchopra@redhat.com)
- Fix mock cartridge verification in cuke tests (ironcladlou@gmail.com)
- add index for created_at (rchopra@redhat.com)
- add index for created_at field for clear-pending-ops (rchopra@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.8-1
- Merge pull request #3631 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz1003014 - find_cartridge should search for 'Name' as well
  (rchopra@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.7-1
- Merge pull request #3621 from smarterclayton/storage_rest_response_broken
  (dmcphers+openshiftbot@redhat.com)
- Sparse group_instance support broke rest api response for carts
  (ccoleman@redhat.com)

* Wed Sep 11 2013 Adam Miller <admiller@redhat.com> 1.14.6-1
- fix bz1006645 (rchopra@redhat.com)
- Fix for bug 1005007 and bug 1006526 (abhgupta@redhat.com)
- Merge pull request #3582 from kraman/test_case_fixes
  (dmcphers+openshiftbot@redhat.com)
- Fixing code to allow admin to restrict # of domains to be less than # of
  gears allocated to a user. (kraman@gmail.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 1.14.5-1
- Merge pull request #3592 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3589 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1005631 (abhgupta@redhat.com)
- Merge pull request #3583 from jwforres/admin_console_capacity_planning-fork
  (dmcphers+openshiftbot@redhat.com)
- fix enable_ha with respect to max gear limits of web cart + config fixes
  (rchopra@redhat.com)
- <admin libs> remove licenses, minor format (lmeyer@redhat.com)
- <admin suggestions> fix bug 1004671 (lmeyer@redhat.com)
- <admin suggestions> allow 1-node districts (lmeyer@redhat.com)
- <admin suggestions> fix bug 1004297 (lmeyer@redhat.com)
- <admin suggestions> fix bug 1004157 (lmeyer@redhat.com)
- <admin suggestions> library to suggest admin changes (lmeyer@redhat.com)
- <admin stats> refactor and mods for admin console (lmeyer@redhat.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 1.14.4-1
- Use EXTERNAL_ETH_DEV if its set in node.conf. (rmillner@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Merge pull request #3558 from pravisankar/dev/ravi/env-var-fix
  (dmcphers+openshiftbot@redhat.com)
- Remove environment variables support from REST 1.0 api version
  (rpenta@redhat.com)
- Using _id instead of uuid for application (abhgupta@redhat.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Merge pull request #3538 from pmorie/dev/fix_tests
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3548 from jwhonce/wip/oo-devel-node
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3543 from fotioslindiakos/nodejs
  (dmcphers+openshiftbot@redhat.com)
- SCL support for nodejs (fotios@redhat.com)
- Node Platform - Fix cucumber tests (jhonce@redhat.com)
- WIP Node Platform - oo-devel-node: clean up oo-* scripts that emulate mco
  calls (jhonce@redhat.com)
- Fix platform upgrade tests (pmorie@gmail.com)
- enable ha feature (rchopra@redhat.com)
- fixing test cases for phpmyadmin-4 (dmcphers@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Bug 1002685 - Downcase domain names when fetching applications by domain
  (ccoleman@redhat.com)
- cleanup (dmcphers@redhat.com)
- Merge pull request #3399 from smarterclayton/propagate_app_id_to_gears
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- cleanup (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fix env var subscription tests (pmorie@gmail.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Merge pull request #3485 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Make dependency on 0.0.1 version of mock explicit for upgrade tests
  (pmorie@gmail.com)
- cleanup (dmcphers@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Merge pull request #3446 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fix test cases (ccoleman@redhat.com)
- Merge pull request #3477 from
  smarterclayton/protect_environment_vars_with_edit
  (dmcphers+openshiftbot@redhat.com)
- Environment variables should be protected with :edit permission
  (ccoleman@redhat.com)
- Mongoid 3.1 does not return the Array that was stored on the model
  (ccoleman@redhat.com)
- Fix for bug 997008 (abhgupta@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Merge pull request #3452 from pravisankar/dev/ravi/bug998905
  (dmcphers+openshiftbot@redhat.com)
- Added environment variable name limitations  - Limit length to 128 bytes.  -
  Allow letters, digits and underscore but can't begin with digit
  (rpenta@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)
- Changes for doing atomic updates on embedded documents (abhgupta@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.8-1
- Merge pull request #3451 from
  smarterclayton/bug_997567_alias_error_message_vague
  (dmcphers+openshiftbot@redhat.com)
- Bug 997567 - The alias error message is too vague (ccoleman@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.7-1
- Merge pull request #3441 from jwhonce/wip/user_vars
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3326 from kraman/admin_command_connection_hooks
  (dmcphers+openshiftbot@redhat.com)
- origin_broker_77 (lnader@redhat.com)
- Merge pull request #3439 from pravisankar/dev/ravi/user-env-bugs
  (dmcphers+openshiftbot@redhat.com)
- Bug 998794 - Allow blank value for a user environment variable
  (rpenta@redhat.com)
- Node Platform - Add .env/user_vars during upgrade (jhonce@redhat.com)
- Merge pull request #3436 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Fix creating new endpoints during incompatible upgrades (pmorie@gmail.com)
- New admin command to call connection hooks on an application.
  (kraman@gmail.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Merge pull request #3435 from
  smarterclayton/bug_997848_capabilities_not_shown_via_api
  (dmcphers+openshiftbot@redhat.com)
- Bug 997848 - Inherited capabilities not in REST API (ccoleman@redhat.com)
- Fix cucumber step ambiguity (ironcladlou@gmail.com)
- Merge pull request #3398 from detiber/bz994445
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3413 from sosiouxme/admin-stats-fixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3410 from pravisankar/dev/ravi/card86
  (dmcphers+openshiftbot@redhat.com)
- <Admin::Stats> use only strings for hash keys (lmeyer@redhat.com)
- <Admin::Stats> exclude inactive nodes from eff avail gears
  (lmeyer@redhat.com)
- <Admin::Stats> fix minor bug - NONE district should be HashWithReaders
  (lmeyer@redhat.com)
- Added REST api support for user environment variables (rpenta@redhat.com)
- Added User environment variables support in broker (rpenta@redhat.com)
- WIP Node Platform - Add support for settable user variables
  (jhonce@redhat.com)
- Bug 99445 - Better error message for No nodes available (jdetiber@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Fixing typos (dmcphers@redhat.com)
- Bug 997785 (dmcphers@redhat.com)
- Merge pull request #3382 from smarterclayton/builder_scope_incorrect
  (dmcphers+openshiftbot@redhat.com)
- <cartridge versions> origin_runtime_219, fix up cart references for renamed
  cart https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-
  versions (jolamb@redhat.com)
- Node Platform - Fixed grep in node_step.rb (jhonce@redhat.com)
- Fix builder scope by introducing a domain builder scope (ccoleman@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3390 from pmorie/dev/fix_tests
  (dmcphers+openshiftbot@redhat.com)
- Fix several tests that now use incorrect versions (pmorie@gmail.com)
- Merge pull request #3370 from
  smarterclayton/bug_997246_prohibit_blank_domains
  (dmcphers+openshiftbot@redhat.com)
- fix bz997078 (rchopra@redhat.com)
- Merge pull request #3375 from smarterclayton/convert_scope_to_string
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3358 from sosiouxme/oo-stats-mods
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Merge pull request #3368 from smarterclayton/find_by_user_broken_on_app
  (dmcphers+openshiftbot@redhat.com)
- <oo-stats> ability to read results from file; more (lmeyer@redhat.com)
- <Admin::Stats> refactor classes and tests (lmeyer@redhat.com)
- Treat domain_scope= the same as app_scope= (ccoleman@redhat.com)
- Bug 997246 - Prohibit blank domains (ccoleman@redhat.com)
- Unable to scale up or snapshot an app (ccoleman@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Merge pull request #3359 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- migration helpers and rest interface for port information of gears
  (rchopra@redhat.com)
- Upgrade tool enhancements (ironcladlou@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- save exposed port interfaces of a gear (rchopra@redhat.com)
- Merge pull request #3290 from
  smarterclayton/bug_992464_not_raising_on_not_found_token
  (dmcphers+openshiftbot@redhat.com)
- Check denormalization in oo-admin-chk (ccoleman@redhat.com)
- Only schedule domain jobs on applications that actually need it
  (ccoleman@redhat.com)
- Default to test mode membership off (ccoleman@redhat.com)
- Review comments (ccoleman@redhat.com)
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

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Merge pull request #3307 from jwhonce/wip/java_opt_ext
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_148 - append JAVA_OPT_EXT to JAVA_OPT (jhonce@redhat.com)
- Various cleanup (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fix for bug 982855 (abhgupta@redhat.com)
- <mongo> allow db access with mongo client 1.6 (lmeyer@redhat.com)
- Merge pull request #3274 from pmorie/bugs/991225
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3276 from detiber/fixtests
  (dmcphers+openshiftbot@redhat.com)
- Bug 991225: upgrade script should be run before setup during incompatible
  upgrade (pmorie@gmail.com)
- Fix runtime-extended tests for jboss cartridges (jdetiber@redhat.com)
- <admin/stats> should fix oo-stats bug 988554 (lmeyer@redhat.com)
- <admin/stats> add unit tests, fix a bug (lmeyer@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.7-1
- Merge pull request #3250 from jwhonce/wip/extended_tests
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3245 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3247 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- WIP Node Platform - Restored env_var_subscription_steps.rb
  (jhonce@redhat.com)
- Merge pull request #3246 from pmorie/bugs/971120
  (dmcphers+openshiftbot@redhat.com)
- fix bz990341 (rchopra@redhat.com)
- Bug 989856 - fix for embedded carts (lnader@redhat.com)
- Bug 971120: refactor openshift-node.feature (pmorie@gmail.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.6-1
- Merge pull request #3225 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3237 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Bug 988255 (lnader@redhat.com)
- Bug 989856 (lnader@redhat.com)
- Merge pull request #3238 from jwhonce/bug/985514
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3228 from pravisankar/dev/ravi/bug984005
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 989650 (abhgupta@redhat.com)
- Merge pull request #3229 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Set 'register_dns' op to 'rolledback' state in case of DNSLoginException.
  (rpenta@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)
- fix in scope for scaling issues (rchopra@redhat.com)
- Capabilities validator should still be called (ccoleman@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Fix for bug 989650, bug 988115, and added additional check in oo-admin-chk
  (abhgupta@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Bug 982738 (dmcphers@redhat.com)
- Merge pull request #3134 from smarterclayton/changes_for_membership
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3194 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3183 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- redo sparse cart addition/deletion as user can override their scaling factors
  (rchopra@redhat.com)
- Bug 982921 (lnader@redhat.com)
- Merge pull request #3180 from rajatchopra/fix_bz984481
  (dmcphers+openshiftbot@redhat.com)
- Bug 980376 (lnader@redhat.com)
- fix bz984481 (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Typo during merge (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Return creation_time on domains (ccoleman@redhat.com)
- Simplify capabilities to be more model like, and support clean proxying of
  inherited properties (ccoleman@redhat.com)
- Support LIST_DOMAINS_BY_OWNER, SHOW_DOMAIN, and SHOW_APPLICATION_BY_DOMAIN
  (ccoleman@redhat.com)
- Support running broker tests directly Force scopes to use checked ids and
  avoid symbolizing arbitrary strings Use .present? instead of .count > 0 (for
  performance) Handle ValidationExceptions globally (ccoleman@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Ensure that git version is 1.8.* before setting push.default simple
  (kraman@gmail.com)
- Merge pull request #3174 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3141 from detiber/jbaws
  (dmcphers+openshiftbot@redhat.com)
- Bug 982921 (lnader@redhat.com)
- Bug 982107 (lnader@redhat.com)
- Bug 987799 (lnader@redhat.com)
- Merge pull request #3172 from ironcladlou/bz/987836
  (dmcphers+openshiftbot@redhat.com)
- JBoss Deployment verification (jdetiber@redhat.com)
- Bug 987836: Refactor hot deploy marker detection (ironcladlou@gmail.com)
- Merge pull request #3164 from pmorie/bugs/mco_bounce
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3160 from pravisankar/dev/ravi/card78
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3156 from kraman/bugfix3
  (dmcphers+openshiftbot@redhat.com)
- Use service script instead of SIGUSR to reload mcollective (pmorie@gmail.com)
- For consistency, rest api response must display 'delete' instead 'destroy'
  for user/domain/app (rpenta@redhat.com)
- Adding Fedora vs RHEL cases for idler. Ruby 2.0 in F19 runs as ruby-mri vs
  ruby in RHEL (kraman@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- fix bz987773, make max calculation use a floating point (rchopra@redhat.com)
- <application.rb> Add feature to carts to handle wildcard ENV variable
  subscriptions (jolamb@redhat.com)
- Merge pull request #3088 from lnader/card-25
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3147 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 987268 (lnader@redhat.com)
- origin_broker_25 (lnader@redhat.com)
- Merge pull request #3146 from sosiouxme/fake-data
  (dmcphers+openshiftbot@redhat.com)
- fix scaling issue (rchopra@redhat.com)
- Bug 971265 (dmcphers@redhat.com)
- Merge pull request #3137 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- check max limits for non-sparse carts too; fix for bz976734
  (rchopra@redhat.com)
- <admin-console> create script to load fake data (lmeyer@redhat.com)
- Merge pull request #3138 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix issues with move code for multiple haproxy cases (rchopra@redhat.com)
- Check cartridge configure order dependency in the broker (rpenta@redhat.com)
- Allow plugin carts to reside either on web-framework or non web-framework
  carts. HA-proxy cart manifest will say it will reside with web-framework
  (earlier it was done in the reverse order). (rpenta@redhat.com)
- <admin-console> reuse admin stats library (lmeyer@redhat.com)
- <oo-stats> splitting into first admin library class (lmeyer@redhat.com)
- Merge pull request #3125 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- make haproxy a sparse cart (rchopra@redhat.com)
- Merge pull request #3121 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- support for sparse cartridges (multiple haproxy) (rchopra@redhat.com)
- Verified that Mongoid::Errors::DocumentNotFound has not been changed.
  Updating test so that class loads in F19 (kraman@gmail.com)
- Merge pull request #3118 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Add version check for gear upgrade extension (pmorie@gmail.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Merge pull request #3112 from kraman/rhel_fixes
  (dmcphers+openshiftbot@redhat.com)
- Clearing SCL cache environment before invoking scripts since scripts may load
  different scl envs. (kraman@gmail.com)
- Merge pull request #3110 from dobbymoodge/platform_upgrade-refactor
  (dmcphers+openshiftbot@redhat.com)
- <cucumber> Cleaning up commented code blocks (jolamb@redhat.com)
- Remove ecdsa ssh key type from supported list. Rationale: Due to patent
  concerns, ECC support is not bundled in fedora/rhel(needed for ecdsa key
  generation).            So even if someone has a valid ecdsa keys, sshd
  server on our node won't be able to authenticate the user.
  (rpenta@redhat.com)
- <cucumber> Refactoring upgrade_steps.rb to be cart-agnostic
  (jolamb@redhat.com)
- Handle nested subclasses in error responses (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Convert keys_controller - work around double deletion bug in console code
  (ccoleman@redhat.com)
- Merge pull request #3085 from sosiouxme/admin-console-broker
  (dmcphers+openshiftbot@redhat.com)
- Fix failing test in api_responses (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Missed a rescue of Mongoid::Errors::DocumentNotFound (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Remove binding.pry, causing failures (ccoleman@redhat.com)
- Merge pull request #3091 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- <broker> re-base the broker URI from /broker => / (lmeyer@redhat.com)
- Add support for upgrade script to be called during cartridge upgrades.
  (pmorie@gmail.com)
- Merge pull request #3083 from smarterclayton/strong_consistency_is_default
  (dmcphers+openshiftbot@redhat.com)
- Authorization test case was wrong (ccoleman@redhat.com)
- Merge pull request #3074 from kraman/bugfix2
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3069 from sosiouxme/admin-console-mcollective
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3072 from pravisankar/dev/ravi/bug969876
  (dmcphers+openshiftbot@redhat.com)
- Fixes for F19 runtime extended tests * Fix platform-oo-admin.feature to use
  mock instead of ruby and python * Fix cloud domain used in
  application_steps.rb * Add missing haproxy/scaled gear steps * Fix jenkins
  test to understand different api versions    - Old api returns color of build
  - new api returns string (notbuilt, built, etc) (kraman@gmail.com)
- <container proxy> adjust naming for getting facts (lmeyer@redhat.com)
- <mcollective> whitespace + typo fixes (lmeyer@redhat.com)
- Make idler test use mock instead of scenario table (pmorie@gmail.com)
- Merge pull request #3080 from smarterclayton/action_log_should_be_lazy
  (dmcphers+openshiftbot@redhat.com)
- Strong consistency is the default for mongoid (ccoleman@redhat.com)
- Move most DocumentNotFound handling to ApiResponse#render_exception
  (ccoleman@redhat.com)
- Merge pull request #3079 from smarterclayton/make_pry_console_available
  (dmcphers+openshiftbot@redhat.com)
- Generic exceptions should always be handled with rescue_from Don't return on
  the last line of controller methods rescue_from handlers should have proper
  access to user info set via UserActionLog filter (ccoleman@redhat.com)
- Merge pull request #3058 from smarterclayton/use_deep_dup
  (dmcphers+openshiftbot@redhat.com)
- Make set_log_tag lazy, so that all controllers have a default behavior Allow
  controllers to override log tag on their class, not on the instance Make
  allowances for legacy behavior (ccoleman@redhat.com)
- Make Pry console available when ENV['PRY']=1 (ccoleman@redhat.com)
- Remove UtilHelper.deep_copy for Rails deep_dup (ccoleman@redhat.com)
- Bug 969876 - Don't run execute_connections if there are no add/remove
  component ops (rpenta@redhat.com)
- <mcollective> adding call to retrieve set of facts for admin-console
  (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- Merge branch 'master' of github.com:openshift/origin-server
  (admiller@redhat.com)
- bump_minor_versions for sprint 31 (admiller@redhat.com)
- Merge pull request #3070 from detiber/info2warn
  (dmcphers+openshiftbot@redhat.com)
- <controller> - Return client_message as warning instead of info
  (jdetiber@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.8-1
- Merge pull request #3017 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3068 from abhgupta/bug_980760
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 980760  - fixing error message on validation failure  - removing
  downloaded cart manifest entry from app if adding a url based cart fails
  (abhgupta@redhat.com)
- Fix bug 983583: remove gear validation step for compatible upgrades
  (pmorie@gmail.com)
- Bug 980928 (lnader@redhat.com)
- Fix up psql command usage in cucumber tests (asari.ruby@gmail.com)
- Merge pull request #3057 from BanzaiMan/dev/hasari/c157
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3054 from abhgupta/bug_980760
  (dmcphers+openshiftbot@redhat.com)
- Add 9.2 for all remaining cucumber features (asari.ruby@gmail.com)
- Closing mongo db connection to prevent connection pool from getting exhausted
  (abhgupta@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.7-1
- Changing error message to make it more clear (abhgupta@redhat.com)
- Restore "application destroyed" step which was removed in
  5fa8baf6c1781c0e1553d5c424688f461773710a (kraman@gmail.com)
- Merge pull request #3024 from abhgupta/bug_980760
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3028 from rajatchopra/fix_970829
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3022 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 980760  - Preventing multiple versions of a cartridge from being
  added to the application (abhgupta@redhat.com)
- use quarantine to not let the app delete operation in while upgrade is in
  progress (rchopra@redhat.com)
- Bug 979182 - Increase file limit for the gear in proportion to the filesystem
  storage. (rpenta@redhat.com)
- Updates to allow basic tests to pass on F19 (kraman@gmail.com)
- Merge pull request #3018 from abhgupta/bug_982549
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3016 from pmorie/dev/fix_tests
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 982549  - Simplified regex to work with ruby 2.0 in Fedora 19
  (abhgupta@redhat.com)
- Fix upgrade functionality and associated tests (pmorie@gmail.com)

* Tue Jul 09 2013 Adam Miller <admiller@redhat.com> 1.11.6-1
- Merge pull request #3010 from pravisankar/dev/ravi/bug982172
  (dmcphers+openshiftbot@redhat.com)
- Bug 982172 - Do not try to unreserve_uid if we don't get valid container for
  the gear. (rpenta@redhat.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 1.11.5-1
- Fixing runtime tests (dmcphers@redhat.com)
- Increase jenkins start timeout (dmcphers@redhat.com)

* Fri Jul 05 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
- Assign default gear size if not specified in applications_controller.rb
  (rpenta@redhat.com)
- Merge pull request #2987 from rajatchopra/routing_broker
  (dmcphers+openshiftbot@redhat.com)
- fix runtime extended tests (dmcphers@redhat.com)
- Routing plug-in for broker. Code base from github/miciah/broker-plugin-
  routing-activemq (miciah.masters@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Merge pull request #2934 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Fixing class/module namespaces Fixing tests Fixing rebase errors Un-hardcode
  context in step_definitions/cartridge-php_steps.rb Fixing paths that were
  broken when going from File.join -> PathUtils.join (kraman@gmail.com)
- Refactor code to use run_in_container_context/run_in_root_context calls
  instead of generically calling oo_spawn and passing uid. Modify frontend
  httpd/proxy classes to accept a container object instead of indivigual
  properties (kraman@gmail.com)
- Moving Node classes into Runtime namespace Removing UnixUser Moving
  functionality into SELinux plugin class (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Moving scaled deploy into the platform (dmcphers@redhat.com)
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Merge pull request #2925 from BanzaiMan/dev/hasari/c157
  (dmcphers+openshiftbot@redhat.com)
- Add gear-level upgrade extensions (pmorie@gmail.com)
- Merge pull request #2945 from pravisankar/dev/ravi/card7
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2783 from genesarm/PULL_1844
  (dmcphers+openshiftbot@redhat.com)
- Remove Online specific references: -Remove hard-coded cart name references.
  -Remove login validations from CloudUser model, login validation must be done
  by authentication plugin. -Remove 'medium' gear size references -All 'small'
  gear size references must be from configuration files. -Remove stale
  application_observer.rb and its references -Remove stale 'abstract' cart
  references -Remove duplicate code from rest controllers -Move all
  get_rest_{user,domain,app,cart} methods in RestModelHelper module. -Cleanup
  unnecessary TODO/FIXME comments in broker. (rpenta@redhat.com)
- Updated platform-oo-admin.feature testing adding and removing domain wide env
  variables (gsarmien@redhat.com)
- PODO-61 Added tests for adding and removing domain wide environment variables
  (gsarmien@redhat.com)
- Added test for adding domain env variable (gsarmien@redhat.com)
- oo-admin-ctl-usage fixes: Create index on 'gear_id'+'usage_type'+'created_at'
  fields for usage_records mongo collection. (rpenta@redhat.com)
- Card online_runtime_157 (asari.ruby@gmail.com)
- Merge pull request #2927 from smarterclayton/bug_970257_support_git_at_urls
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2967 from pmorie/dev/os_migrations
  (dmcphers+openshiftbot@redhat.com)
- Rename migrate to upgrade in code (pmorie@gmail.com)
- Fix alias validation regex (kraman@gmail.com)
- Remove unused scripts. (mrunalp@gmail.com)
- Bug 977493 - Avoid leaking the lock file descriptor to child processes.
  (rmillner@redhat.com)
- Merge pull request #2827 from genesarm/PULL_2005
  (dmcphers+openshiftbot@redhat.com)
- Move core migration into origin-server (pmorie@gmail.com)
- Merge pull request #2951 from BanzaiMan/mocha_deprecation_warning
  (dmcphers@redhat.com)
- Merge pull request #2952 from pmorie/fix-tests (dmcphers@redhat.com)
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
- Fix mysql scaling tests (pmorie@gmail.com)
- Merge pull request #2865 from BanzaiMan/dev/hasari/bz974632
  (dmcphers+openshiftbot@redhat.com)
- Tests pass fully (add initial_git_url for earlier api versions).  Control
  what values of URI get persisted to DB (passwords and userinfo from clone
  specs should not be) (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Merge pull request #2938 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz977519 - for cases where v2 parsing succeeds but broker manifest
  parsing fails (rchopra@redhat.com)
- PULL_2005 Changed GEAR_SUPL_GRPS to GEAR_SUPPLEMENTARY_GROUPS in node and
  tests (gsarmien@redhat.com)
- PULL_2005 fixed code review bugs for adding supplementary groups to new gears
  (gsarmien@redhat.com)
- PULL_2005 added tests for adding supplementary groups when creating new gears
  in a node (gsarmien@redhat.com)
- Remove V1 code and V2-specific stepdefs (pmorie@gmail.com)
- Merge pull request #2757 from tbielawa/acceptable_values
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Allow clients to pass an initial_git_url of "empty", which creates a bare
  repo but does not add a commit.  When 'empty' is passed, the node will skip
  starting the gear and also skip the initial build.  This allows clients that
  want to send a local Git repository (one that isn't visible to OpenShift.com,
  for example) to avoid having to push/merge/delete the initial commit, and
  instead submit their own clean repo.  In this case, the user will get a
  result indicating that their repository is empty. (ccoleman@redhat.com)
- Merge pull request #2930 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- <App creation error message> Clarify wording in error message
  (tbielawa@redhat.com)
- Reverting fix for bug 973718  - instead of not returning the broken apps, we
  are relying on the CLI/console resilience to handle these broken apps for now
  (abhgupta@redhat.com)
- Bug 970257 - Allow git@ urls (ccoleman@redhat.com)
- removing v1 logic (dmcphers@redhat.com)
- Merge pull request #2923 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 977037 (lnader@redhat.com)
- Resurrect file permissions tests that existed for v1 PHP cartridge
  (asari.ruby@gmail.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 1.10.5-1
- Merge pull request #2908 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- quick fix for 972958 - increase lock timeout (rchopra@redhat.com)
- Merge pull request #2902 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 975586  - Alowing multiple dashes in alias (abhgupta@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Bug 975388 - oo-admin-usage fixes (rpenta@redhat.com)
- Merge pull request #2887 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Fix runtime extended tests (dmcphers@redhat.com)
- fix for bz972514 - handle cases where gear's server id is not set yet
  (rchopra@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Bug 975255 (dmcphers@redhat.com)
- Bug 965804 (lnader@redhat.com)
- Fix runtime extended tests (dmcphers@redhat.com)
- Various cleanup (dmcphers@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Merge pull request #2851 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 974507 (dmcphers@redhat.com)
- Merge pull request #2856 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Bug 974493 (lnader@redhat.com)
- Bug 971204 (lnader@redhat.com)
- <app model> ssh_url should use gear.name for secondary gears
  (lmeyer@redhat.com)
- <app model> fix whitespace (lmeyer@redhat.com)
- Merge pull request #2841 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 973718 (lnader@redhat.com)
- Fix mock test cases for the new routes used by the console
  (jforrest@redhat.com)
- Fix routing clashes when id matches new or edit (jforrest@redhat.com)
- part two of parallelizing node tasks from broker (rchopra@redhat.com)
- Added Usage consistency checks as part of oo-admin-chk script
  (rpenta@redhat.com)
- parallelization of app events across gears (rchopra@redhat.com)
- Bug 971876 (dmcphers@redhat.com)
- Node timeout handling improvements (ironcladlou@gmail.com)
- Fix jboss tests (kraman@gmail.com)
- Build RPM depending on which version of nodejs is available on the platform.
  Make tests pick nodejs version based on what is installed (kraman@gmail.com)
- Fix ruby cartridge. It reuires a ~/.passenger dir on RHEL 6.4 systems Fix
  some cucumber tests tags (kraman@gmail.com)
- Update test for F19 package versions Remove F18 tests Added new tags @not-
  fedora-19, @fedora-19-only to indicate which tests to run Moved cucumber step
  definitons from ruby files back into feature files (kraman@gmail.com)
- origin_runtime_138 - Add SSL_ENDPOINT variable and filter whether carts use
  ssl_to_gear. (rmillner@redhat.com)
- Add ssl_to_gear option. (mrunalp@gmail.com)
- delete downloaded cartridge when component is deleted (rchopra@redhat.com)
- Merge pull request #2666 from lnader/rest-api-version-1.5
  (dmcphers+openshiftbot@redhat.com)
- return HTTP Status code 200 from DELETE instead of 204 (lnader@redhat.com)
- fix for bz970008 (rchopra@redhat.com)
- fix bz969724 - feature name is now just cartridge name (rchopra@redhat.com)
- move v1 tests to extended other only (dmcphers@redhat.com)
- Merge pull request #2697 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 969165 (abhgupta@redhat.com)
- Fix for bug 968952  - Fixing application alias validation regex
  (abhgupta@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)
- Merge pull request #2695 from fotioslindiakos/runtime_extended
  (dmcphers+openshiftbot@redhat.com)
- Fix failing runtime_extended test (fotios@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.10-1
- Merge pull request #2694 from pmorie/dev/v2_switchyard
  (dmcphers+openshiftbot@redhat.com)
- Add V2 tests for switchyard (pmorie@gmail.com)
- Merge pull request #2679 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix search for components given in group overrides (rchopra@redhat.com)
- Merge pull request #2677 from pravisankar/dev/ravi/bug968283
  (dmcphers+openshiftbot@redhat.com)
- Fix track_usage rollback (rpenta@redhat.com)
- Bug 968283 - before_filter check_version must be applied before check_outage
  to ensure @requested_api_version is populated (rpenta@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.9.9-1
- Merge pull request #2664 from abhgupta/bug_967426
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2662 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2654 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2660 from ironcladlou/dev/v2carts/cucumber
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 967426 (abhgupta@redhat.com)
- Fix for bug 966750 (abhgupta@redhat.com)
- fix bz 967779, 967409, 967395 (rchopra@redhat.com)
- Fix client message translation function and add tests (ironcladlou@gmail.com)
- Bug 962657 (dmcphers@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.8-1
- Bug 967518 (dmcphers@redhat.com)
- Bug 966963: Remove unnecessary versioned conf files from php cart
  (ironcladlou@gmail.com)
- Various cleanup (dmcphers@redhat.com)
- Merge pull request #2641 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Replace pre-receive cart control action with pre-repo-archive
  (ironcladlou@gmail.com)
- vendoring of cartridges (rchopra@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- Merge pull request #2614 from
  smarterclayton/add_unique_header_to_cart_download
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2621 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2612 from jwhonce/bug/964347
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 959976 (abhgupta@redhat.com)
- Bug 964347 - Run cartridge scripts from cartridge home directory
  (jhonce@redhat.com)
- Add a unique header X-OpenShift-Cartridge-Download to all cart download
  requests (ccoleman@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- Merge pull request #2611 from pravisankar/dev/ravi/unsubscribe_fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2606 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2596 from fotioslindiakos/Bug960707
  (dmcphers+openshiftbot@redhat.com)
- Bug 966007 - Fix old connections for unsubscribe event (rpenta@redhat.com)
- Merge pull request #2597 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2600 from mrunalp/bugs/966068
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 960757  - Sending init_git_url only for deployable cartridge
  configure/post-configure  - Removing is_primary_cart method in favor of
  is_deployable (abhgupta@redhat.com)
- Add force-reload functionality. (mrunalp@gmail.com)
- Fix test case in extended postgres tests (fotios@redhat.com)
- Bug960707: MySQL snapshot and restore across applications (fotios@redhat.com)
- Bug 964337 (lnader@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- Merge pull request #2595 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Moving code that throws exception into the begin-rescue block
  (abhgupta@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- Merge pull request #2581 from abhgupta/abhgupta-dev-3
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2576 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Ignoring if initial_git_url specified as an empty string
  (abhgupta@redhat.com)
- clean pending ops script to ensure rollbacks when needed; fix downloaded
  manifest screening (rchopra@redhat.com)
- Removing externally_reserved_uids_size attribute from districts
  (abhgupta@redhat.com)
- Merge pull request #2564 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- split cartridge cache per feature (rchopra@redhat.com)
- Merge pull request #2559 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2562 from fotioslindiakos/Bug964116
  (dmcphers+openshiftbot@redhat.com)
- do not save connections in mongo; regenerate them everytime we need to
  execute them (rchopra@redhat.com)
- Fixes to cleanup during app operation failures (abhgupta@redhat.com)
- Bug 964116: Postgres failed to restore snapshot (fotios@redhat.com)
- Merge pull request #2542 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2499 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- safe yaml for parsing of downloaded yaml (rchopra@redhat.com)
- added validation for initial git url (lnader@redhat.com)
- Bug 961475 (lnader@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- Skipping the as7 cukes on OpenShift Enterprise (bleanhar@redhat.com)
- Adjusting test case allocations (dmcphers@redhat.com)
- Merge pull request #2539 from ironcladlou/bz/963646
  (dmcphers+openshiftbot@redhat.com)
- Bug 963981 - Fix app events controller Use canonical_name/canonical_namespace
  for application/domain respectively when using find_by op.
  (rpenta@redhat.com)
- Bug 963646: Quote env var contents to avoid undesirable array evals
  (ironcladlou@gmail.com)
- Merge pull request #2524 from pravisankar/dev/ravi/guard-usage-records
  (dmcphers+openshiftbot@redhat.com)
- no need for semicolon check (rchopra@redhat.com)
- refix 961904 (rchopra@redhat.com)
- Add fault tolerance code to UsageRecord model (rpenta@redhat.com)
- fix for bz963035, bz963607 - use spawn and rate limit for curl
  (rchopra@redhat.com)
- Merge pull request #2520 from jwhonce/wip/rm_post_setup
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - remove post-setup support (jhonce@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Merge pull request #2481 from smarterclayton/add_param_for_downloadable_carts
  (dmcphers@redhat.com)
- Merge pull request #2511 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2494 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 963463 (dmcphers@redhat.com)
- Bug 959123: Unable to restore Postgres snapshot to new application
  (fotios@redhat.com)
- Merge pull request #2503 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2496 from rajatchopra/fix_963080
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2482 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2492 from mrunalp/dev/pybugs
  (dmcphers+openshiftbot@redhat.com)
- process-version -> update-configuration (dmcphers@redhat.com)
- fix 963080 - url is given for downloaded url carts (rchopra@redhat.com)
- fix bz962453 - allow rhc tools to work with url cartridges
  (rchopra@redhat.com)
- Merge pull request #2486 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Specifying applicable actions on controller (abhgupta@redhat.com)
- Merge pull request #2479 from ironcladlou/dev/v2carts/cuke/trap-user
  (dmcphers+openshiftbot@redhat.com)
- Move env var creation to correct install file. (mrunalp@gmail.com)
- Adding upgrade_in_progress at the gear level (dmcphers@redhat.com)
- Review comment (ccoleman@redhat.com)
- Add 'cartridges[][url]' as an optional parameter on ADD_APPLICATION and 'url'
  as an optional parameter on ADD_CARTRIDGE (ccoleman@redhat.com)
- Refactor trap-user tests (ironcladlou@gmail.com)
- Fix platform-scalable-snapshot.feature (pmorie@gmail.com)
- add update in progress mechanism (dmcphers@redhat.com)
- Merge pull request #2466 from fotioslindiakos/rhcsh_test
  (dmcphers+openshiftbot@redhat.com)
- Use rhcsh for ssh commands (fotios@redhat.com)
- WIP cuke reorganization (ironcladlou@gmail.com)
- Fix bug 958977 (pmorie@gmail.com)
- Merge pull request #2444 from detiber/bz961255
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2450 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2451 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2426 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Disabling v1 operations when in v2 mode (dmcphers@redhat.com)
- Added API for cartridge search (lnader@redhat.com)
- minor correction (lnader@redhat.com)
- Make process label checks in cuke tests v1/v2 compatible
  (ironcladlou@gmail.com)
- <controller,broker-util> Bug 961255 - DataStore fixes for mongo ssl
  (jdetiber@redhat.com)
- get runtime extended other working (dmcphers@redhat.com)
- removing extra accept node calls (dmcphers@redhat.com)
- Switching v2 to be the default (dmcphers@redhat.com)
- Merge pull request #2431 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2236 from ncdc/applications-controller-destroy-comment-
  typo (dmcphers+openshiftbot@redhat.com)
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)
- Adding a rewrite to allow X-OpenShift-Host override the HTTP_HOST
  (calfonso@redhat.com)
- Merge pull request #2412 from pravisankar/dev/ravi/bug961220-misc
  (dmcphers+openshiftbot@redhat.com)
- Cleanup: get/set/unset group overrides methods (rpenta@redhat.com)
- fix bz961216 and others related to url based apps (rchopra@redhat.com)
- Merge pull request #2400 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz959221 - embedded cartridge map (rchopra@redhat.com)
- Corrected comment for destroy method (andy.goldstein@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)
- Merge pull request #2341 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bugs 958653, 959676, 959214 and Cleaned up UserException (lnader@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.10-1
- Merge pull request #2385 from pravisankar/dev/ravi/misc-bug958249
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2393 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Fix 'max_storage_per_gear' capability in rest user model. (rpenta@redhat.com)
- Bug 958249 : oo-admin-move will allow different node profile for non-scalable
  apps (rpenta@redhat.com)
- cleanup download url flow for embedded cart (rchopra@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.9-1
- fix bz959826 - fqdn for secondary gears (rchopra@redhat.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.8.8-1
- Merge pull request #2366 from rajatchopra/url_carts_fixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2362 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix the rest models/controllers for applications based on downloadable carts
  (rchopra@redhat.com)
- fix embedded cartridges controller to cleanly understand json input structure
  (rchopra@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- renaming and fix bug#958970 (rchopra@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- fix version mismatch between broker/node for personal carts; some more safety
  for yaml downloads (rchopra@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- nomenclature cleanup and fix for bz958342 (rchopra@redhat.com)
- Merge pull request #2232 from smarterclayton/support_external_cartridges
  (dmcphers+openshiftbot@redhat.com)
- Remove last external reference (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Rename "external cartridge" to "downloaded cartridge".  UI should call them
  "personal" cartridges (ccoleman@redhat.com)
- 'or true' results in external always being enabled (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Add broker config for external cartridges (ccoleman@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Merge pull request #2300 from pravisankar/dev/ravi/card21
  (dmcphers+openshiftbot@redhat.com)
- Broker changes for supporting unsubscribe connection event. Details: When one
  of the component is removed from the app and if it has published some content
  to other components located on different gears, we issue unsubscribe event on
  all the subscribing gears to cleanup the published content.
  (rpenta@redhat.com)
- Merge pull request #2307 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- embedding and versions support for community carts (rchopra@redhat.com)
- Merge pull request #2284 from lnader/551 (dmcphers+openshiftbot@redhat.com)
- fixed broker extended by increasing timeout (lnader@redhat.com)
- Merge pull request #2301 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bug#958320 - no singleton cart's hook for scaled gears
  (rchopra@redhat.com)
- fixed issue with features with dashes (lnader@redhat.com)
- Card 551 (lnader@redhat.com)
- Card online_runtime_266 - Support for JAVA_HOME (jhonce@redhat.com)
- Merge pull request #2287 from brenton/oo-accept-systems2
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2282 from rajatchopra/url_story
  (dmcphers+openshiftbot@redhat.com)
- Adding a cucumber test for oo-accept-systems (bleanhar@redhat.com)
- support for external cartridge through urls (rchopra@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Merge pull request #2280 from mrunalp/dev/auto_env_vars
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2230 from pravisankar/dev/ravi/card559
  (dmcphers+openshiftbot@redhat.com)
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2273 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix for bug#956117 - cartname is required for start/stop and not comp_name
  (rchopra@redhat.com)
- Removed 'setmaxstorage' option for oo-admin-ctl-user script. Added
  'setmaxtrackedstorage' and 'setmaxuntrackedstorage' options for oo-admin-ctl-
  user script. Updated oo-admin-ctl-user man page. Max allowed additional fs
  storage for user will be 'max_untracked_addtl_storage_per_gear' capability +
  'max_tracked_addtl_storage_per_gear' capability. Don't record usage for
  additional fs storage if it is less than
  'max_untracked_addtl_storage_per_gear' limit. Fixed unit tests and models to
  accommodate the above change. (rpenta@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2254 from ironcladlou/dev/v2carts/process-version
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2243 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Add process-version control action (ironcladlou@gmail.com)
- Maintaining configure order among components for post-configure as well
  (abhgupta@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #2231 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- subscriber connection should know who is the publisher (rchopra@redhat.com)
- Bug 956670 - Fix static references to small gear size (jdetiber@redhat.com)
- Card online_runtime_266 - Cucumber test checking for removed file
  (jhonce@redhat.com)
- splitting up runtime_other tests (dmcphers@redhat.com)
- Merge pull request #2220 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2217 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Merge pull request #2212 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1918 from lnader/rest_api_improvments
  (dmcphers+openshiftbot@redhat.com)
- Trim execution time of runtime_other tests (pmorie@gmail.com)
- Bug 955973 (dmcphers@redhat.com)
- Postgres V2 fixes (fotios@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- Merge pull request #2208 from ironcladlou/dev/v2carts/post-configure
  (dmcphers+openshiftbot@redhat.com)
- General REST API clean up - centralizing log tags and getting common objects
  (lnader@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- add connection type to connector calls (dmcphers@redhat.com)
- Merge pull request #2196 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- WIP: test mysql in scalable app (pmorie@gmail.com)
- Merge pull request #2187 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- install and post setup tests (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Update extended tests for raw environment variables
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Card#255 missed env var source in app_helper.rb
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- app_dns should belong to only one group instance (rchopra@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Merge pull request #2155 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2152 from pravisankar/dev/ravi/plan_history_cleanup
  (dmcphers+openshiftbot@redhat.com)
- eventual consistency is alright in some cases (rchopra@redhat.com)
- Merge pull request #2149 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Added pre_sync_usage, post_sync_usage operations in oo-admin-ctl-usage script
  (rpenta@redhat.com)
- Merge pull request #2146 from abhgupta/bug_953493
  (dmcphers+openshiftbot@redhat.com)
- disallow creation of scalable apps with framework carts that do not scale
  (rchopra@redhat.com)
- Merge pull request #2142 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 953493  - Providing better error message when creating a scalable
  application with a framework cartridge that cannot be scaled  - Validating
  against adding more than one framework cartridge to an application
  (abhgupta@redhat.com)
- refix unreserve_uid when destroying gear (rchopra@redhat.com)
- Merge pull request #2120 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- unreserve should not happen twice over (rchopra@redhat.com)
- Fix for bug 953035 Including the links for aliases embedded in application
  response if nolinks was not specified (abhgupta@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Merge pull request #2099 from brenton/controller1
  (dmcphers+openshiftbot@redhat.com)
- controller dependency fixes (bleanhar@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.8-1
- Merge pull request #2083 from pmorie/bugs/927850
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - V2 support for reading .uservars (jhonce@redhat.com)
- <controller/test/cucumber> Bug 949251 - fix jboss* snapshot/restore tests
  (jolamb@redhat.com)
- <runtime_steps.rb> Bug 949251 - Add file check to V1 snapshot/restore test
  (jolamb@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.7-1
- WIP: scalable snapshot/restore (pmorie@gmail.com)
- Merge pull request #2040 from pmorie/dev/mock_cuke (dmcphers@redhat.com)
- Rename and break out platform features into discrete tests (pmorie@gmail.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.6-1
- Fix cart-scoped action hook executions (ironcladlou@gmail.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- phpmyadmin tests (dmcphers@redhat.com)
- Merge pull request #2015 from ironcladlou/dev/v2carts/build-system
  (dmcphers@redhat.com)
- Merge pull request #2016 from pmorie/dev/platform_ssh (dmcphers@redhat.com)
- Merge pull request #1996 from
  smarterclayton/bug_950367_use_default_for_bad_expires_in
  (dmcphers+openshiftbot@redhat.com)
- Generate ssh key for web proxy cartridges (pmorie@gmail.com)
- Call cart pre-receive hook during default build lifecycle
  (ironcladlou@gmail.com)
- Bug 950367 - Handle non-integer values for expires_in (ccoleman@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- Merge pull request #2009 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- Merge pull request #2001 from brenton/misc2 (dmcphers@redhat.com)
- Merge pull request #1998 from pravisankar/dev/ravi/card526
  (dmcphers@redhat.com)
- Merge pull request #1997 from
  smarterclayton/bug_928668_better_messages_for_storage_limits
  (dmcphers+openshiftbot@redhat.com)
- Specifying an invalid embedded cartridge during app creation was throwing
  internal server error (abhgupta@redhat.com)
- Merge pull request #1752 from BanzaiMan/ruby_v2_work (dmcphers@redhat.com)
- Labeling a few cucumber tests as @not-enterprise (bleanhar@redhat.com)
- Ruby v2 cartridge work (asari.ruby@gmail.com)
- Bug 928668 - Provide better gear storage messages (ccoleman@redhat.com)
- Add 'plan_history' to CloudUser model. oo-admin-ctl-usage will also cache
  'plan_history' and will pass to sync_usage(). (rpenta@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1980 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1979 from pmorie/dev/snapshot_cuke
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1959 from pravisankar/dev/ravi/card-537
  (dmcphers+openshiftbot@redhat.com)
- Returning the correct http status in case of unhandled exception
  (abhgupta@redhat.com)
- Add core platform test for v2 snapshot/restore (pmorie@gmail.com)
- Merge pull request #1968 from pmorie/dev/v2_mysql (dmcphers@redhat.com)
- Gear Move changes: Keep same uid for the gear When changing the gear from one
  district to another. (rpenta@redhat.com)
- Merge pull request #1965 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1953 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Add mysql v2 snapshot/restore tests (pmorie@gmail.com)
- fix system_ssh_key remove case (rchopra@redhat.com)
- Adding checks for ssh key matches (abhgupta@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #1954 from lnader/gear-ssh-url
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1957 from lnader/536 (dmcphers+openshiftbot@redhat.com)
- Card 536 - Clean up in domain space (lnader@redhat.com)
- delete all calls to remove_ssh_key, and remove_domain_env_vars
  (rchopra@redhat.com)
- Merge pull request #1934 from lnader/card-534 (dmcphers@redhat.com)
- Add ssh_url to gear_groups for each gear (lnader@redhat.com)
- Merge pull request #1921 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)
- Card 534 (lnader@redhat.com)
- auto-cleanup of ssh-keys/env vars on cart remove (rchopra@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- 10gen-mms-agent WIP (dmcphers@redhat.com)
- Remove redundant steps from nodejs feature (ironcladlou@gmail.com)
- nodejs cucumber features modelled after ruby v2 features
  (asari.ruby@gmail.com)
- Part 2 of Card 536 (lnader@redhat.com)
- Part 1 of Card 536 (lnader@redhat.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Consolidating ssh key name manipulation in one place (abhgupta@redhat.com)
- too much had been added to runtime_other (dmcphers@redhat.com)
- Merge pull request #1883 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1880 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Mongodb Cartridge V2 (calfonso@redhat.com)
- Bug 947288 (lnader@redhat.com)
- Merge pull request #1867 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- Randomizing UIDs in available_uids list for district (abhgupta@redhat.com)
- corrected broker extended test (lnader@redhat.com)
- Merge pull request #1859 from ironcladlou/dev/v2carts/state-management
  (dmcphers+openshiftbot@redhat.com)
- V2 cart state management implementation (ironcladlou@gmail.com)
- Corrected test to reflect changes in API (lnader@redhat.com)
- Card 515 - Improve test coverage (lnader@redhat.com)
- scale-down should ignore haproxy gear (rchopra@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- Improve mock/mock-plugin cartridges (ironcladlou@gmail.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.8-1
- Fixing retry logic of rest-domains.feature tests to not run F18-only tests on
  RHEL and vice-versa https://bugzilla.redhat.com/show_bug.cgi?id=928382
  (kraman@gmail.com)
- Merge pull request #1815 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1821 from jwhonce/wip/threaddump
  (dmcphers+openshiftbot@redhat.com)
- Corrected the incorrect fix put in for bug 915673 (lnader@redhat.com)
- WIP Cartridge Refactor - Roll out old threaddump support (jhonce@redhat.com)
- Merge pull request #1817 from jwhonce/wip/threaddump (dmcphers@redhat.com)
- Merge pull request #1816 from rmillner/fix_runtime (dmcphers@redhat.com)
- Merge pull request #1809 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Read values from node.conf for origin testing. (rmillner@redhat.com)
- Merge pull request #1808 from lnader/master (dmcphers@redhat.com)
- Merge pull request #1811 from kraman/gen_docs (dmcphers@redhat.com)
- WIP Cartridge Refactor - Add PHP support for threaddump (jhonce@redhat.com)
- don't catch Mongoid::Errors::DocumentNotFound (lnader@redhat.com)
- Bug 915673 (lnader@redhat.com)
- Update docs generation and add node/cartridge guides [WIP]
  https://trello.com/c/yUMBZ0P9 (kraman@gmail.com)
- Bug 927614: Fix action hook execution during v2 control ops
  (ironcladlou@gmail.com)
- fixing test cases (dmcphers@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- Fix for bug 920016   Handling exception thrown by get_bool util method
  (abhgupta@redhat.com)
- Fix for bug 924479   Handling the case when component_properties is an empty
  array instead of a Hash   This can happen if the mongo document is copied and
  pasted back and saved using a UI tool (abhgupta@redhat.com)
- Fixing validations for updating scaling parameters for cartridges
  (abhgupta@redhat.com)
- Fix for bug 927154 Fixing multiple issues in remove-gear command of admin
  script (abhgupta@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1762 from fabianofranz/dev/ffranz/ssl
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1775 from mmcgrath-openshift/ruby-combined
  (dmcphers@redhat.com)
- Merge pull request #1773 from rajatchopra/bz919379
  (dmcphers+openshiftbot@redhat.com)
- corrected some 1.8/1.9 issues, cucumber tests now work (mmcgrath@redhat.com)
- do not delete app unless its really empty (rchopra@redhat.com)
- fixed for vendor-ruby bits (mmcgrath@redhat.com)
- removing steps (mmcgrath@redhat.com)
- correcting to work with both versions of ruby (mmcgrath@redhat.com)
- Changing regex (mmcgrath@redhat.com)
- Card #239: Added support to alias creation and deletion and SSL certificate
  upload to the web console (ffranz@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- The larger tests do not conflict with Online and needed to be available to
  runtime-extended. (rmillner@redhat.com)
- Fix for bug 924479 (abhgupta@redhat.com)
- Using relationships for on_domains and completed_domains
  (abhgupta@redhat.com)
- Fixing mongo query to pass correct parameters (abhgupta@redhat.com)
- Storing the pending_op id to retrieve it after a reload (abhgupta@redhat.com)
- Merge pull request #1746 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1749 from ironcladlou/dev/v2carts/build-system
  (dmcphers@redhat.com)
- Reimplement the v2 build process (ironcladlou@gmail.com)
- dont crash user_op on missing domains (rchopra@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Merge pull request #1743 from jwhonce/wip/cartridge_ident
  (dmcphers+openshiftbot@redhat.com)
- Additional fixes to read from the primary (abhgupta@redhat.com)
- Fixing force deletion of domain to correctly read apps from primary
  (abhgupta@redhat.com)
- WIP Cartridge Refactor - Add new environment variables (jhonce@redhat.com)
- Merge pull request #1727 from kraman/embeeded_feature_fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1714 from pmorie/dev/v2_mysql (admiller@redhat.com)
- Fix embedded.feature runtime extended test (kraman@gmail.com)
- Jenkins client WIP (dmcphers@redhat.com)
- Cart V2 build implementation WIP (ironcladlou@gmail.com)
- Merge pull request #1717 from jwhonce/wip/setup_version
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1702 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor -- restore --version to setup calls
  (jhonce@redhat.com)
- WIP: v2 mysql (pmorie@gmail.com)
- US436: Add plan_state field to cloud_user mongoid model (rpenta@redhat.com)
- Merge pull request #1696 from pravisankar/dev/ravi/us506
  (dmcphers+openshiftbot@redhat.com)
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)
- US506 : Broker rails flag to enable/disable broker in maintenance mode
  (rpenta@redhat.com)
- Merge pull request #1692 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1695 from jwhonce/wip/coverage
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1685 from abhgupta/bug921301
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Work on tests and coverage (jhonce@redhat.com)
- Merge pull request #1683 from jwhonce/wip/mock_updated (dmcphers@redhat.com)
- Fix for bug 921301 Reading the domain from the primary (abhgupta@redhat.com)
- analytics data export/import (rchopra@redhat.com)
- WIP Cartridge Refactor - cucumber test refactor (jhonce@redhat.com)
- V2 cucumber test refactor (ironcladlou@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Adding permission related support for cartridge-php tests (kraman@gmail.com)
- Disable cartridge-php.feature on Fedora due to hard coded assumptions about
  RHEL paths (kraman@gmail.com)
- Removing hack for separating id from format in keys controller
  (abhgupta@redhat.com)
- Adding back the get_mcs_level function for the php cartridge tests
  (kraman@gmail.com)
- Merge pull request #1633 from lnader/revert_pull_request_1486
  (dmcphers+openshiftbot@redhat.com)
- Fixing fedora tests for php and mongodb (kraman@gmail.com)
- Merge pull request #1663 from smarterclayton/cache_enable_origin
  (dmcphers+openshiftbot@redhat.com)
- Bug 920801 (lnader@redhat.com)
- Fixed merge conflict (lnader@redhat.com)
- Changed private_certificate to private_ssl_certificate (lnader@redhat.com)
- Add SNI upload support to API (lnader@redhat.com)
- save analytics in application (rchopra@redhat.com)
- Support cache config (ccoleman@redhat.com)
- Merge pull request #1653 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Fix typo in runtime cuke test stepdefs (ironcladlou@gmail.com)
- Disable check for quota over ssh on Fedora (kraman@gmail.com)
- Fix for bug 918966 Removing constraints from routes and adding regex checks
  in controllers (abhgupta@redhat.com)
- Merge pull request #1651 from rmillner/build_failures
  (dmcphers+openshiftbot@redhat.com)
- DIY Cartridge 2.0 (chris@@hoflabs.com)
- RHEL and Fedora have different versions of the cartridge.
  (rmillner@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Merge pull request #1644 from ironcladlou/dev/v2carts/endpoint-refactor
  (dmcphers@redhat.com)
- Merge pull request #1643 from kraman/update_parseconfig (dmcphers@redhat.com)
- Merge pull request #1641 from rmillner/test_case_fixes (dmcphers@redhat.com)
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- Replacing get_value() with config['param'] style calls for new version of
  parseconfig gem. (kraman@gmail.com)
- The add_alias and remove_alias functions now raise on error instead of
  returning like a shell call. (rmillner@redhat.com)
- Modify cucumber test cases so that the retry login in origin-dev-tools does
  not run Fedora tests on RHEL. The core of the issue is that cucumber ignores
  tags when line number is specified. (kraman@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- adding runtime_other tests (dmcphers@redhat.com)
- Merge pull request #1607 from brenton/oo-admin-broker-auth
  (dmcphers+openshiftbot@redhat.com)
- remove old obsoletes (tdawson@redhat.com)
- Merge pull request #1619 from pmorie/dev/oo_cartridge
  (dmcphers+openshiftbot@redhat.com)
- Fixes and tests for oo-cartridge (pmorie@gmail.com)
- Merge pull request #1552 from mmcgrath-openshift/cartridge_prep
  (dmcphers+openshiftbot@redhat.com)
- fix for bug 920045 - connector args should have gear uuid
  (rchopra@redhat.com)
- Adding oo-admin-broker-auth (bleanhar@redhat.com)
- Adding the ability to fetch all gears with broker auth tokens
  (bleanhar@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #1586 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1593 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- Merge pull request #1582 from markllama/docs/dns_plugins
  (dmcphers+openshiftbot@redhat.com)
- Missed the ssh keyname handling in the show method (abhgupta@redhat.com)
- Speed up haproxy interaction (dmcphers@redhat.com)
- Merge branch 'openshift-master' into cartridge_prep (mmcgrath@redhat.com)
- Fix for bug 911994   Making sure that the correct user login is recorded in
  logs and response messages (abhgupta@redhat.com)
- Add yard documentation markup to DNS plugins (mlamouri@redhat.com)
- Merge branch 'openshift-master' into cartridge_prep (mmcgrath@redhat.com)
- Added new cartridges (mmcgrath@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.14-1
- Merge pull request #1566 from lnader/master (dmcphers@redhat.com)
- be sure you dont cache an empty list (dmcphers@redhat.com)
- Bug 918501 (lnader@redhat.com)
- Merge pull request #1559 from pravisankar/dev/ravi/usage-fixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1562 from kraman/default_gear_sizes_2
  (dmcphers@redhat.com)
- Fixed a regression where DEFAULT_GEAR_CAPABILITIES was not being used to
  populate cloud user default capabilities. (kraman@gmail.com)
- Bug 911322 (lnader@redhat.com)
- Sync usage fixes (rpenta@redhat.com)
- Merge pull request #1555 from danmcp/master (dmcphers@redhat.com)
- Bug 917973 Addind a retry and better messaging when you dont get a response
  from the find one (dmcphers@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.13-1
- Adding input redirect for ssh-keygen so it does not prompt for a question and
  wait indefinitely (kraman@gmail.com)
- Merge pull request #1488 from kraman/fix_parallel_test_run
  (dmcphers+openshiftbot@redhat.com)
- Update setup helper to create test ssh key in exclusive lock. Othrwise was
  facing race condition where multiple test runs were completing to create the
  key files. (kraman@gmail.com)
- Skip Usage capture for sub-account users (rpenta@redhat.com)
- Merge pull request #1512 from rajatchopra/master (dmcphers@redhat.com)
- force stop - fix bug#915587 (rchopra@redhat.com)
- Bug 916559 - Existing broker keys broken after stage upgrade
  (ccoleman@redhat.com)

* Mon Mar 04 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- Bug 916941 - Keep created time in sync when creating UsageRecord and Usage
  mongo record (rpenta@redhat.com)
- Merge pull request #1519 from abhgupta/abhgupta-ssh-keys
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1518 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1516 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Fix for issue identified by lnader where force_delete fails for a user with
  domains (abhgupta@redhat.com)
- adding coverage (dmcphers@redhat.com)
- Fix for bug 915638   We are not logging the user credentials in the log file
  (abhgupta@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- Add test for v2 tidy (pmorie@gmail.com)
- Add simple v2 app builds (pmorie@gmail.com)
- Updated feature test. (mrunalp@gmail.com)
- Updated tests. (mrunalp@gmail.com)
- Remove parsing version from cartridge-name (pmorie@gmail.com)
- Merge pull request #1500 from rajatchopra/master (dmcphers@redhat.com)
- Merge pull request #1495 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- scale down should not get affected with consumed_gears/actual_gears mismatch
  (rchopra@redhat.com)
- gear name is the whole uuid now (rchopra@redhat.com)
- Reloading the domain from primary to make sure pending_ops is loaded
  (abhgupta@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Merge pull request #1441 from pravisankar/dev/ravi/us3409
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1487 from bdecoste/master (dmcphers@redhat.com)
- Merge pull request #1486 from lnader/revert_pull_request_1
  (dmcphers@redhat.com)
- fix jenkins test to allow 302 redirect (bdecoste@gmail.com)
- Merge pull request #1481 from abhgupta/abhgupta-ssh-keys
  (dmcphers+openshiftbot@redhat.com)
- reverted US2448 (lnader@redhat.com)
- Merge pull request #1480 from
  smarterclayton/bug_916311_expired_tokens_should_be_hidden
  (dmcphers+openshiftbot@redhat.com)
- Added index on 'login' for usage_record and usage mongoid models Added
  separate usage audit log, /var/log/openshift/broker/usage.log instead of
  syslog. Moved user action log from /var/log/openshift/user_action.log to
  /var/log/openshift/broker/user_action.log Added Distributed lock used in oo-
  admin-ctl-usage script Added Billing Service interface Added oo-admin-ctl-
  usage script to list and sync usage records to billing vendor Added oo-admin-
  ctl-usage to broker-util spec file Fixed distributed lock test Add billing
  service to origin-controller Some more bug fixes (rpenta@redhat.com)
- Fix for bug 916323 -  making sure that we delete all applications and re-
  verify  before force-deleting a domain (abhgupta@redhat.com)
- Merge pull request #1474 from bdecoste/master (dmcphers@redhat.com)
- Merge pull request #1473 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1478 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- Bug 916311 - Expired tokens should be hidden (ccoleman@redhat.com)
- Use update rather than find_and_modify (dmcphers@redhat.com)
- Fix for bug 916268 - adding properties for embedded carts in application rest
  response Note: this was opened as a regression for bug 812046
  (abhgupta@redhat.com)
- Bug 913217 (bdecoste@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Merge pull request #1477 from ironcladlou/dev/cartridge_refactor
  (dmcphers@redhat.com)
- WIP Cartridge Refactor (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Merge pull request #1475 from abhgupta/abhgupta-ssh-keys
  (dmcphers+openshiftbot@redhat.com)
- Added certificate_added_at to alias (lnader@redhat.com)
- Added validation for SSL certificate and private key (lnader@redhat.com)
- Added unit tests for alias and domain (lnader@redhat.com)
- US2448 (lnader@redhat.com)
- fix comment (dmcphers@redhat.com)
- send domain creates and updates to nuture (dmcphers@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- Should be using uuid for gear name (dmcphers@redhat.com)
- Merge pull request #1453 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- fix for bug 915571 - blocking haproxy from being added to app
  (abhgupta@redhat.com)
- Merge pull request #1445 from kraman/gen_docs
  (dmcphers+openshiftbot@redhat.com)
- avoiding unnecessary mongo queries and fixing routes constraints
  (abhgupta@redhat.com)
- Documentation (kraman@gmail.com)
- Bug 914639 (dmcphers@redhat.com)
- Merge pull request #1451 from pmorie/bugs/915502
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 915502 (pmorie@gmail.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- Implement authorization support in the broker (ccoleman@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.6-2
- bump Release for fixed build target rebuild (admiller@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- avoiding unnecessary mongoid calls (abhgupta@redhat.com)
- Merge pull request #1438 from
  smarterclayton/bug_912286_cleanup_robots_misc_for_split
  (dmcphers+openshiftbot@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- handling pending_ops correctly in run_jobs in case of multiple processes
  running simultaneously (abhgupta@redhat.com)
- Bug 912286 - Allow quickstart link to be server relative
  (ccoleman@redhat.com)
- Merge pull request #1428 from pravisankar/dev/ravi/bug912208
  (dmcphers+openshiftbot@redhat.com)
- Bug 912208 - Fix app creation for medium gears (rpenta@redhat.com)
- Merge pull request #1426 from fotioslindiakos/find_application
  (dmcphers+openshiftbot@redhat.com)
- Fixed rhc_ctl_destroy helper to look for correct exit code and run faster
  (fotios@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Tests for node web proxy. (mrunalp@gmail.com)
- Relaxing restrictions on ssh key names (abhgupta@redhat.com)
- Merge pull request #1409 from tdawson/tdawson/fix_rubygem_sources
  (dmcphers+openshiftbot@redhat.com)
- Bug 912798 (dmcphers@redhat.com)
- fix rubygem sources (tdawson@redhat.com)
- Bug 912292 (dmcphers@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 912601 (dmcphers@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Bug 910616 Order web frameworks before other carts (dmcphers@redhat.com)
- stop passing extra app object (dmcphers@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- broker unit testcases (rchopra@redhat.com)
- Fixes to get builds and tests running on RHEL: (kraman@gmail.com)
- Fixes for ruby193 (john@ibiblio.org)
- Adding more indexes based on prod performance (dmcphers@redhat.com)
- Add index on domain_id (dmcphers@redhat.com)
- Add request id to mco requests (dmcphers@redhat.com)
- Performance fixes around retrieving apps and domains (dmcphers@redhat.com)
- use correct sort syntax (dmcphers@redhat.com)
- correction in node selection algorithm (dmcphers@redhat.com)
- Merge pull request #1368 from smarterclayton/bug_908546_restrict_cart_types
  (dmcphers+openshiftbot@redhat.com)
- Properly deserialize nested cartridges when a relation exists and no method
  setter (ccoleman@redhat.com)
- remove community pod (dmcphers@redhat.com)
- Merge pull request #1366 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- providing stub for usage_rates and changing rest response field to
  usage_rates from usage_rate_usd (abhgupta@redhat.com)
- Refactor agent and proxy, move all v1 code to v1 model
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- making usage filter a generic hash (abhgupta@redhat.com)
- added new admin script to list usage for a user (abhgupta@redhat.com)
- Fix broken idler test (kraman@gmail.com)
- Updating idler tests to ignore warnings from facter (kraman@gmail.com)
- Fix current ip address during app creation (rpenta@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Merge pull request #1346 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1289 from
  smarterclayton/isolate_api_behavior_from_base_controller
  (dmcphers+openshiftbot@redhat.com)
- use a sparse index on gear uuid (dmcphers@redhat.com)
- Merge pull request #1288 from smarterclayton/improve_action_logging
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1339 from tdawson/tdawson/cleanup-spec-headers
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1344 from kraman/f18_fixes (dmcphers@redhat.com)
- Disable trap user quota access check for F18, since fedora selinux policy is
  blocking it at the moment (kraman@gmail.com)
- Cut and paste error (ccoleman@redhat.com)
- Merge branch 'improve_action_logging' into
  isolate_api_behavior_from_base_controller (ccoleman@redhat.com)
- deep copy the group overrides so that a software cache of cartridges does not
  suffer changes (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' into improve_action_logging
  (ccoleman@redhat.com)
- change %%define to %%global (tdawson@redhat.com)
- Bug 908825 Create gear uuid index in the right place (dmcphers@redhat.com)
- Remove legacy login() method on authservice (ccoleman@redhat.com)
- All controllers should inherit the standard filters, except where they are
  bypassed (ccoleman@redhat.com)
- Move authentication logic to a new controller mixin (ccoleman@redhat.com)
- Ensure lib directory is in the autoload path, do not require rubygems when
  developing from source (ccoleman@redhat.com)
- Move the API document handler to its own controller (ccoleman@redhat.com)
- Do not use a global variable to initialize a RestReply - use a controller
  helper method. (ccoleman@redhat.com)
- Remove global references to $requested_api_version (ccoleman@redhat.com)
- Separate API behavior into its own model Make the base url mechanism relative
  to the Rails root (ccoleman@redhat.com)
- Extract API response behavior to a controller mixin (ccoleman@redhat.com)
- Remove gen_req_uuid and get_cloud_user_info, no longer used
  (ccoleman@redhat.com)
- Move ActionLog to a controller mixin, make core user_action_log independent
  of controller so it can be used in models Make user logging stateful to the
  thread Remove unnecessary duplicate log statement in domains controller
  Remove @request_id (ccoleman@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- Setting namespace and canonical_namespace for the domain together and doing
  the same for the application (abhgupta@redhat.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.7-1
- Merge pull request #1332 from abhgupta/abhgupta-ssh-keys
  (dmcphers@redhat.com)
- Merge pull request #1324 from tdawson/tdawson/remove_rhel5_spec_stuff
  (dmcphers+openshiftbot@redhat.com)
- Fix for issue where system ssh keys were being left behind in the domain
  object (abhgupta@redhat.com)
- Fix for bug 908199 - we are logging only the basic info in user_action.log
  (abhgupta@redhat.com)
- remove BuildRoot: (tdawson@redhat.com)
- Fix for bug 806395 - added list of alias as valid options in remove alias
  link for application in rest response (abhgupta@redhat.com)
- Merge pull request #1318 from tdawson/tdawson/openshift-common-sources
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1317 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)
- Fix for bug 907764 - fixing configure/start/stop order for components
  (abhgupta@redhat.com)
- fix BZ907788 - gear size gets stored in group overrides now
  (rchopra@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- Fix for bug 907683 - Reloading from primary (abhgupta@redhat.com)
- Merge pull request #1303 from pravisankar/dev/ravi/app-lock-timeout
  (dmcphers+openshiftbot@redhat.com)
- fix issue with reserve given not taking the valid uid (dmcphers@redhat.com)
- - Added Application Lock Timeout (default: 10 mins) - Unit tests for Lock
  model (rpenta@redhat.com)
- Setting quota on new gear only if additional storage is specified
  (abhgupta@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Merge pull request #1292 from pravisankar/dev/ravi/bug907373
  (dmcphers+openshiftbot@redhat.com)
- Bug 907373 - Minor fix in oo-admin-chk (rpenta@redhat.com)
- Bug 906759 - Add usage_rate_usd field to RestEmbeddedCartridge model
  (rpenta@redhat.com)
- Merge pull request #1287 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1284 from pravisankar/dev/ravi/bug906717
  (dmcphers+openshiftbot@redhat.com)
- Reloading the application and fetching the pending_op_groups from it instead
  of reloading the embedded object (abhgupta@redhat.com)
- Merge pull request #1279 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- adjust to 1.8.1 driver (dmcphers@redhat.com)
- missed a file (dmcphers@redhat.com)
- Bug 906717 - Fix additional storage for scaled gear (rpenta@redhat.com)
- Fix for bug 906266 and bug 904913 (abhgupta@redhat.com)
- Better naming (dmcphers@redhat.com)
- Merge pull request #1276 from danmcp/master (dmcphers@redhat.com)
- share db connection logic (dmcphers@redhat.com)
- fix bz894976 - dont run connections on old container (rchopra@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Merge pull request #1269 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- US2626 changes based on feedback - Add application name in Usage and
  UsageRecord models - Change 'price' to 'usage_rate_usd' in rest cartridge
  model - Change 'charges' to 'usage_rates' in rails configuration - Rails
  configuration stores usage_rates for different currencies (currently only
  have usd) (rpenta@redhat.com)
- Merge pull request #1270 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1260 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 906603 Handle race condition creating user with concurrent calls
  (dmcphers@redhat.com)
- fix instability of ci tests (rchopra@redhat.com)
- Merge pull request #1252 from
  smarterclayton/us3350_establish_plan_upgrade_capability
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 906266, bug 906230, and bug 906233 (abhgupta@redhat.com)
- Review - use 'caps' instead of 'cap' for shortname (ccoleman@redhat.com)
- US3350 - Expose a plan_upgrade_enabled capability that indicates whether
  users can select a plan (ccoleman@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- cleanup (dmcphers@redhat.com)
- Removing unnecessary cucumber scenarios (mhicks@redhat.com)
- Merge pull request #1250 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix for bz903963 - conditionally reload haproxy after update namespace
  (rchopra@redhat.com)
- Collect/Sync Usage data for EAP cart (rpenta@redhat.com)
- Fix for broker extended tests (abhgupta@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- fix read before initialize issue (rchopra@redhat.com)
- Merge pull request #1234 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1230 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1232 from pravisankar/dev/ravi/fix-broker-extended-tests
  (dmcphers+openshiftbot@redhat.com)
- Bug 874594 Bug 888550 (dmcphers@redhat.com)
- refix oo-admin-chk - remove pagination; minor fix with group override
  matching (rchopra@redhat.com)
- cartridge name validation fix BZ869196 (rchopra@redhat.com)
- Fix Broker extended tests, Don't call observers for cloud user model if the
  record is already persisted. (rpenta@redhat.com)
- remove consumed_gear_sizes (dmcphers@redhat.com)
- removing legacy broker rest api (abhgupta@redhat.com)
- Bug 894230 Use strong consistency properly and when creating an app
  (dmcphers@redhat.com)
- Bug 902672 (dmcphers@redhat.com)
- Bug 902286 (dmcphers@redhat.com)
- Bug 876087 (dmcphers@redhat.com)
- Bug 903551 (dmcphers@redhat.com)
- Bug 870377 Give proper error for cart missing vs app (dmcphers@redhat.com)
- Bug 884456 (dmcphers@redhat.com)
- Merge pull request #1217 from pravisankar/dev/ravi/fix-quota
  (dmcphers+openshiftbot@redhat.com)
- Fix Quota, additional storage validations (rpenta@redhat.com)
- Fix for bug 895441 - tightening our validations for cartridge scale factors
  (abhgupta@redhat.com)
- maintaining backward compatibility for rest application output
  (abhgupta@redhat.com)
- helper to rhc-fix-uid (rchopra@redhat.com)
- fixing cucumber test that was incorrectly merged (abhgupta@redhat.com)
- fixing rest api error message for scale factor validations
  (abhgupta@redhat.com)
- fixing issue where jenkins ssh key was not always being added with domain-
  jenkins suffix in the authorized_keys file in the apps (abhgupta@redhat.com)
- adding fix from master into model refactor manually for passing server
  identities during gear creation (abhgupta@redhat.com)
- reverting change to rest user model (abhgupta@redhat.com)
- - Added UtilHelper module: It has deep_copy() method - Fix elaborate() in
  application model: group_overides.dup only does shallow copy, we need to do
  deep copy. (rpenta@redhat.com)
- Fix for issue where addtl_fs_gb could not be set for non-scalable apps
  (abhgupta@redhat.com)
- Fix for bug 895441 - validing against scales_from being higher than scales_to
  (abhgupta@redhat.com)
- bumping rest api version to handle change in rest user model
  (abhgupta@redhat.com)
- Fix prereq for usage ops (rpenta@redhat.com)
- - Remove addtl_fs_gb, gear_size fields from GroupInstance - Don't need
  :set_additional_storage op, :set_gear_additional_storage op is enough - some
  cleanup (rpenta@redhat.com)
- making changes so that we call delete/deconfigure on the app and not each
  cart (abhgupta@redhat.com)
- fix for bug 896333 (abhgupta@redhat.com)
- fixing gear usage record validation during app destroy (abhgupta@redhat.com)
- GearSize fix: Set default_gear_size for the app to 'small' if nil is passed
  from applications controller. (rpenta@redhat.com)
- Usage: Added gear_size, addtl_fs_gb validations to avoid invalid
  usage/usagerecord. (rpenta@redhat.com)
- fixing application action rollback (abhgupta@redhat.com)
- fix broker unit testcase (rchopra@redhat.com)
- Fix Usage: Through an error instead of bailing out when gear was created with
  usage-tracking disabled and later on gear was destroyed with usage-tracking
  enabled (rpenta@redhat.com)
- Fix Usage workflow: Don't create begin/end record if additional storage is
  zero (rpenta@redhat.com)
- Bug 895441 (rchopra@redhat.com)
- indexed and Bug 894985 (rchopra@redhat.com)
- fixed runtime tests and Lock exception handling (lnader@redhat.com)
- _id is uuid for uri information (rchopra@redhat.com)
- fix for bug 895730 and 895733 (abhgupta@redhat.com)
- Added CloudUser.force_delete option and fix oo-admin-ctl-user script
  (rpenta@redhat.com)
- auto retry on application lock acquire (rchopra@redhat.com)
- Fix district model and district unit tests rework (rpenta@redhat.com)
- added retries to application destroy in case app is locked by another op
  (lnader@redhat.com)
- removed group check from descriptot (profiles no longer have groups
  (lnader@redhat.com)
- _id to uuid for controllers - affects migrated apps (rchopra@redhat.com)
- Assume default gear size in calculate_gear_create_ops() if gear size is not
  passed (rpenta@redhat.com)
- fix for bug 889932 (abhgupta@redhat.com)
- remove some more datastore references (rpenta@redhat.com)
- fix build issue (rchopra@redhat.com)
- Populate mongoid.yml config from Rails datastore configuration.
  (rpenta@redhat.com)
- changing reload calls to reload from primary (abhgupta@redhat.com)
- fixing issue where completed pending_ops were not being deleted from domain
  and user docs in mongo (abhgupta@redhat.com)
- Rollback logic fixes (kraman@gmail.com)
- cleanup (dmcphers@redhat.com)
- user_agent tracking (rchopra@redhat.com)
- Bug 893879 (dmcphers@redhat.com)
- Bug 889958 (dmcphers@redhat.com)
- fixing test condition (abhgupta@redhat.com)
- fix for bug 893365 (abhgupta@redhat.com)
- district re-alignment for migration (rchopra@redhat.com)
- fix for bug893366 (rchopra@redhat.com)
- Bug 893265 (dmcphers@redhat.com)
- Bug 889940 Comment 6 (dmcphers@redhat.com)
- Give a better message on missing feature (dmcphers@redhat.com)
- Bug 891801 (dmcphers@redhat.com)
- temporary fix for bug 893176 (lnader@redhat.com)
- CloudUser.with_plan scope added for rhc-admin-ctl-plan (rpenta@redhat.com)
- use uuid for communication with node (rchopra@redhat.com)
- fix for bug 891810 (abhgupta@redhat.com)
- fix for bug 892106 (abhgupta@redhat.com)
- fix for bug 892881 (abhgupta@redhat.com)
- fix for bug 892105 (abhgupta@redhat.com)
- Bug 892068 and fixed HTTP error codes (lnader@redhat.com)
- uuid field to the gear+application models (rchopra@redhat.com)
- removing debug info being printed in test (abhgupta@redhat.com)
- Bug 890119 (lnader@redhat.com)
- fixing bug 892756 (abhgupta@redhat.com)
- Bug 889958 (dmcphers@redhat.com)
- Bug 892098 (lnader@redhat.com)
- can't send nil for gear_size (dmcphers@redhat.com)
- Bug 889940 (dmcphers@redhat.com)
- Bug 892099 (dmcphers@redhat.com)
- Bug 891901 (dmcphers@redhat.com)
- Bug 892117 (dmcphers@redhat.com)
- Bug 892139 (dmcphers@redhat.com)
- Bug 892104 (dmcphers@redhat.com)
- Bug 892129 (dmcphers@redhat.com)
- fixed missing attribute (lnader@redhat.com)
- Removing application estimate cucumber test (abhgupta@redhat.com)
- Fixing extended broker tests (abhgupta@redhat.com)
- Bug 889947 (lnader@redhat.com)
- fix for REST API reading the value as true Bug 890001 (lnader@redhat.com)
- temp fix for max_gears error (rchopra@redhat.com)
- Fix for bug 889978 (abhgupta@redhat.com)
- commenting out broken tests for now - were always broke but error was hidden
  before (dmcphers@redhat.com)
- Bug# 889957: part 1 (rpenta@redhat.com)
- simplify previous fix (dmcphers@redhat.com)
- update namespace fix (rchopra@redhat.com)
- special case web_proxy (dmcphers@redhat.com)
- Bug# 890009 : Fix 'nolinks' param (rpenta@redhat.com)
- Bug 889940 part 2 (dmcphers@redhat.com)
- Bug 889940 part 1 (dmcphers@redhat.com)
- Bug 889917 (dmcphers@redhat.com)
- fix for bug#889938 (rchopra@redhat.com)
- Bug 889952 (lnader@redhat.com)
- fix for bug#889986 (rchopra@redhat.com)
- Bug 889939 (lnader@redhat.com)
- Bug 889932 (dmcphers@redhat.com)
- Bug 889951 (lnader@redhat.com)
- Bug 890101 (dmcphers@redhat.com)
- more runtime test fixes (rchopra@redhat.com)
- fix runtime destroy test (rchopra@redhat.com)
- admin script fixes (rchopra@redhat.com)
- fixed merge mistake (lnader@redhat.com)
- Fixed site application tests (lnader@redhat.com)
- fixing site cartridge tests (abhgupta@redhat.com)
- fixing site integration test for application (abhgupta@redhat.com)
- removed rest_application13.rb (lnader@redhat.com)
- admin-ctl-app remove particular gear (rchopra@redhat.com)
- fixing ssh key test failures (abhgupta@redhat.com)
- fixed regression errors (lnader@redhat.com)
- more admin script fixes (rchopra@redhat.com)
- fixing update namespacwe (abhgupta@redhat.com)
- fixing update_namespace (abhgupta@redhat.com)
- fixed domain update validation (lnader@redhat.com)
- fixed 2 regression bugs (lnader@redhat.com)
- fixing broker tests again after rebase (abhgupta@redhat.com)
- search gear/app by uuid (rchopra@redhat.com)
- logging exception in case of pending app job failure (abhgupta@redhat.com)
- fixiing application scale-up (abhgupta@redhat.com)
- district search fix (rchopra@redhat.com)
- removing txt records (dmcphers@redhat.com)
- removing gears resource from the routes (abhgupta@redhat.com)
- refactoring to use getter/setter for user capabilities (abhgupta@redhat.com)
- lock with timeout (kraman@gmail.com)
- rollback component check from change calculations (rchopra@redhat.com)
- reverting fix for broker integration test (abhgupta@redhat.com)
- removing app templates and other changes (dmcphers@redhat.com)
- fixing broker integration test (abhgupta@redhat.com)
- addtional_storage fixes (rchopra@redhat.com)
- removed show-port from tests and added correct error response to controller
  (lnader@redhat.com)
- fix rest-workflow (dmcphers@redhat.com)
- fixing user creation in legacy controller (abhgupta@redhat.com)
- fixing rest_api_test and fixing backward compatibility bugs
  (lnader@redhat.com)
- fix ssh key issue - not a final fix (dmcphers@redhat.com)
- remove extra save call (dmcphers@redhat.com)
- Fixing bad merge for add_alias (kraman@gmail.com)
- porting bug fix for 883607 to model refactor branch (abhgupta@redhat.com)
- handle options on cloud use save (dmcphers@redhat.com)
- fix typo (dmcphers@redhat.com)
- fix oo-accept-node (dmcphers@redhat.com)
- fixing cloud user test cases (dmcphers@redhat.com)
- Throw exception if user is trying to scale up/down a non scalable app
  (lnader@redhat.com)
- Removing application templates (kraman@gmail.com)
- district fixes (rchopra@redhat.com)
- Fixed error in feature removal (kraman@gmail.com)
- default gear sizes (rchopra@redhat.com)
- config is msg_broker and not gearchanger (rchopra@redhat.com)
- test case fixes + typo fixes (dmcphers@redhat.com)
- bug fixes in app and descriptor controller (lnader@redhat.com)
- fix ss refs (dmcphers@redhat.com)
- Merged Ravi's changes for usage records (kraman@gmail.com)
- Fixed scaled app creation Fixed scaled app cartridge addition Updated
  descriptors to set correct group overrides for web_cartridges
  (kraman@gmail.com)
- deregister dns (dmcphers@redhat.com)
- Fixing php manifest Adding logging statements for debugging scaled apps
  (kraman@gmail.com)
- Added support for thread dump. Fixed default username in mongoid.yml file
  (kraman@gmail.com)
- Various bugfixes (kraman@gmail.com)
- fixed error on creating app by adding the user lock on user create
  (lnader@redhat.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)
- Ensure write to at least 2 mongo instances (dmcphers@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.8-1
- Merge pull request #1183 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 902117 (dmcphers@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.7-1
- Merge pull request #500 from mscherer/fix_missing_jsondata
  (dmcphers+openshiftbot@redhat.com)
- include webproxy group instance in non ha list (dmcphers@redhat.com)
- favor different nodes within a gear group (dmcphers@redhat.com)
- Merge pull request #1169 from smarterclayton/use_nahi_httpclient_instead
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'master' of git://github.com/openshift/origin-server into
  use_nahi_httpclient_instead (ccoleman@redhat.com)
- Use --insecure in tests Use --clean to isolate problems, purge the express
  config Swap node_steps to use rhc_delete_domain/create_domain for sanity
  (ccoleman@redhat.com)
- Do not return a unclear error message if json_data is not set
  (mscherer@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.6-1
- Adding support for broker to mongodb connections over SSL
  (calfonso@redhat.com)
- Merge pull request #1163 from ironcladlou/endpoint-refactor
  (dmcphers@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Bug 895269 (dmcphers@redhat.com)

* Mon Jan 14 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Merge pull request #1145 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1146 from pmorie/bugs/fix-tests2
  (dmcphers+openshiftbot@redhat.com)
- increase jenkins creation timeout (bdecoste@gmail.com)
- Fix failing socket file tests (pmorie@gmail.com)
- Merge pull request #916 from Miciah/devenv-fixes-2
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1142 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- kill orphan jenkins process (bdecoste@gmail.com)
- harden JSON parsing for jenkins test (bdecoste@gmail.com)
- Add @not-enterprise tag to some tests (miciah.masters@gmail.com)
- Fix tests to use newer-style rhc invocations (miciah.masters@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- increased jenkins test timeout (bdecoste@gmail.com)
- Merge pull request #1134 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- updated ews2 tests (bdecoste@gmail.com)
- Fix BZ892006: Make postgresql socket file access solvent and add tests for
  postgres and mysql socket files. (pmorie@gmail.com)
- added ews2 tests (bdecoste@gmail.com)
- Refactor to use env var rather than output from hook (jhonce@redhat.com)
- Merge pull request #1083 from bdecoste/master (openshift+bot@redhat.com)
- re-enabed ews2 (bdecoste@gmail.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.10-1
- Merge pull request #986 from BanzaiMan/dev/hasari/us2975
  (dmcphers@redhat.com)
- 'rhc cartridge add' output format is different (asari.ruby@gmail.com)
- The pertinent line changed the output format. (asari.ruby@gmail.com)
- Remove cartridge from the command line. (asari.ruby@gmail.com)
- Fixed cucmber errors by increasing retry attempts and timeout margins
  (nhr@redhat.com)
- Fix 'rhc domain update' command usage. (asari.ruby@gmail.com)
- Upload ssh key before creating app. (asari.ruby@gmail.com)
- --state, not --status. (asari.ruby@gmail.com)
- 'rhc app create' does not clone repo if dns option is not set.
  (asari.ruby@gmail.com)
- Log timing correctly. (asari.ruby@gmail.com)
- Oops. '$' was missing. (asari.ruby@gmail.com)
- One more deprecated command that slipped through. (asari.ruby@gmail.com)
- Tweak flags further to avoid warnings. (asari.ruby@gmail.com)
- Properly invoke 'rhc domain destroy'. (asari.ruby@gmail.com)
- First pass at US2795. (asari.ruby@gmail.com)
- fix for resultio append (abhgupta@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.9-1
- fixfor bug#883007 (rchopra@redhat.com)
- Merge pull request #1029 from bdecoste/master (openshift+bot@redhat.com)
- Merge pull request #1048 from lnader/master (openshift+bot@redhat.com)
- Bug 883151 - Broker should return valid error response (lnader@redhat.com)
- removed ews2.0 and sy xslt (bdecoste@gmail.com)
- remove ews2 tests (bdecoste@gmail.com)
- ews2 and bugs (bdecoste@gmail.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.8-1
- Merge pull request #1042 from lnader/master (openshift+bot@redhat.com)
- Fix for Bug 885177 (jhonce@redhat.com)
- bug fix (lnader@redhat.com)
- US3025: Retrieve cartridge info with app (lnader@redhat.com)
- Needed a narrower test, \w catches characters invalid in DNS.
  (rmillner@redhat.com)
- Proper host name validation. (rmillner@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.7-1
- Merge pull request #1035 from abhgupta/abhgupta-dev
  (openshift+bot@redhat.com)
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- add debugging to help with issues found in field (dmcphers@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- fix for bug#883007 (rchopra@redhat.com)
- fix for bug#883740 - additional storage is reset on scale up/down
  (rchopra@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- create :default_gear_capabilities conf key for setting default gear
  capabilities a user has at creation (lmeyer@redhat.com)
- Merge pull request #1012 from brenton/dead_code1 (openshift+bot@redhat.com)
- Merge pull request #1014 from rajatchopra/master (openshift+bot@redhat.com)
- fix bug#883553 - additional_storage param is now additional_gear_storage
  (rchopra@redhat.com)
- Removing some dead code (bleanhar@redhat.com)
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Merge pull request #995 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- more mco 2.2 changes (dmcphers@redhat.com)
- more changes for US3078 (abhgupta@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)
- Merge pull request #1001 from pmorie/sooth_ops (openshift+bot@redhat.com)
- Remove 'framework' message from Application constructor (pmorie@gmail.com)
- fixing mongo connection issues for build (dmcphers@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- changes for US3078 (abhgupta@redhat.com)
- Remove unused phpmoadmin cartridge (jhonce@redhat.com)
- Bug 880370 (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- Merge pull request #945 from smarterclayton/improve_invalid_cart_message
  (openshift+bot@redhat.com)
- Improve the invalid cart message to read more naturally for users, and to
  better reflect what the user has passed. (ccoleman@redhat.com)
- Merge pull request #956 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #954 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- Merge pull request #953 from rajatchopra/master (dmcphers@redhat.com)
- Add method to get the active gears (dmcphers@redhat.com)
- Fix for bug 875442 (abhgupta@redhat.com)
- reform the get_all_gears call and add capability to reserve a specific uid
  from a district (rchopra@redhat.com)
- Merge pull request #915 from Miciah/devenv-fixes-1 (openshift+bot@redhat.com)
- Fix tests to work with remote-user auth (miciah.masters@gmail.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.10-1
- Bug 877340 (dmcphers@redhat.com)
- Merge pull request #913 from
  smarterclayton/better_gear_limit_message_on_create (openshift+bot@redhat.com)
- Bug 876796 (dmcphers@redhat.com)
- fix typo (dmcphers@redhat.com)
- Return a better error message when the gear limit on app creation is reached.
  (ccoleman@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.9-1
- fix broker extended tests (dmcphers@redhat.com)
- more ruby1.9 changes (dmcphers@redhat.com)
- Merge pull request #911 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #910 from jwhonce/dev/bz876687 (openshift+bot@redhat.com)
- fix for bug#875258 (rchopra@redhat.com)
- Merge pull request #907 from danmcp/master (dmcphers@redhat.com)
- remove spurious output (jhonce@redhat.com)
- Merge pull request #909 from pravisankar/dev/ravi/us3043_bugs
  (dmcphers@redhat.com)
- Merge pull request #904 from bdecoste/master (openshift+bot@redhat.com)
- Bug 876459 (dmcphers@redhat.com)
- Fix for bug# 876516 (rpenta@redhat.com)
- Fix bug# 876124: caused due to ruby 1.8 to 1.9 upgrade (rpenta@redhat.com)
- switchyard tests (bdecoste@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.8-1
- Merge pull request #906 from ironcladlou/db-test-fixes (dmcphers@redhat.com)
- Fix typo resulting in undefined stepdef (ironcladlou@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- Compare retcode as an int rather than string (ironcladlou@gmail.com)
- Merge pull request #895 from smarterclayton/us3046_quickstarts_and_app_types
  (openshift+bot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  us3046_quickstarts_and_app_types (ccoleman@redhat.com)
- Quickstart URLs aren't spec compliant (ccoleman@redhat.com)
- Relativize base URL (ccoleman@redhat.com)
- Support COMMUNITY_QUICKSTARTS_URL parameter for serving hardcoded quickstarts
  vs. public quickstarts, and test that these values are returned.
  (ccoleman@redhat.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- fix testdescriptor generator (dmcphers@redhat.com)
- get the broker working again (dmcphers@redhat.com)
- Move trap-user.feature and trap-user-extended.feature to origin-server
  (pmorie@gmail.com)
- Test support and nodejs test fixes for Ruby 1.9 (ironcladlou@gmail.com)
- fixing tests (dmcphers@redhat.com)
- Remove hard-coded ruby references (ironcladlou@gmail.com)
- add config to gemspec (dmcphers@redhat.com)
- Moving plugins to Rails 3.2.8 engine (kraman@gmail.com)
- Ruby 1.9 compatibility fixes (ironcladlou@gmail.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- Merge pull request #894 from jwhonce/master (openshift+bot@redhat.com)
- Merge pull request #888 from pravisankar/dev/ravi/bug/876124
  (dmcphers@redhat.com)
- Fix for Bug# 876124 (rpenta@redhat.com)
- Move idler tests to origin-server (jhonce@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- specifying mocha gem version and fixing tests (abhgupta@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Merge pull request #859 from lnader/master (openshift+bot@redhat.com)
- US3043: store initial_git_url (lnader@redhat.com)
- US3043: Allow applications to be created from adhoc application templates
  (lnader@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #845 from brenton/BZ873992-origin
  (openshift+bot@redhat.com)
- Merge pull request #844 from jwhonce/dev/bz873810 (openshift+bot@redhat.com)
- Bug 873992 - [onpremise][Client]Should delete all the prompts about
  mongodb-2.2 cartridge. (bleanhar@redhat.com)
- Merge pull request #839 from pravisankar/dev/ravi/fix-env-controller-auth
  (openshift+bot@redhat.com)
- Disable auth for environment controller (rpenta@redhat.com)
- Fix for Bug 873810 (jhonce@redhat.com)
- fixing origin tests (abhgupta@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #815 from pravisankar/dev/ravi/fix_nameserver_resolver
  (openshift+bot@redhat.com)
- Fix name server cache: query up the chain to find dns resolver nameservers
  (rpenta@redhat.com)
