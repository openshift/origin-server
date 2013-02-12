%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-console
%global rubyabi 1.9.1

Summary:       OpenShift Origin Management Console
Name:          rubygem-%{gem_name}
Version:       1.5.2
Release:       2%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{gem_name}/rubygem-%{gem_name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
%if 0%{?fedora}%{?rhel} <= 6
Requires:      %{?scl:%scl_prefix}rubygem(rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(rdiscount)
Requires:      %{?scl:%scl_prefix}rubygem(formtastic)
Requires:      %{?scl:%scl_prefix}rubygem(net-http-persistent)
Requires:      %{?scl:%scl_prefix}rubygem(haml)
Requires:      %{?scl:%scl_prefix}rubygem(ci_reporter)
Requires:      %{?scl:%scl_prefix}rubygem(coffee-rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(jquery-rails)
Requires:      %{?scl:%scl_prefix}rubygem(mocha)
Requires:      %{?scl:%scl_prefix}rubygem(sass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(simplecov)
Requires:      %{?scl:%scl_prefix}rubygem(test-unit)
Requires:      %{?scl:%scl_prefix}rubygem(uglifier)
Requires:      %{?scl:%scl_prefix}rubygem(webmock)
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
BuildRequires: %{?scl:%scl_prefix}rubygem(rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(compass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(mocha)
BuildRequires: %{?scl:%scl_prefix}rubygem(simplecov)
BuildRequires: %{?scl:%scl_prefix}rubygem(test-unit)
BuildRequires: %{?scl:%scl_prefix}rubygem(ci_reporter)
BuildRequires: %{?scl:%scl_prefix}rubygem(webmock)
BuildRequires: %{?scl:%scl_prefix}rubygem(sprockets)
BuildRequires: %{?scl:%scl_prefix}rubygem(rdiscount)
BuildRequires: %{?scl:%scl_prefix}rubygem(formtastic)
BuildRequires: %{?scl:%scl_prefix}rubygem(net-http-persistent)
BuildRequires: %{?scl:%scl_prefix}rubygem(haml)
BuildRequires: %{?scl:%scl_prefix}rubygem(therubyracer)
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildRequires: %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires: %{?scl:%scl_prefix}ruby 
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
This contains the OpenShift Origin Management Console.

%package doc
Summary: OpenShift Origin Management Console docs.

%description doc
OpenShift Origin Management Console ri documentation 

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}

set -e
mkdir -p .%{gem_dir}

%if 0%{?fedora}%{?rhel} <= 6
rm -f Gemfile.lock
bundle install --local

mkdir -p %{buildroot}%{_var}/log/openshift/console/
mkdir -m 770 %{buildroot}%{_var}/log/openshift/console/httpd/
touch %{buildroot}%{_var}/log/openshift/console/production.log
chmod 0666 %{buildroot}%{_var}/log/openshift/console/production.log

pushd test/rails_app/
CONSOLE_CONFIG_FILE=../../conf/console.conf.example \
  RAILS_ENV=production \
  RAILS_LOG_PATH=%{buildroot}%{_var}/log/openshift/console/production.log \
  RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
echo > %{buildroot}%{_var}/log/openshift/console/production.log
popd

rm -rf %{buildroot}%{_var}/log/openshift/*

rm -f Gemfile.lock
%endif

# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

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
* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-2
- bump for chainbuild

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Merge pull request #1343 from nhr/BZ885194_fixed_account_upgrade_validations
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1339 from tdawson/tdawson/cleanup-spec-headers
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1342 from sg00dwin/bug-fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 885194 - Corrected form handler to suppress submit on form errors
  (hripps@redhat.com)
- Add function for placeholder on create app form include jquery_placeholder
  for ie9 and older (sgoodwin@redhat.com)
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-2
- bump for chainbuild

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.9-2
- bump for chainbuild

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.9-1
- Merge pull request #1330 from rhamilto/master (dmcphers@redhat.com)
- Merge pull request #1324 from tdawson/tdawson/remove_rhel5_spec_stuff
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1314 from fotioslindiakos/BZ907570 (dmcphers@redhat.com)
- Merge pull request #1327 from fotioslindiakos/max_gears_errors
  (dmcphers@redhat.com)
- Merge pull request #1325 from fotioslindiakos/async_aware_bug
  (dmcphers+openshiftbot@redhat.com)
- Bug 907570: Don't render form is user cannot upgrade storage
  (fotios@redhat.com)
- Only process the :base errors once (fotios@redhat.com)
- Tweaking the logo dimensions to improve upon the rotate on hover effect.
  (rhamilto@redhat.com)
- Merge pull request #1323 from
  smarterclayton/capabilities_test_too_sensitive_to_scope
  (dmcphers+openshiftbot@redhat.com)
- Fixes a problem loading the gear_group model in the storage_controller with
  AsyncAware (fotios@redhat.com)
- The capabilities test in application types controller test is too sensitive
  to the actual values on the session, we need to make it cleaner.
  (ccoleman@redhat.com)
- remove BuildRoot: (tdawson@redhat.com)
- Merge pull request #1319 from smarterclayton/align_popover_right
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1318 from tdawson/tdawson/openshift-common-sources
  (dmcphers+openshiftbot@redhat.com)
- Align popover to the right for restart (ccoleman@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.8-2
- bump for chainbuild

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.8-1
- Merge pull request #1309 from smarterclayton/improve_capability_extension
  (dmcphers+openshiftbot@redhat.com)
- Fix caching issues in plan controller, handle new attributes, revert to
  correct version of Rails model lookup code (caused Cartridge.prefix to be
  reset) (ccoleman@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.7-2
- bump for chainbuild

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.7-1
- Merge pull request #1302 from smarterclayton/restore_uppercase_bits
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1301 from smarterclayton/fix_firesass_support
  (dmcphers+openshiftbot@redhat.com)
- Restore uppercase style (ccoleman@redhat.com)
- Fix FireSass support in origin (ccoleman@redhat.com)
- Merge pull request #1295 from smarterclayton/hide_service_tag
  (dmcphers+openshiftbot@redhat.com)
- Hide the service tag in the UI (ccoleman@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- Merge pull request #1265 from fotioslindiakos/storage
  (dmcphers+openshiftbot@redhat.com)
- Fixing tests (fotios@redhat.com)
- Moved can_modify_storage to controller and capabilities Use flash message if
  user cannot modify storage (fotios@redhat.com)
- Fixing functional tests (fotios@redhat.com)
- Show gear_groups properly when the carts have different storage values
  (fotios@redhat.com)
- More changes (fotios@redhat.com)
- US2441: Storage UI (fotios@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- popover title wasn't rendering - fix (sgoodwin@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.4-2
- bump spec for chainbuild (admiller@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> - 1.4.4-2
- bump spec for chain build

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Merge pull request #1252 from
  smarterclayton/us3350_establish_plan_upgrade_capability
  (dmcphers+openshiftbot@redhat.com)
- Sort test results for comparison (ccoleman@redhat.com)
- US3350 - Expose a plan_upgrade_enabled capability that indicates whether
  users can select a plan (ccoleman@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1253 from smarterclayton/bug_878328_clarify_filter
  (dmcphers+openshiftbot@redhat.com)
- Bug 878328 - Alter instant app filter title to be clearer
  (ccoleman@redhat.com)
- Bug 902962 - Only highlight URL field when error occurs (ccoleman@redhat.com)
- Merge pull request #1244 from brenton/misc6
  (dmcphers+openshiftbot@redhat.com)
- Bug 893298 - fixing the missing . on the site /account page
  (bleanhar@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Update console/README.md (ccoleman@redhat.com)
- remove consumed_gear_sizes (dmcphers@redhat.com)
- Merge pull request #1212 from brenton/misc5
  (dmcphers+openshiftbot@redhat.com)
- make test react to weirdness of controller (dmcphers@redhat.com)
- Bug 876087 (dmcphers@redhat.com)
- correct link (sgoodwin@redhat.com)
- add partners link in footer (sgoodwin@redhat.com)
- Merge pull request #1152 from jtharris/features/US3205
  (dmcphers+openshiftbot@redhat.com)
- BZ892990 - The server address should not be "localhost" on user account info
  page (bleanhar@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- Merge pull request #1208 from kraman/features/model_refactor
  (dmcphers+openshiftbot@redhat.com)
- US3205 - Adding restart functionality to UI (jharris@redhat.com)
- Merge pull request #1206 from sg00dwin/misc-dev
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Fixed site application tests (lnader@redhat.com)
- Fixed site Misc 1 tests (lnader@redhat.com)
- fixed scaling test (lnader@redhat.com)
- fixing site ssh key rest api integration test (abhgupta@redhat.com)
- Merge pull request #1207 from
  smarterclayton/only_boot_rest_api_in_development
  (dmcphers+openshiftbot@redhat.com)
- use clearfix instead of overflow:hidden allows tb focus to be seen
  (sgoodwin@redhat.com)
- In production, don't attempt to connect to the REST API on startup
  (ccoleman@redhat.com)
- overwrite mixin and adjustoffset for primary nav (sgoodwin@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.9-1
- Merge remote-tracking branch 'upstream/master' (ffranz@redhat.com)
- Bug 901949 - setting Accept header on OAuth to workaround a bug in some
  versions of ActiveSupport (ffranz@redhat.com)
- Merge pull request #1193 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 901342 - timestamp was being cached which was causing several 401 errors
  when calling Twitter api (ffranz@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.8-1
- Merge pull request #1191 from jtharris/bugs/894229
  (dmcphers+openshiftbot@redhat.com)
- Fix for Bug 894229 (jharris@redhat.com)
- Ensure descriptions for cartridges and application types are safe and limited
  in the UI. (ccoleman@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.7-1
- Merge pull request #1149 from fotioslindiakos/captcha
  (dmcphers+openshiftbot@redhat.com)
- Added js_required helper (fotios@redhat.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.6-1
- Fixes Bug 895370 (ffranz@redhat.com)
- Merge pull request #1155 from tdawson/tdawson/fix-misc-jan16
  (dmcphers+openshiftbot@redhat.com)
- fedora mock build fix (tdawson@redhat.com)

* Wed Jan 16 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Merge pull request #1144 from fabianofranz/dev/ffranz/twitter1.1
  (dmcphers+openshiftbot@redhat.com)
- Using CGI.escape to percent_encode OAuth headers (ffranz@redhat.com)
- Now using SecureRandom.hex to generate OAuth nonce (ffranz@redhat.com)
- Added simple OAuth client support as a mixin (ffranz@redhat.com)

* Mon Jan 14 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Update UserGuide link to Working With Domains Switch namespace form to use
  latest input_append input_prepend (sgoodwin@redhat.com)
- Merge pull request #1139 from
  smarterclayton/bug_893298_add_dot_to_domain_name_form
  (dmcphers+openshiftbot@redhat.com)
- Bug 893298 - Add period to domain name form (ccoleman@redhat.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Bug 892906 - Fix client tools link (ccoleman@redhat.com)
- Merge pull request #1130 from sg00dwin/bug892694-addon
  (dmcphers+openshiftbot@redhat.com)
- fix for Bug 892694 - When entering an invalid domain name or app name on the
  app creation page, the text in the public URL is unreadable  - Set color to
  inherit (white) so it displays on error red bg (sgoodwin@redhat.com)
- Bug 889376 - Provide more clarification of what happens when creating an app
  based on a git repo (ccoleman@redhat.com)
- Merge pull request #1123 from sg00dwin/signup
  (dmcphers+openshiftbot@redhat.com)
- Added functional coverage / removed app template logic (hripps@redhat.com)
- Create variables for border color; .ie specific styled moved to core
  (sgoodwin@redhat.com)
- Modified scalability tests to check for 'not_scalable' tags
  (hripps@redhat.com)
- Merge pull request #1100 from sg00dwin/misc-dev
  (dmcphers+openshiftbot@redhat.com)
- Switch app url form to use lates twitter prepend.append and block them >480;
  plus multiple cleanup changes (sgoodwin@redhat.com)
- switch to <p> for spacing (sgoodwin@redhat.com)
- Revised quickstart scalability check to handle nil summary (nhr@redhat.com)
- Faster regex + DRYer mocking for unit tests (nhr@redhat.com)
- Added unit tests for quickstart scalability parsing (nhr@redhat.com)
- Quickstart scalability now determined in summary field (nhr@redhat.com)
- Merge pull request #1092 from smarterclayton/mock_environments_for_test
  (openshift+bot@redhat.com)
- Merge pull request #1083 from bdecoste/master (openshift+bot@redhat.com)
- Mock environment call for simplicity in some states (ccoleman@redhat.com)
- Merge pull request #1081 from smarterclayton/quickstart_nil_error
  (openshift+bot@redhat.com)
- re-enabed ews2 (bdecoste@gmail.com)
- A nil error is displayed when quickstarts are shown with type length == 1
  (ccoleman@redhat.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- Added a specific fix for quickstarts and two related improvements to the app
  config page (hripps@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.7-1
- Merge pull request #1061 from fotioslindiakos/BZ886146 (dmcphers@redhat.com)
- Moved async_aware into the models (fotios@redhat.com)
- Addition of block classes for buttons. Addresses Bug 883334
  (sgoodwin@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into dev
  (sgoodwin@redhat.com)
- "new block level class and btn-block class" (sgoodwin@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1045 from kraman/f17_fixes (openshift+bot@redhat.com)
- Reverted oauth mixin (ffranz@redhat.com)
- Added helpers for outage jsonp (ffranz@redhat.com)
- changes associated with revamped simple template (sgoodwin@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)
- Merge remote-tracking branch 'upstream/master' (ffranz@redhat.com)
- Merge remote-tracking branch 'upstream/master' (ffranz@redhat.com)
- Merge remote-tracking branch 'upstream/master' (ffranz@redhat.com)
- Merge remote-tracking branch 'upstream/master' (ffranz@redhat.com)
- Updating our Twitter clients to use the REST API 1.1 (ffranz@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1032 from smarterclayton/quickstart_issues_in_prod
  (dmcphers@redhat.com)
- Fix OpenShift Origin bugzilla URL, ensure that quickstarts are a bit more
  resilient to missing data, and ensure value field of search is propagated
  (ccoleman@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Merge pull request #1025 from
  smarterclayton/bug_883253_search_button_for_forms (openshift+bot@redhat.com)
- Bug 883253, Bug 882904 (ccoleman@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Updated base on review feedback (nhr@redhat.com)
- Corrected boolean inputs to work w/ bootstrap styles (hripps@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Remove unused phpmoadmin cartridge (jhonce@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- Merge pull request #960 from smarterclayton/no_python_filter
  (openshift+bot@redhat.com)
- No python filter in the UI (ccoleman@redhat.com)
- Revised formtastic to handle hints for inline elements (hripps@redhat.com)
- Bug 877979 - Instant app tag should be visible to users (ccoleman@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- Bug 876853 - Preserve form inputs when clicking 'change'
  (ccoleman@redhat.com)
- Remove excess debugging, handle merge of change to Quickstart#cartridges
  (ccoleman@redhat.com)
- Bug 877222 - Some values not correctly being carried across - need to know
  when quickstart is invalid (ccoleman@redhat.com)
- Merge pull request #929 from smarterclayton/slightly_extend_match_spec
  (openshift+bot@redhat.com)
- Merge pull request #913 from
  smarterclayton/better_gear_limit_message_on_create (openshift+bot@redhat.com)
- Merge pull request #918 from sg00dwin/master (dmcphers@redhat.com)
- Extend the match spec to support OR construct 'php-|zend-' returns both PHP
  and Zend (ccoleman@redhat.com)
- calling bootstrap-tab.js in console.js adding conditional for ie9
  (sgoodwin@redhat.com)
- include bootstrap-tab js (sgoodwin@redhat.com)
- Return a better error message when the gear limit on app creation is reached.
  (ccoleman@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Merge pull request #919 from
  smarterclayton/bug_876894_cache_of_templates_horribly_wrong
  (openshift+bot@redhat.com)
- Bug 876894 - Caching of templates is horribly incorrect, causing bad cache
  fetches (ccoleman@redhat.com)
- more ruby1.9 changes (dmcphers@redhat.com)
- Merge pull request #898 from
  smarterclayton/bug_876525_poorly_formatted_json_should_be_handled
  (dmcphers@redhat.com)
- Test was pointing to the wrong id (ccoleman@redhat.com)
- Bug 876525 - Handle poorly formatted JSON from a quickstart
  (ccoleman@redhat.com)
- Remove old helper (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Merge pull request #895 from smarterclayton/us3046_quickstarts_and_app_types
  (openshift+bot@redhat.com)
- Test / merge conflict (ccoleman@redhat.com)
- A few leftover style problems with input-append-prepend in Firefox,
  placeholder bug in chrome (ccoleman@redhat.com)
- Remove conflicting metadata (ccoleman@redhat.com)
- Cleanup visuals of app creation, indicate default git branch, add a date
  helper for visuals, and ensure jenkins has the instant_app tag.
  (ccoleman@redhat.com)
- Support a few edge cases - local quickstarts and idle applications
  (ccoleman@redhat.com)
- Attempt to correct test failure issues on test execution and cleanup
  (ccoleman@redhat.com)
- Quickstart URLs aren't spec compliant (ccoleman@redhat.com)
- Implement all templates as the base quickstarts, and make quickstart.rb a bit
  more flexible (ccoleman@redhat.com)
- Fix broken test (ccoleman@redhat.com)
- Add an accordion mode for wider displays, add a unit test for invalid gear
  size (ccoleman@redhat.com)
- Disable initial_git_branch UI support until it is implemented
  (ccoleman@redhat.com)
- US3046: Allow quickstarts to show up in the UI (ccoleman@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Removed outdated 'conflicts' constraints from cartridge config file
  (hripps@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #837 from nhr/US2458_spastic_formtastics
  (openshift+bot@redhat.com)
- Merge pull request #861 from
  smarterclayton/bug_874916_bugzilla_component_changed
  (openshift+bot@redhat.com)
- Bug 874916 - Bugzilla for OpenShift changed to OpenShift Online
  (ccoleman@redhat.com)
- Added input_inline support for checkboxes + salutations helper
  (hripps@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #816 from sg00dwin/master (openshift+bot@redhat.com)
- console sepecific input placeholder and focus colors (sgoodwin@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.3-1
- Merge pull request #814 from
  smarterclayton/bug_872055_relative_paths_not_generated_for_404
  (dmcphers@redhat.com)
- Bug 872055 - 404/500 page generation was not taking into account the relative
  URL root (ccoleman@redhat.com)
- change needed for previous commit that did a mass updated of forms.scss
  (sgoodwin@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Merge pull request #800 from bdecoste/master (openshift+bot@redhat.com)
- fix yml for RECENTLY ADDED tag (bdecoste@gmail.com)
- Merge pull request #790 from bdecoste/master (openshift+bot@redhat.com)
- BZ871314 (bdecoste@gmail.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
- Merge branch 'master' of git://github.com/openshift/origin-server
  (sgoodwin@redhat.com)
- Update all form related styles to the latest in https://github.com/thomas-
  mcdonald/bootstrap-sass based on bootstrap v2.1.0. Doing so required changes
  in several partials that are hooked into these latest styles.
  (sgoodwin@redhat.com)
- Merge pull request #769 from nhr/US1375_improved_scalability_detection
  (openshift+bot@redhat.com)
- Modified scalability determination method to match Cartridges
  (nhr@redhat.com)
- Added unit and functional tests (nhr@redhat.com)
- Aliased scalability checks to ruby-approved 'scalable?' syntax
  (nhr@redhat.com)
- Revised to evaluate supported_scales_to against support_scales_from
  (nhr@redhat.com)
- Application types now inherit a scalability check from their parents
  (nhr@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.0.14-1
- Merge pull request #738 from smarterclayton/console_remote_user
  (openshift+bot@redhat.com)
- Persisted model objects don't implement id (ccoleman@redhat.com)
- Bug 869590 - Only copy headers that are present, when BASIC enabled force
  reauth if broker returns 401 (ccoleman@redhat.com)
- Bug 869590 - Infinite redirect on visit to /unauthorized
  (ccoleman@redhat.com)
- Console needs a base file to build, update filename to match Krishna's
  preference (ccoleman@redhat.com)
- Fix user-agent, update documentation to reflect changes to config.
  (ccoleman@redhat.com)
- Finalize parameter and class names (ccoleman@redhat.com)
- Implement Auth::Passthrough completely, have unauthorized escape values
  (ccoleman@redhat.com)
- Switch to loading from a config file, split authorization into 3 modes, add
  test (ccoleman@redhat.com)

* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.0.13-1
- Bug 869494 - Using :text instead of :string for input selection on scale page
  when range is large (ccoleman@redhat.com)
- Revised test setup to reuse domain if available (nhr@redhat.com)
- Merge pull request #753 from smarterclayton/console_assets_in_production
  (openshift+bot@redhat.com)
- Remove sass requires, handled by gemfile (ccoleman@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.0.12-1
- Merge pull request #553 from nhr/specify_gear_size (openshift+bot@redhat.com)
- Revised tests to make proper use of per-test domain (nhr@redhat.com)
- BZ867779 - Revised capability_aware to allow forced session refresh
  (nhr@redhat.com)
- Fixed up test helper (nhr@redhat.com)
- Modified test to use unique domain (nhr@redhat.com)
- Added application controller tests (nhr@redhat.com)
- Moved CSS into core (nhr@redhat.com)
- Added functional tests (nhr@redhat.com)
- Updated with feedback from design discussion. (nhr@redhat.com)
- Added scaling controls to app creation. (nhr@redhat.com)
- Layout iteration 5 (nhr@redhat.com)
- Post-review modifications (hripps@redhat.com)
- US1375 Migrated account upgrade changes to crankcase (hripps@redhat.com)
- fix for bz868081 and switch to word-break:normal so words aren't broken at
  wrap (sgoodwin@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.0.11-1
- Merge pull request #699 from smarterclayton/us2283_alter_scaling_display
  (openshift+bot@redhat.com)
- Take feedback from last design meeting, emphasize minimum/maximum nature of
  the scale limits, alter text to make form more appealing, make scale
  multiplier indicate gear usage directly. (ccoleman@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.0.10-1
- Prefix options are not preserved during save for some rest api resources
  (ccoleman@redhat.com)
- Merge pull request #701 from smarterclayton/bug_821107_change_key_test
  (openshift+bot@redhat.com)
- Merge pull request #700 from
  smarterclayton/bug_851345_remove_old_error_mapping (openshift+bot@redhat.com)
- Bug 821107 - Broker now allows more key types to be saved, update testcase
  (ccoleman@redhat.com)
- Bug 851345 - Exit code 102 no longer means UserAlreadyHasDomain, broker fixed
  underlying issue (ccoleman@redhat.com)
- Merge pull request #693 from
  smarterclayton/bug_867264_unable_to_create_jenkins (openshift+bot@redhat.com)
- Bug 867264 - Not able to create jenkins app (ccoleman@redhat.com)
- Merge pull request #689 from rajatchopra/master (openshift+bot@redhat.com)
- patch tests for the respective bug fixes (rchopra@redhat.com)
- fixes for bugs 866650, 866626, 866544, 866555; also set user-agent while
  creation of apps (rchopra@redhat.com)
- Bug 864309 - Change deploy hooks link to point to new community page
  (ccoleman@redhat.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.0.9-1
- Merge pull request #685 from smarterclayton/scaling_support_in_web2
  (ccoleman@redhat.com)
- Fix final failing test prior to merge (ccoleman@redhat.com)
- Set prefix appropriately when subresources are created (ccoleman@redhat.com)
- More tests (ccoleman@redhat.com)
- Further clarifying and simplifying tests (ccoleman@redhat.com)
- Replace hardcoded cart lookups in building_controller with new rest api
  (ccoleman@redhat.com)
- Final updates to conform to Rajat's changes (ccoleman@redhat.com)
- Redo Pry integration, minor tweaks to tests (ccoleman@redhat.com)
- Switch to using cartridge scaling model vs. gear_group scaling model
  (ccoleman@redhat.com)
- Allow missing / invalid domain to properly clear session object
  (ccoleman@redhat.com)
- Prepare to infer gear groups from cartridges, simplify build checks with new
  REST API (ccoleman@redhat.com)
- Remove site specific variables, ensure set -e is present
  (ccoleman@redhat.com)
- Support an important form, tweak HR to be less prominent, add minor JS to
  emphasize save button (ccoleman@redhat.com)
- Implement #update on cartridge scaling (ccoleman@redhat.com)
- Support PATCH on update (ccoleman@redhat.com)
- Hide label element when not specified (ccoleman@redhat.com)
- Basic scaling page (ccoleman@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.0.8-1
- removing addressable dep, not needed. (admiller@redhat.com)
- Fixed select_input call to parts() (nhr@redhat.com)
- Added error processing for select inputs. (hripps@redhat.com)
- Restored automatic error collection for inline elements (hripps@redhat.com)
- BZ849627 Refactored error handling for inline form elements
  (hripps@redhat.com)

* Mon Oct 08 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Merge pull request #601 from smarterclayton/production_assets_broken
  (openshift+bot@redhat.com)
- Merge pull request #577 from smarterclayton/noise_image_too_large
  (openshift+bot@redhat.com)
- Merge pull request #545 from DanAnkers/master (openshift+bot@redhat.com)
- US2912 - Site should be able to subclass and change view generation to be
  specific. (ccoleman@redhat.com)
- renaming crankcase -> origin-server (dmcphers@redhat.com)
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Ensure static assets are compired and digests are enabled for production mode
  console. (ccoleman@redhat.com)
- Ensure Gemfile.lock is removed post install and its absence doesn't delete
  the file. (ccoleman@redhat.com)
- Allow downstream consumers to override variables easily (ccoleman@redhat.com)
- Update console/README.md (md1clv@md1clv.com)

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.0.6-1
- add Gemfile.lock to .gitignore (dmcphers@redhat.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.0.5-1
- Bug 862065 - Add some additional info to signup complete page.
  (ccoleman@redhat.com)
- Merge pull request #567 from danmcp/master (openshift+bot@redhat.com)
- removing Gemfile.locks (dmcphers@redhat.com)
- Update console/README.md (ccoleman@redhat.com)

* Sat Sep 29 2012 Adam Miller <admiller@redhat.com> 0.0.4-3
- fix typo in Requires ... its late (admiller@redhat.com)

* Sat Sep 29 2012 Adam Miller <admiller@redhat.com> 0.0.4-2
- added missing Requires: from Gemfile to spec (admiller@redhat.com)

* Sat Sep 29 2012 Adam Miller <admiller@redhat.com> 0.0.4-2
- Add missing requires from Gemfile into spec

* Sat Sep 29 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- add addressable gem dep to console (admiller@redhat.com)

* Fri Sep 28 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Merge pull request #547 from smarterclayton/add_rubyracer_for_assets
  (openshift+bot@redhat.com)
- Add therubyracer for RPM builds (ccoleman@redhat.com)

* Fri Sep 28 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Merge pull request #546 from smarterclayton/bug861317_typo_in_error
  (openshift+bot@redhat.com)
- Add instructions on finding a JS runtime (ccoleman@redhat.com)
- Bug 861317 - Typo in key error page (ccoleman@redhat.com)
- Merge pull request #542 from smarterclayton/remove_execjs_dependency
  (openshift+bot@redhat.com)
- Merge pull request #541 from smarterclayton/stack_overflow_link_broken
  (openshift+bot@redhat.com)
- ExecJS no longer needs spidermonkey with httpd_execmem selinux permission set
  (ccoleman@redhat.com)
- StackOverflow link was broken in console (ccoleman@redhat.com)
- Merge pull request #539 from
  smarterclayton/bug821107_pass_all_key_types_to_broker
  (openshift+bot@redhat.com)
- Merge pull request #537 from
  smarterclayton/bug860969_remove_deep_user_guide_link
  (openshift+bot@redhat.com)
- Bug 821107 - Allow all key types potentially (ccoleman@redhat.com)
- Bug 860969 - Remove user guide deep link (ccoleman@redhat.com)
- Simplify the console proxy setup to support native ENV from
  net::http::persistent (ccoleman@redhat.com)

* Wed Sep 26 2012 Clayton Coleman <ccoleman@redhat.com> 0.0.1-1
- Initial commit of OpenShift Origin console

