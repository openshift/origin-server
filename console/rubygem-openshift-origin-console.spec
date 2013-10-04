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
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
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
Requires:      %{?scl:%scl_prefix}rubygem(poltergeist)
Requires:      %{?scl:%scl_prefix}rubygem(konacha)
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(rspec-core)
Requires:      %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif

BuildRequires: %{?scl:%scl_prefix}rubygem(coffee-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(jquery-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(uglifier)
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
BuildRequires: %{?scl:%scl_prefix}rubygem(poltergeist)
BuildRequires: %{?scl:%scl_prefix}rubygem(konacha)
BuildRequires: %{?scl:%scl_prefix}rubygem(minitest)
BuildRequires: %{?scl:%scl_prefix}rubygem(rspec-core)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)

BuildRequires: %{?scl:%scl_prefix}rubygems-devel
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
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

find . -name .gitignore -delete
find . -name .gitkeep -delete

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
* Tue Oct 01 2013 Adam Miller <admiller@redhat.com> 1.15.7-1
- Merge pull request #3729 from smarterclayton/suggest_app_name
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3738 from jwforres/bug_1012342_delete_alias_fails
  (dmcphers+openshiftbot@redhat.com)
- Fix tests (dmcphers@redhat.com)
- Should use up to, not inclusive, review comment (ccoleman@redhat.com)
- Bug 1012342 - delete alias on aliases page fails (jforrest@redhat.com)
- Suggest an application name if possible (ccoleman@redhat.com)

* Mon Sep 30 2013 Troy Dawson <tdawson@redhat.com> 1.15.6-1
- Merge pull request #3727 from smarterclayton/fix_environment_variable_routes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3726 from jwforres/grammar_fix
  (dmcphers+openshiftbot@redhat.com)
- Update singular routes to use singular_path (ccoleman@redhat.com)
- Merge pull request #3723 from jwforres/membership_plus_console
  (dmcphers+openshiftbot@redhat.com)
- Grammar fix in applications list page help links (jforrest@redhat.com)
- Show members on the application page (jforrest@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.5-1
- Failing unit tests due to last minute changes (ccoleman@redhat.com)
- Membership changes (jliggitt@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3699 from jwforres/wrong_scale_arg_in_help
  (dmcphers+openshiftbot@redhat.com)
- Fix rhc command in not scalable help text (jforrest@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Allow for version 4.0.x of haml gem to be used (jforrest@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Remove the icon font shadow unless explicitly included with a class. Causes
  problems with varied background colors. (jforrest@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Updated cartridges and scripts for phpmyadmin-4 (mfojtik@redhat.com)
- Handle .resultset.json (dmcphers@redhat.com)
- Fixing console RPM spec to install ruby dependencies on Fedora 19
  (kraman@gmail.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Merge pull request #3437 from smarterclayton/alias_overzealous_messaging
  (dmcphers+openshiftbot@redhat.com)
- Review comments (ccoleman@redhat.com)
- Aliases are writing too many flashes when errors are present
  (ccoleman@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Merge pull request #3415 from tdawson/tdawson/mirrorfixes/2013-08
  (dmcphers+openshiftbot@redhat.com)
- Bug 997080 - chrome input fields - turn of break word (jforrest@redhat.com)
- fix old mirror url (tdawson@redhat.com)
- Merge pull request #3408 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 995034 (abhgupta@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3382 from smarterclayton/builder_scope_incorrect
  (dmcphers+openshiftbot@redhat.com)
- additional version changes (dmcphers@redhat.com)
- <cartridge versions> origin_runtime_219, fix up cart references for renamed
  cart https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-
  versions (jolamb@redhat.com)
- Fix builder scope by introducing a domain builder scope (ccoleman@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Default to test mode membership off (ccoleman@redhat.com)
- Catch more exceptions from broker (ccoleman@redhat.com)
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

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Card 57 - Fix typo (jforrest@redhat.com)
- Card 57 - gemify bootstrap, use sass-twitter-bootstrap gem
  (jforrest@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Consolidated docs for admin/mgmt consoles, cartridges (hripps@redhat.com)
- Bug 985952 - should not touch certificate if chain was not provided
  (ffranz@redhat.com)
- Bug 985952 - strip certificate content when appending chain
  (ffranz@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Add omit method for functional and integration tests (jliggitt@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- WebMock causes errors in Net::HTTP::Persistent, disable except when needed
  (ccoleman@redhat.com)
- Support LIST_DOMAINS_BY_OWNER, SHOW_DOMAIN, and SHOW_APPLICATION_BY_DOMAIN
  (ccoleman@redhat.com)
- Support running broker tests directly Force scopes to use checked ids and
  avoid symbolizing arbitrary strings Use .present? instead of .count > 0 (for
  performance) Handle ValidationExceptions globally (ccoleman@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Correctly create custom apps (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- API version is not locked when using PUT/POST/DELETE due to only Content-Type
  being sent (ccoleman@redhat.com)
- Merge pull request #3095 from smarterclayton/custom_cart_test
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3111 from pravisankar/dev/ravi/bug983038
  (dmcphers+openshiftbot@redhat.com)
- Reset capybara between tests, restore cached cookies with correct domain
  (jliggitt@redhat.com)
- Remove ecdsa ssh key type from supported list. Rationale: Due to patent
  concerns, ECC support is not bundled in fedora/rhel(needed for ecdsa key
  generation).            So even if someone has a valid ecdsa keys, sshd
  server on our node won't be able to authenticate the user.
  (rpenta@redhat.com)
- Convert keys_controller - work around double deletion bug in console code
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Test custom cart creation (ccoleman@redhat.com)
- Merge pull request #3037 from Miciah/console-application_types-custom_types-
  fix (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3082 from smarterclayton/formtastic_cant_be_too_new
  (dmcphers+openshiftbot@redhat.com)
- Authorizations will not return specific id messages (ccoleman@redhat.com)
- Add test cases for not_found messages and behavior (ccoleman@redhat.com)
- Formtastic can't be newer than 1.2.x (ccoleman@redhat.com)
- Add test cases for not_found messages and behavior (ccoleman@redhat.com)
- Console: Make sure excluded_tags is set (miciah.masters@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
- Fix bug 983459 - typo in add ssh key text (jliggitt@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Fix bug 980953 - allow conversion tracking (jliggitt@redhat.com)
- Updates to allow basic tests to pass on F19 (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Merge pull request #2966 from sg00dwin/701dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2970 from liggitt/full_screenshot
  (dmcphers+openshiftbot@redhat.com)
- Take full screenshots when web tests fail (jliggitt@redhat.com)
- Link path correction (sgoodwin@redhat.com)
- Changes: (sgoodwin@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Fix testcase login to work with full test suite (jforrest@redhat.com)
- Bug 975365 - Change to direct mapping and update testcase
  (jforrest@redhat.com)
- Bug 975365 - Redirect old console routes to the new singular forms
  (jforrest@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Allow clients to pass an initial_git_url of "empty", which creates a bare
  repo but does not add a commit.  When 'empty' is passed, the node will skip
  starting the gear and also skip the initial build.  This allows clients that
  want to send a local Git repository (one that isn't visible to OpenShift.com,
  for example) to avoid having to push/merge/delete the initial commit, and
  instead submit their own clean repo.  In this case, the user will get a
  result indicating that their repository is empty. (ccoleman@redhat.com)
- Merge pull request #2922 from sg00dwin/624dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2919 from jwforres/bug_971337_cleanup_alias_form_errors
  (dmcphers+openshiftbot@redhat.com)
- Bug 970257 - Allow git@ urls (ccoleman@redhat.com)
- Correct img link (sgoodwin@redhat.com)
- Addition of touch image to console images and markup to support touch/favicon
  within console across browsers (sgoodwin@redhat.com)
- Bug 971337 - cleanup alias form errors (jforrest@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 1.10.5-1
- Merge pull request #2900 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- The console tabs are slightly misaligned (ccoleman@redhat.com)
- More assertions on app creation timeout tests (ffranz@redhat.com)
- Now redirecting to My Applications when app creation times out
  (ffranz@redhat.com)
- Handling nil exception message (ffranz@redhat.com)
- Proper timeout error message (ffranz@redhat.com)
- Bug 967504 - proper timeout (ffranz@redhat.com)
- Bug 967504 - tests (ffranz@redhat.com)
- Bug 967504 - handling timeout (ffranz@redhat.com)
- Bug 967504 - web console now properly handling app creation timeout
  (ffranz@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Merge branch 'master' of github.com:openshift/origin-server into 617dev
  (sgoodwin@redhat.com)
- Addition of defaul print specific css from latest bootstrap Updated entire
  _reset.scss - no impact expected (sgoodwin@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Merge pull request #2847 from liggitt/bug_974483_error_page_header
  (dmcphers+openshiftbot@redhat.com)
- Remove obsolete panda container from 404 pages (jliggitt@redhat.com)
- Fix bug 974483 - make header match openshift.com (jliggitt@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Add a proper check for rockmongo (dmcphers@redhat.com)
- Merge pull request #2856 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2852 from
  liggitt/bug_971328_app_create_missing_result_messages
  (dmcphers+openshiftbot@redhat.com)
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Fix bug 971328 - jenkins creation missing result messages
  (jliggitt@redhat.com)
- Merge pull request #2831 from smarterclayton/bug_972878_version_assets
  (dmcphers+openshiftbot@redhat.com)
- Use new routes (jliggitt@redhat.com)
- Add unit tests for message parsing, add reload support (jliggitt@redhat.com)
- Fix bug 971280 - make app restart message correct (jliggitt@redhat.com)
- Merge pull request #2509 from jwforres/route_id_clash
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2801 from smarterclayton/bug_970933_to_master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2832 from jwforres/bug_971147_allow_scaling_quickstart
  (dmcphers+openshiftbot@redhat.com)
- Fix mock test cases for the new routes used by the console
  (jforrest@redhat.com)
- Fix routing clashes when id matches new or edit (jforrest@redhat.com)
- Implement review feedback (jforrest@redhat.com)
- Bug 971147 - make not-scalable a recommendation (jforrest@redhat.com)
- js_required forces session cookie reset, wrong abstraction to use for
  noscript (ccoleman@redhat.com)
- Merge pull request #2824 from jwforres/bug_972877
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2825 from liggitt/user_guide_url
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2814 from jtharris/bugs/BZ971136
  (dmcphers+openshiftbot@redhat.com)
- Remove border and background color from checkboxes to fix IE10
  (jforrest@redhat.com)
- Fix checkbox on authorizations page to work with new styles
  (jforrest@redhat.com)
- Use community redirect for linking to the user guide (jliggitt@redhat.com)
- Bug 972877 - checkboxes are not correctly aligned (jforrest@redhat.com)
- Add test to validate REST API returning partially created results
  (ccoleman@redhat.com)
- Unit test for missing framework. (jharris@redhat.com)
- Add framework to the Application schema (jharris@redhat.com)
- Use -z with quotes (dmcphers@redhat.com)
- Bug 970933 - CLI backgrounds are incorrect (ccoleman@redhat.com)

* Fri Jun 07 2013 Adam Miller 1.10.1-5
- Bump spec for site rebuild

* Thu Jun 06 2013 Adam Miller 1.10.1-4
- Bump spec for site rebuild

* Wed Jun 05 2013 Adam Miller 1.10.1-3
- Bump spec for site rebuild

* Mon Jun 03 2013 Adam Miller 1.10.1-2
- Bump spec for 2.0.28.1 rebuild

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.10-1
- <openshift-console> Bug 968442 - Change verbiage of get_started page
  (jdetiber@redhat.com)
- Merge pull request #2619 from jtharris/email_blacklist
  (dmcphers+openshiftbot@redhat.com)
- Add prohibited email domain configuration. (jharris@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.9.9-1
- Merge pull request #2657 from smarterclayton/clear_carts_on_reload
  (dmcphers+openshiftbot@redhat.com)
- Clear cartridges when applications are reloaded, fix downloadable application
  test (ccoleman@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.8-1
- Merge pull request #2638 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2635 from
  liggitt/bug_966330_authorization_keys_responsive_layout
  (dmcphers+openshiftbot@redhat.com)
- fix some broken tests (rchopra@redhat.com)
- Fix bug 966330 - fix authorizations and ssh keys for responsive layouts
  (jliggitt@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- Tests don't pass (ccoleman@redhat.com)
- Additional tests of downloading cartridges (ccoleman@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- Merge pull request #2592 from smarterclayton/better_mail_config
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2598 from smarterclayton/prevent_unrescued_errors
  (dmcphers+openshiftbot@redhat.com)
- Review comments (ccoleman@redhat.com)
- Prevent unrescued errors in the console (ccoleman@redhat.com)
- Better mail config, allow SMTP to be set by ops (ccoleman@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- add required Build deps found because the Rails package got cleaned up
  (admiller@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- Merge pull request #2590 from smarterclayton/rescue_delivery_failures
  (dmcphers+openshiftbot@redhat.com)
- Rescue delivery failures gracefully with a global logger
  (ccoleman@redhat.com)
- Bug 961072 (jharris@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- 

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Merge pull request #2514 from jtharris/log_helper_move
  (dmcphers+openshiftbot@redhat.com)
- Moving log_helper into console (jharris@redhat.com)
- Safeguard against unexpected field name responses from the REST API, using
  sym to check (ffranz@redhat.com)
- Safeguard against unexpected field name responses from the REST API
  (ffranz@redhat.com)
- Bug 963156 (dmcphers@redhat.com)
- Merge pull request #2424 from smarterclayton/upgrade_to_mocha_0_13_3
  (admiller@redhat.com)
- Review comment - kill comments (ccoleman@redhat.com)
- Make scaling info easier to get at in UI (ccoleman@redhat.com)
- Card online_ui_278 - Log helper utility (jharris@redhat.com)
- Merge pull request #2435 from smarterclayton/allow_ci_reporter_to_be_optional
  (dmcphers+openshiftbot@redhat.com)
- ci_reporter is optional, not required (ccoleman@redhat.com)
- Merge pull request #2428 from
  smarterclayton/cart_spec_parsing_doesnt_handle_urls
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2427 from jwforres/Card227MenuHeaderDropdowns
  (dmcphers+openshiftbot@redhat.com)
- Cartridge spec parsing does not handle deserialized JSON hashes - a hash
  should be treated as a hard match, not a soft spec (ccoleman@redhat.com)
- Card 227 megamenu primary link dropdown - move bootstrap dropdown import
  (jforrest@redhat.com)
- Bug 961671 - Remove the community link from the header (ccoleman@redhat.com)
- Upgrade to mocha 0.13.3 (compatible with Rails 3.2.12) (ccoleman@redhat.com)
- Bug 961226 Update storage controller to reflect broker API change
  (hripps@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)
- Merge pull request #2399 from smarterclayton/allow_grids_to_be_pulled
  (dmcphers+openshiftbot@redhat.com)
- Allow spans to be pulled right responsively (ccoleman@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.10-1
- Merge pull request #2389 from liggitt/bug_959559_js_validation_errors
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 959559 - mark individual fields as having errors, limit js validation
  to onsubmit (jliggitt@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.9-1
- Merge pull request #2388 from detiber/bz959162
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2390 from ironcladlou/bz/958694
  (dmcphers+openshiftbot@redhat.com)
- Bug 958694: Make .state gear scoped and refactor primary cart concept
  (ironcladlou@gmail.com)
- Merge pull request #2377 from smarterclayton/fix_cart_messaging
  (dmcphers+openshiftbot@redhat.com)
- <console> Bug 959162 - Fix display issues (jdetiber@redhat.com)
- Merge pull request #2383 from smarterclayton/revert_a0a565ff_in_console
  (dmcphers+openshiftbot@redhat.com)
- Revert a0a565ff - changes need to go through styling review
  (ccoleman@redhat.com)
- Adjust the naming of downloaded cartridges to match decisions
  (ccoleman@redhat.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.8.8-1
- Merge pull request #2369 from liggitt/date_helper
  (dmcphers+openshiftbot@redhat.com)
- Add collapse_dates helper method (jliggitt@redhat.com)
- Merge pull request #2358 from detiber/bz959162
  (dmcphers+openshiftbot@redhat.com)
- <console> Bug 959162 - Fix display issues (jdetiber@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- Bug 959904 - DIY cartridge is not listed on the create app page
  (jforrest@redhat.com)
- Add authorization controller tests in console (ccoleman@redhat.com)
- Merge pull request #2331 from liggitt/cache_method
  (dmcphers+openshiftbot@redhat.com)
- Fix call to cache_key_for (jliggitt@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Merge pull request #2334 from smarterclayton/unify_footer_header_colors
  (dmcphers+openshiftbot@redhat.com)
- Make the H3 and A consistent in color in the footer (ccoleman@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Merge pull request #2319 from
  smarterclayton/rest_api_defends_against_bad_exceptions
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2320 from liggitt/bug_958278_segfault_on_int_assetss
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2232 from smarterclayton/support_external_cartridges
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 958278 - only insert asset middleware when static asset serving is
  enabled (jliggitt@redhat.com)
- Rename "external cartridge" to "downloaded cartridge".  UI should call them
  "personal" cartridges (ccoleman@redhat.com)
- RestApi should defend against poorly formed response bodies (it's possible
  for ActiveResource::ConnectionError#response to return a string)
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Read the enabled state of the external cartridges feature from the broker
  (ccoleman@redhat.com)
- Add custom cartridges to existing apps (ccoleman@redhat.com)
- Improve test performance by reusing cache for most tests
  (ccoleman@redhat.com)
- Support URL entry during app creation (ccoleman@redhat.com)
- Extract form-important from #new-application (ccoleman@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Add host name as an option for asset generation (ccoleman@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Merge pull request #2281 from smarterclayton/add_link_block
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2230 from pravisankar/dev/ravi/card559
  (dmcphers+openshiftbot@redhat.com)
- Add a link-block class (ccoleman@redhat.com)
- Removed 'setmaxstorage' option for oo-admin-ctl-user script. Added
  'setmaxtrackedstorage' and 'setmaxuntrackedstorage' options for oo-admin-ctl-
  user script. Updated oo-admin-ctl-user man page. Max allowed additional fs
  storage for user will be 'max_untracked_addtl_storage_per_gear' capability +
  'max_tracked_addtl_storage_per_gear' capability. Don't record usage for
  additional fs storage if it is less than
  'max_untracked_addtl_storage_per_gear' limit. Fixed unit tests and models to
  accommodate the above change. (rpenta@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2206 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- Fixed Maintenance mode message (ffranz@redhat.com)
- Fixed tests for Maintenance mode (ffranz@redhat.com)
- Using a dedicated exception to handle server unavailable so we don't have to
  check status codes more than once (ffranz@redhat.com)
- Handling a special ConnectionError so we can put the console in maintenance
  mode (ffranz@redhat.com)
- Maintenance mode, changed routing (ffranz@redhat.com)
- Tests for Maintenance mode (ffranz@redhat.com)
- Maintenance mode will now handle login/authorization properly
  (ffranz@redhat.com)
- Maintenance mode page, now handling nil responses on server error
  (ffranz@redhat.com)
- Maintenance mode for the web console (ffranz@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #2190 from smarterclayton/extract_form_important
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 951370 - update url for namespace user guide (jliggitt@redhat.com)
- Merge pull request #2200 from mmahut/master
  (dmcphers+openshiftbot@redhat.com)
- Extract form-important from #new-application (ccoleman@redhat.com)
- Fix find/delete command for openshift-console and console packages. Bug
  888714. (kraman@gmail.com)
- Merge pull request #2178 from smarterclayton/improve_memory_usage_of_rest_api
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2177 from smarterclayton/split_settings_page
  (dmcphers+openshiftbot@redhat.com)
- Improve console rest api memory usage by reducing copies
  (ccoleman@redhat.com)
- Send all settings interactions to the settings page, and fix tests.  Add a
  few more tests around the settings page, specifically for new key and new
  domain. (ccoleman@redhat.com)
- Split the settings page from the my account page (ccoleman@redhat.com)
- Using password field instead of plain text input for the certificate
  passphrase. (mmahut@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  separate_config_from_environments (ccoleman@redhat.com)
- Bug 888714 - Remove .gitkeep and .gitignore (ccoleman@redhat.com)
- Merge pull request #1770 from fotioslindiakos/plan_currency
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2112 from
  smarterclayton/bug_953177_keys_with_periods_cannot_be_deleted
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2089 from smarterclayton/add_web_integration_tests
  (dmcphers+openshiftbot@redhat.com)
- Bug 953177 - Keys with periods in their name cannot be deleted
  (ccoleman@redhat.com)
- Add a test case for configuration to ruby values (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  separate_config_from_environments (ccoleman@redhat.com)
- Merge pull request #2123 from smarterclayton/bug_953263_use_color_only_in_dev
  (dmcphers+openshiftbot@redhat.com)
- Rspec core should be in the test group (ccoleman@redhat.com)
- Bug 953263 - Use ANSI color codes only in development (ccoleman@redhat.com)
- Separate config from environments (ccoleman@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Add additional flexibility for running community tests (ccoleman@redhat.com)
- Add separators in the capybara log (ccoleman@redhat.com)
- Demonstrate web integration testing (ccoleman@redhat.com)
- Added :autocomplete option to inputs/input (fotios@redhat.com)

* Tue Apr 16 2013 Dan McPherson <dmcphers@redhat.com> 1.7.8-1
- Add buildrequires for new test packages (ccoleman@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.7-1
- Merge pull request #2087 from smarterclayton/move_to_minitest
  (dmcphers+openshiftbot@redhat.com)
- Move to minitest 3.5.0, webmock 1.8.11, and mocha 0.12.10
  (ccoleman@redhat.com)
- Fix bug 950866 - highlight errors in grouped fields correctly
  (jliggitt@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.6-1
- Bug 951367 (ffranz@redhat.com)
- Merge pull request #2025 from smarterclayton/origin_ui_37_error_page
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2014 from liggitt/accessibility
  (dmcphers+openshiftbot@redhat.com)
- Add a few base URLs and helpers for fetching assets during static page
  compilation (ccoleman@redhat.com)
- Merge pull request #1996 from
  smarterclayton/bug_950367_use_default_for_bad_expires_in
  (dmcphers+openshiftbot@redhat.com)
- Add form labels (jliggitt@redhat.com)
- Bug 950367 - Handle non-integer values for expires_in (ccoleman@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- Merge pull request #1995 from smarterclayton/tweaks_to_quickstarts
  (dmcphers@redhat.com)
- Add social sharing links (ccoleman@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Merge pull request #1992 from smarterclayton/fix_account_settings_breadcrumb
  (dmcphers+openshiftbot@redhat.com)
- Fix account settings breadcrumb to point to the correct URL
  (ccoleman@redhat.com)
- Merge pull request #1969 from liggitt/currency_display (dmcphers@redhat.com)
- Separate currency symbol into helper method (jliggitt@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #1944 from sg00dwin/408dev (dmcphers@redhat.com)
- Changes for: (sgoodwin@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Changes to apply the correct the default input.btn:focus background color in
  the console. (sgoodwin@redhat.com)
- Bug 917492 - The error message overlapped with the original content in
  scaling page of jbosseap apps on Iphone4S (sgoodwin@redhat.com)
- Changes: (sgoodwin@redhat.com)
- Bug 947098 fix - add margin to h3 so icon doesn't overlap at narrow
  resolutions (sgoodwin@redhat.com)
- Moving openshift-icon to a partial and including in common so that mixin can
  be applied Created a mixin for text-overflow .truncate and used with aliases
  list Created markup for header button usage of add/create function Switched
  individual application page from using sprite images to icon font Swiched
  application list to use right arrow icon instead of sprite Removed bottom
  positioning of icons with h1,h2 b/c when used with truncate the
  overflow:hidden cut the tops off. A couple of variables added for colors
  (sgoodwin@redhat.com)
- Merge pull request #1843 from smarterclayton/bug_928669_load_error_in_async
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1845 from sg00dwin/0325dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 928669 - Async errors in development mode (ccoleman@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into 0325dev
  (sgoodwin@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into 0325dev
  (sgoodwin@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into 0325dev
  (sgoodwin@redhat.com)
- Fix for Bug 927208 Multiple edits needed because of the issues involved with
  the problem of styling input[type="file"] that are also disabled. In a
  nutshell, it's nearly impossible to present input type=file in a consistant
  manner across browsers platforms. Further complicated by the way Firefox
  handles those inputs when disabled - text and background-color are given
  opacity and inherit the parent background color which caused the text to be
  unreadable on our dark background. So created the .platform class, which is
  inverse of well. (sgoodwin@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- Minor wording and styling bug fixes, improved tests for SSL certificates
  (ffranz@redhat.com)
- Minor visual tweaks on the web console, alias list (ffranz@redhat.com)
- Merge pull request #1813 from fotioslindiakos/BZ922689 (dmcphers@redhat.com)
- Merge pull request #1812 from liggitt/invoice_styles (dmcphers@redhat.com)
- Fix for not showing proper cartridge errors (fotios@redhat.com)
- Add placeholder styles for usage graph types (jliggitt@redhat.com)
- Bug 923746 - Tax exempt link should point to public page
  (ccoleman@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1785 from sg00dwin/0325dev
  (dmcphers+openshiftbot@redhat.com)
- switch to existing variable (sgoodwin@redhat.com)
- Bug 921453 fix - webkit rendering of multi gylph icons needs top:0
  (sgoodwin@redhat.com)
- Make console alert link color $linkColorBlue since it's on a lighter
  background, with exception for alert-error. (sgoodwin@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Review comments - missed search page, needed to reintroduce link to
  quickstart page (ccoleman@redhat.com)
- Clean up premium cart indicators (ccoleman@redhat.com)
- Add provider data to the UI that is exposed by the server
  (ccoleman@redhat.com)
- Add icon to app config page (sgoodwin@redhat.com)
- Addition of icon denotion for cartridge or quickstart on application creation
  step (sgoodwin@redhat.com)
- add usage rules for alert headings w/ icons (sgoodwin@redhat.com)
- Merge pull request #1762 from fabianofranz/dev/ffranz/ssl
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1763 from smarterclayton/aria_dashboard
  (dmcphers+openshiftbot@redhat.com)
- Web console now using api v. 1.4 (ffranz@redhat.com)
- Card #239: Added support to alias creation and deletion and SSL certificate
  upload to the web console (ffranz@redhat.com)
- Fix test failures (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into aria_dashboard
  (ccoleman@redhat.com)
- Merge branch 'aria_dashboard' of github.com:smarterclayton/origin-server into
  aria_dashboard (ccoleman@redhat.com)
- Reformat resource_not_found checking (jliggitt@redhat.com)
- Don't assume exceptions have a model (jliggitt@redhat.com)
- Add billing_date_no_year (jliggitt@redhat.com)
- Tweak graph line height, style table captions (jliggitt@redhat.com)
- Remove extraneous pry (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into aria_dashboard
  (ccoleman@redhat.com)
- Update tests (ccoleman@redhat.com)
- Support cache config (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into aria_dashboard
  (ccoleman@redhat.com)
- Fixing test cases (ccoleman@redhat.com)
- Support redirection back to the settings page (ccoleman@redhat.com)
- Use credit card format closer to card value (ccoleman@redhat.com)
- Cache that the user has no keys (ccoleman@redhat.com)
- Creating an authorization should take the user to the show page for the token
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into aria_dashboard
  (ccoleman@redhat.com)
- Merge with master, _account moved to origin-server (ccoleman@redhat.com)
- Add a stack overflow link helper (ccoleman@redhat.com)
- Updated date helpers (ccoleman@redhat.com)
- Initial work (ccoleman@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Merge pull request #1678 from smarterclayton/minor_object_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Small cleanups in prep for future refactors (remove eigenclasses, no
  require_dependency) (ccoleman@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Pry console won't start in console app (ccoleman@redhat.com)
- Merge pull request #1668 from smarterclayton/wrong_quickstart_default
  (dmcphers+openshiftbot@redhat.com)
- Site should not default to community URL for quickstarts if not specified
  (ccoleman@redhat.com)
- Support cache config (ccoleman@redhat.com)
- Merge pull request #1650 from sg00dwin/various-work
  (dmcphers+openshiftbot@redhat.com)
- Replace search and caret with icon-font (sgoodwin@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Merge pull request #1636 from tdawson/tdawson/fix-f19-builds
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1590 from jtharris/features/US2627
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1634 from smarterclayton/add_pry_console
  (dmcphers+openshiftbot@redhat.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- Add Pry as a console option - use 'PRY=1 rails c' (ccoleman@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into misc-dev
  (sgoodwin@redhat.com)
- adding empty mixin account_background in
  console/app/assets/stylesheets/console/_mixins.scss (sgoodwin@redhat.com)
- COMMUNITY_URL must end with '/' (jharris@redhat.com)
- No default proxy setting for quickstarts. (jharris@redhat.com)
- moved from li to console for inclusion in origin.css (sgoodwin@redhat.com)
- usage_rates? unit tests (jharris@redhat.com)
- Default to empty array for usage_rates (jharris@redhat.com)
- include .wrap rule which was lost previously (sgoodwin@redhat.com)
- heading color rules needed again since _type is shared (sgoodwin@redhat.com)
- Revert to one _type partial for site and console Regen updated icon-font
  files (sgoodwin@redhat.com)
- Bug 918339 - Remove unnecessary lambda and conditionalize at_exit
  registration. (hripps@redhat.com)
- need font-url instead of url (sgoodwin@redhat.com)
- add license that missing (sgoodwin@redhat.com)
- Additional icons included to font (sgoodwin@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into misc-dev
  (sgoodwin@redhat.com)
- Put focus on advanced field when shown (jliggitt@redhat.com)
- Merge pull request #1589 from liggitt/bug/919520
  (dmcphers+openshiftbot@redhat.com)
- Fixing alert heading color. (jharris@redhat.com)
- Pulling out app/cart titles and notifications. (jharris@redhat.com)
- Merge pull request #1544 from fotioslindiakos/BZ909060
  (dmcphers+openshiftbot@redhat.com)
- remove heading style b/c it was overriding .alert-header rule
  (sgoodwin@redhat.com)
- remove adjacent h2 + p rule and will handle one offs independently
  (sgoodwin@redhat.com)
- Fix Bug 919520 Changing application creation page to advanced view with
  errors shown returns to main applications page (jliggitt@redhat.com)
- Merge pull request #1580 from liggitt/aria_landmarks
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into misc-dev
  (sgoodwin@redhat.com)
- Bug 909060 - Corrected forms to use proper semantic_errors
  https://bugzilla.redhat.com/show_bug.cgi?id=909060 (fotios@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into misc-dev
  (sgoodwin@redhat.com)
- Move to separate _type partials for console and site for better control of
  headers and typography  - fine tune for console Modify add cartidge heading
  to fix small spacing issue Add _account to origin.css (sgoodwin@redhat.com)
- Scope table cell and row headers, add role=main landmarks, add 'Skip to
  content' links (jliggitt@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.13-1
- Bug 918867 (jharris@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- Merge pull request #1569 from smarterclayton/fix_default_config_url
  (dmcphers@redhat.com)
- COMMUNITY_URL should end in slash by default (ccoleman@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- Move REST API cartridge test to misc1 group (pmorie@gmail.com)
- Merge pull request #1554 from
  smarterclayton/bug_902181_should_wrap_domain_element
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1556 from smarterclayton/bug_885954_wrap_links_on_webkit
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1558 from liggitt/alt_text (dmcphers@redhat.com)
- Bug 885954 - Wrap links on WebKit (needs word-break) (ccoleman@redhat.com)
- Add alt text to all images (jliggitt@redhat.com)
- Bug 902181 - Should wrap domain input element where possible
  (ccoleman@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Merge branch 'master' of github.com:openshift/origin-server into icon-changes
  (sgoodwin@redhat.com)
- Merge pull request #1539 from jtharris/bugs/BZ902118 (dmcphers@redhat.com)
- Merge pull request #1534 from
  liggitt/bug_912010_cartridge_filter_empty_results (dmcphers@redhat.com)
- Merge pull request #1533 from
  smarterclayton/bug_916495_relative_urls_in_community_still
  (dmcphers@redhat.com)
- Bug 902118 - Removing generated hidden form fields (jharris@redhat.com)
- - first glyph gets position: relative - other glyph(s) get position: absolute
  and left:0 (sgoodwin@redhat.com)
- Move test case into rest_api_test.rb (jliggitt@redhat.com)
- Bug 916495 - Community still points incorrectly to some incorrect URLs
  (ccoleman@redhat.com)
- Bug 912010 - Make the 'cartridge' tag match all cartridges
  (jliggitt@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Fix for Bug 912194 - The "the User Guide" link on my account page is broken
  (sgoodwin@redhat.com)
- Merge pull request #1479 from sg00dwin/iconfont
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1433 from fotioslindiakos/plan_upgrade
  (dmcphers+openshiftbot@redhat.com)
- rename of file (sgoodwin@redhat.com)
- Added opts to pricing for anchors (fotios@redhat.com)
- Move fonts from li to openshift-server apply margin to class that controls
  :before positioned fonts for offset (sgoodwin@redhat.com)
- remove margin because it needs to only be for icons set using their class
  name (sgoodwin@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server into iconfont
  (sgoodwin@redhat.com)
- Replace the following sprite images with icon font - Restart - Search
  (sgoodwin@redhat.com)
- Include iconfont in common.css (sgoodwin@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Merge pull request #1483 from
  smarterclayton/bug_915527_session_caps_not_cleared (dmcphers@redhat.com)
- Bug 915527 - Session capabilities not cleared when domain/app changed
  (ccoleman@redhat.com)
- Bug 916311 - Expired tokens should be hidden (ccoleman@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- Merge pull request #1447 from smarterclayton/community_url_not_available
  (dmcphers+openshiftbot@redhat.com)
- Implement authorization support in the broker (ccoleman@redhat.com)
- The community URL is not available for some operations - use the default
  config if that is true (ccoleman@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Merge pull request #1443 from
  smarterclayton/bug_913816_work_around_bad_logtailer
  (dmcphers+openshiftbot@redhat.com)
- Bug 913816 - Fix log tailer to pick up the correct config
  (ccoleman@redhat.com)
- Asset pages need CommunityAware, reorder suites slightly
  (ccoleman@redhat.com)
- Integrate Justin's community URL changes with the new site split changes
  (ccoleman@redhat.com)
- Merge pull request #1421 from jtharris/community (ccoleman@redhat.com)
- Adding community url to config. (jharris@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.5-2
- bump for chainbuild

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Merge pull request #1419 from smarterclayton/console_should_send_api_version
  (dmcphers+openshiftbot@redhat.com)
- The console should send a locked API version (ccoleman@redhat.com)
- Relaxing restrictions on ssh key names (abhgupta@redhat.com)
- fix rubygem sources (tdawson@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.4-2
- bump for chainbuild

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- bump spec for chain build (admiller@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> - 1.5.3-3
- Bump spec for chainbuild

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-2
- bump for chainbuild

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Fixes for ruby193 (john@ibiblio.org)
- Merge pull request #1372 from
  smarterclayton/bug_907647_remove_calls_to_extend
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1368 from smarterclayton/bug_908546_restrict_cart_types
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1361 from
  smarterclayton/bug_908607_fix_app_overview_in_devenv
  (dmcphers+openshiftbot@redhat.com)
- Remove test case usage of Object#extend (ccoleman@redhat.com)
- Properly deserialize nested cartridges when a relation exists and no method
  setter (ccoleman@redhat.com)
- Merge pull request #1290 from Coolhand/dev/niharvey/bug/903733
  (dmcphers+openshiftbot@redhat.com)
- Bug 908546 - Disallow injected cart values (ccoleman@redhat.com)
- Bug 908607 - Make application overview page faster (ccoleman@redhat.com)
- Revert "Moved async_aware into the models" (ccoleman@redhat.com)
- altered the messaging to reflect the suggestions given.
  (nickharveyonline@gmail.com)
- missed trailing backslash (admiller@redhat.com)
- move logs to a more standard location (admiller@redhat.com)

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

