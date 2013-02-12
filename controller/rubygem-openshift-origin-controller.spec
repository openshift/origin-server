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
Version:       1.5.2
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{gem_name}/rubygem-%{gem_name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(state_machine)
Requires:      rubygem(openshift-origin-common)
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
BuildRequires: %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires: %{?scl:%scl_prefix}ruby 
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version
Obsoletes: 	   rubygem-stickshift-controller

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
