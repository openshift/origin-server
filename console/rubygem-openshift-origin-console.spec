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
Version: 1.8.0
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
Requires:      %{?scl:%scl_prefix}rubygem(poltergeist)
Requires:      %{?scl:%scl_prefix}rubygem(konacha)
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(rspec-core)

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
BuildRequires: %{?scl:%scl_prefix}rubygem(poltergeist)
BuildRequires: %{?scl:%scl_prefix}rubygem(konacha)
BuildRequires: %{?scl:%scl_prefix}rubygem(minitest)
BuildRequires: %{?scl:%scl_prefix}rubygem(rspec-core)

%endif
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

