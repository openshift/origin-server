%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global v8_scl v8314
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-console
%global rubyabi 1.9.1

Summary:       OpenShift Origin Management Console
Name:          rubygem-%{gem_name}
Version: 1.35.4
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
Requires:      %{?scl:%scl_prefix}rubygem(coffee-rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(formtastic)
Requires:      %{?scl:%scl_prefix}rubygem(haml)
Requires:      %{?scl:%scl_prefix}rubygem(jquery-rails)
# Bz1017671
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(net-http-persistent)
Requires:      %{?scl:%scl_prefix}rubygem(rails)
Requires:      %{?scl:%scl_prefix}rubygem(rdiscount)
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(sass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)
Requires:      %{?scl:%scl_prefix}rubygem(uglifier)
Requires:      %{?scl:%scl_prefix}rubygem(syslog-logger)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
BuildRequires:  v8314
%endif

BuildRequires: %{?scl:%scl_prefix}rubygem(coffee-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(compass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(formtastic)
BuildRequires: %{?scl:%scl_prefix}rubygem(haml)
BuildRequires: %{?scl:%scl_prefix}rubygem(jquery-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(minitest)
BuildRequires: %{?scl:%scl_prefix}rubygem(net-http-persistent)
BuildRequires: %{?scl:%scl_prefix}rubygem(rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(rdiscount)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)
BuildRequires: %{?scl:%scl_prefix}rubygem(sprockets)
BuildRequires: %{?scl:%scl_prefix}rubygem(therubyracer)
BuildRequires: %{?scl:%scl_prefix}rubygem(uglifier)
BuildRequires: %{?scl:%scl_prefix}rubygem(syslog-logger)


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
%{?scl:scl enable %scl %v8_scl - << \EOF}

set -e
mkdir -p .%{gem_dir}

%if 0%{?fedora}%{?rhel} <= 6
rm -f Gemfile.lock

# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' Gemfile

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

%if 0%{?scl:1}
mkdir -p %{buildroot}%{_root_sbindir}
cp -p bin/oo-* %{buildroot}%{_root_sbindir}/
mkdir -p %{buildroot}%{_root_mandir}/man8/
cp bin/man/*.8 %{buildroot}%{_root_mandir}/man8/
%else
mkdir -p %{buildroot}%{_sbindir}
cp -p bin/oo-* %{buildroot}%{_sbindir}/
mkdir -p %{buildroot}%{_mandir}/man8/
cp bin/man/*.8 %{buildroot}%{_mandir}/man8/
%endif

%files
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/COPYRIGHT
%{gem_instdir}
%{gem_cache}
%{gem_spec}

%if 0%{?scl:1}
%attr(0750,-,-) %{_root_sbindir}/oo-admin-console-cache
%{_root_mandir}/man8/oo-admin-console-cache.8.gz
%else
%attr(0750,-,-) %{_sbindir}/oo-admin-console-cache
%{_mandir}/man8/oo-admin-console-cache.8.gz
%endif

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.35.4-1
- Merge pull request #6236 from Miciah/make-console-functional-tests-less-
  random (dmcphers+openshiftbot@redhat.com)
- Whitelist quickstarts in console functional test (miciah.masters@gmail.com)

* Thu Sep 17 2015 Stefanie Forrester <sedgar@redhat.com> 1.35.3-1
- Version bump for build errors (sedgar@redhat.com)
- Fix render error (jliggitt@redhat.com)
- Updates web analytics for web console (jacoblucky@gmail.com)

* Thu Sep 17 2015 Stefanie Forrester <sedgar@redhat.com>
- Fix render error (jliggitt@redhat.com)
- Updates web analytics for web console (jacoblucky@gmail.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.35.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.34.2-1
- Specify addition rubygems in the openshift-console, rathen than the admin-
  console (tiwillia@redhat.com)
- Specify additional gems to be loaded in the broker and console
  (tiwillia@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.34.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.33.2-1
- Updates Community QuickStarts URL (jacoblucky@gmail.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Bug 1170021 - quota warning not displayed after cartridge add in the web
  console (jforrest@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- Merge pull request #5913 from liggitt/site_extended_fixes
  (dmcphers+openshiftbot@redhat.com)
- Use TLS for integration tests (jliggitt@redhat.com)
- Bug 1156374 - domain admin member must be able to see domain teams
  (contact@fabianofranz.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.31.7-1
- Merge pull request #5870 from fabianofranz/bugs/1151548
  (dmcphers+openshiftbot@redhat.com)
- Bug 1151548 - adding cartridge must send supported gear size
  (contact@fabianofranz.com)

* Mon Oct 13 2014 Adam Miller <admiller@redhat.com> 1.31.6-1
- Fixes indendation issue in coffeescript (contact@fabianofranz.com)

* Thu Oct 09 2014 Adam Miller <admiller@redhat.com> 1.31.5-1
- Merge pull request #5857 from fabianofranz/bugs/1149901
  (dmcphers+openshiftbot@redhat.com)
- Bug 1149901 - add missing line break to certificate files
  (contact@fabianofranz.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.31.4-1
- Merge pull request #5823 from tiwillia/bz1144175
  (dmcphers+openshiftbot@redhat.com)
- Replaced missing underscore in config_accessor (tiwillia@redhat.com)
- Refined validity check to properly check strings and integers
  (tiwillia@redhat.com)
- Fixed typo in regex (tiwillia@redhat.com)
- Fixed digit regex check and added sanity check to ensure timeout is not 0
  Updated call in console/app/controllers/settings_controller.rb to also use
  the configured timeout (tiwillia@redhat.com)
- Bug 1144175 Bugzilla link https://bugzilla.redhat.com/show_bug.cgi?id=1144175
  Added a configuration option for a timeout where the console waits for
  several background requests to the broker. (tiwillia@redhat.com)

* Wed Sep 24 2014 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bug 1146108 - display unique name on cartridge if there is another cart with
  the same display name (jforrest@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.31.2-1
- Merge pull request #5830 from jwforres/bug_1144950_alias_cert_errors
  (dmcphers+openshiftbot@redhat.com)
- Bug 1144950 - Show server-side errors for bad certs (jforrest@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- Use domain max_gears when displaying app scaling limits (jliggitt@redhat.com)
- Changes first_steps links to developer portal (spurtell@redhat.com)

* Mon Sep 08 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- add build dep for RHEL6 to pull in RHSCL 1.1 v8314 (admiller@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Merge pull request #5779 from liggitt/logout_link_example
  (dmcphers+openshiftbot@redhat.com)
- LOGOUT_LINK example (jliggitt@redhat.com)
- Add logout logic (jliggitt@redhat.com)
- Merge pull request #5715 from detiber/sclbuildfixes
  (dmcphers+openshiftbot@redhat.com)
- scl build fixes (jdetiber@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)
- Bug 1131967 - fixes validation of gear sizes on quickstarts page
  (contact@fabianofranz.com)

* Tue Aug 19 2014 Adam Miller <admiller@redhat.com> 1.29.5-1
- [origin-ui-192] Adjustments according to feedback (contact@fabianofranz.com)
- [origin-ui-192] Handle cartridges restricted by gear size
  (contact@fabianofranz.com)

* Fri Aug 15 2014 Troy Dawson <tdawson@redhat.com> 1.29.4-1
- Merge pull request #5714 from
  jcantrill/207_hide_regions_when_user_not_allowed
  (dmcphers+openshiftbot@redhat.com)
- [Origin UI 207] Show region selection only if user is allowed
  (jcantril@redhat.com)

* Thu Aug 14 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- [Origin UI 194] Add description support to app create page and refactor to
  use radio buttons (jcantril@redhat.com)

* Wed Aug 13 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Show sub-cent rates (jliggitt@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Allow customizing the content-type and accept headers for oauth calls
  (jforrest@redhat.com)

* Mon Jul 28 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Origin UI 190 - Expose region for app create and show, region and zone on
  gear page for admin-console (jcantril@redhat.com)

* Wed Jul 23 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Allow for 2-leg oauth where there is no token or token_secret
  (jforrest@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- Update Rest API Integration test for ruby-2.0 cartridge (j.hadvig@gmail.com)
- OAuth - should be able to specify what HTTP method is being used when signing
  a request (jforrest@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Mon Jul 07 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Merge pull request #5566 from soltysh/card224
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_224 - Upgrading nodejs quickstarts to version 0.10
  (maszulik@redhat.com)

* Thu Jul 03 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Merge pull request #5565 from developercorey/add-stack-url
  (dmcphers+openshiftbot@redhat.com)
- removing forum link and replacing with stackoverflow url, and updating
  newsletter text (cdaley@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Fix bug 1111009: Typo on app scaling page (jliggitt@redhat.com)

* Tue Jun 17 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Merge pull request #5510 from developercorey/fix_delete_application_namespace
  (dmcphers+openshiftbot@redhat.com)
- Replacing the short app name on the delete application page with the full
  application url to help negate confusion when deleting applications when you
  have access to multiple domains.  Similar to how github does it when you
  delete a repository, they show the user or organization name plus the repo
  name.  if this format is not appropriate, let me know what format would make
  more sense maybe domain/app_name? (cdaley@redhat.com)
- https://bugzilla.redhat.com/show_bug.cgi?id=1109026 (bparees@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- console_helper.rb:   - replace hard-coded value of product logo and product
  title by     dynamic value from Console.config.env console.conf:   - add
  PRODUCT_LOGO and PRODUCT_TITLE parameters (thierry@tfserver.no-ip.org)
- Merge pull request #5453 from pivanov/css-small-fix
  (dmcphers+openshiftbot@redhat.com)
- Add a section to inject information about external cartridges
  (jforrest@redhat.com)
- Comment test_in_groups_by_tag (miciah.masters@gmail.com)
- model_helper_tests.rb: Add test for bug 1100508 (miciah.masters@gmail.com)
- Console: Improve grouping of application types (miciah.masters@gmail.com)
- bump_minor_versions for sprint 46 (admiller@redhat.com)
- [stylesheets] - remove unit after 0 length. (pivanov@mozilla.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.4-1
- Revert "Updating file paths from blogs to blog" (shalompisteuo@gmail.com)

* Fri May 23 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Merge pull request #5359 from worldline/improving_config_files
  (dmcphers+openshiftbot@redhat.com)
- adding console community helper parameters in /etc/openshift/console.conf
  (thierry.forli@worldline.com)

* Wed May 21 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Merge pull request #5430 from liggitt/improve_team_creation
  (dmcphers+openshiftbot@redhat.com)
- Add create link when no team matches are found (jliggitt@redhat.com)
- Merge pull request #5428 from ShalomPisteuo/bug_1065154
  (dmcphers+openshiftbot@redhat.com)
- Updating file paths from blogs to blog (shalompisteuo@gmail.com)
- Test JSON endpoints for typeahead (jliggitt@redhat.com)
- Remove Typo (jliggitt@redhat.com)
- Bug 1098903: Fix team name truncation (jliggitt@redhat.com)
- Add Team management UI (jliggitt@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- Bug 1092066: Prevent javascript links in cartridges (jliggitt@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.5-1
- Bug 1090984 - reduces the max size of flash messages
  (contact@fabianofranz.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Update API version to 1.7 (jliggitt@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Fix call to gear_increase_indicator (jliggitt@redhat.com)
- Add plan attributes (jliggitt@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Bug 1086920: Check ssl certificate capability on domain, not on user
  (jliggitt@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Merge pull request #5246 from liggitt/bug_1086567_handle_implicit_leaving
  (dmcphers+openshiftbot@redhat.com)
- Fix test case trying to remove owner (jliggitt@redhat.com)
- Bug 1086567: Handle implicit members leaving (jliggitt@redhat.com)
- Bug 1086716: Update jquery syntax for live-clicking (jliggitt@redhat.com)
- Downloadable cartridges are improperly described as getting updates
  (bparees@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5211 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5209 from sg00dwin/cart-icon-fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5175 from liggitt/teams_ui
  (dmcphers+openshiftbot@redhat.com)
- Fixing urls (dmcphers@redhat.com)
- Switch old cartridge icon to new icon (sgoodwin@redhat.com)
- Update capability test (jliggitt@redhat.com)
- Remove unused routes, use configured model class (jliggitt@redhat.com)
- Simplify role rendering (jliggitt@redhat.com)
- Use box-sizing mixin (jliggitt@redhat.com)
- Update jquery, add typeahead widget (jliggitt@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Merge remote-tracking branch 'upstream/master' (sgoodwin@redhat.com)
- Fixes related to bug 1062499 console/help and console/app/create search field
  css (sgoodwin@redhat.com)
- Allow version of jQuery newer than 2.0 (jliggitt@redhat.com)
- Add comment, test for team member details (jliggitt@redhat.com)
- Add functional tests for domain member rendering (jliggitt@redhat.com)
- Handle implicit members and team members on domain page (jliggitt@redhat.com)
- Bug 1081869 - Console needs a oo-admin-console-cache command. Remove the
  --console flag from the oo-admin-broker-cache command. (jforrest@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.6-1
- [origin-dev-ui-162] surface more information in the UI for external
  cartridges (contact@fabianofranz.com)
- Merge pull request #5044 from liggitt/external_nav_links
  (dmcphers+openshiftbot@redhat.com)
- Allow nav links to be external, pull cartridge link into helper method
  (jliggitt@redhat.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Chmod +x site scripts (jliggitt@redhat.com)
- Add console oauth controller test (jliggitt@redhat.com)
- Console oauth controller (jliggitt@redhat.com)
- SSO OAuth support (jliggitt@redhat.com)
- Merge branch 'master' into origin-footer-bug (sgoodwin@redhat.com)
- Remove old style that's no longer needed and caused links in origin footer to
  display incorrectly (sgoodwin@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Adds the xPaaS section to the app creation page in the web console
  (contact@fabianofranz.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #4979 from sg00dwin/external-cart
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4929 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Teams API (lnader@redhat.com)
- Use unique name for user with downloaded app (jliggitt@redhat.com)
- Merge branch 'master' into external-cart (sgoodwin@redhat.com)
- Addition of updated cartridge and external cartridge icons
  (sgoodwin@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Merge pull request #4955 from fabianofranz/dev/163
  (dmcphers+openshiftbot@redhat.com)
- [origin-server-ui-163] Adding support to query apps owned by the user
  (contact@fabianofranz.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Merge pull request #4897 from fabianofranz/dev/155b
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)
- Web console: improves error details on non-recoverable errors (e.g. http 422,
  etc) (contact@fabianofranz.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Merge pull request #4891 from ShalomPisteuo/appLoginCSS
  (dmcphers+openshiftbot@redhat.com)
- Altering .css styling for the new help-block (shalompisteuo@gmail.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Bug 1072185 - should not collapse message details when bound to a form input
  (contact@fabianofranz.com)
- Bug 1071819: Fix storage dropdown overflow (jliggitt@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Merge pull request #4852 from sg00dwin/disabed-buttons-fix
  (dmcphers+openshiftbot@redhat.com)
- Bug 1070068 - fixes some search forms to the new site search engine
  (contact@fabianofranz.com)
- Merge pull request #4684 from liggitt/domain_capabilities
  (dmcphers+openshiftbot@redhat.com)
- Fix for disabled button states Fix for bug 1050796 incorrect drupal
  quickstart link in console/help page (sgoodwin@redhat.com)
- Fix up rates incorrectly rounded to bash.00 (jliggitt@redhat.com)
- Surface owner storage capabilities and storage rates (jliggitt@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- Bug 1066945 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4760 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- Fixes site_extended tests (contact@fabianofranz.com)
- Activate obsolete cartridges in devenv (ccoleman@redhat.com)
- Merge pull request #4674 from fabianofranz/dev/155
  (dmcphers+openshiftbot@redhat.com)
- [origin-ui-155] Improves error and debug messages on the REST API and web
  console (contact@fabianofranz.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4739 from fabianofranz/bugs/1063470
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063470 - handle different encodings in files provided by ssl cert
  issuers (contact@fabianofranz.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4718 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4708 from smarterclayton/bug_1063109_trim_required_carts
  (dmcphers+openshiftbot@redhat.com)
- Obsoleted zend-5.6 cartridge (lnader@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063109 - Required carts should be handled higher in the model
  (ccoleman@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Support changing categorizations (ccoleman@redhat.com)
- UI uses "requires" value from broker (ccoleman@redhat.com)
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4649 from ncdc/dev/rails-syslog
  (dmcphers+openshiftbot@redhat.com)
- Add/correct syslog-logger in Gemfiles (andy.goldstein@gmail.com)
- Merge pull request #4602 from jhadvig/mongo_update
  (dmcphers+openshiftbot@redhat.com)
- Add optional syslog support to Rails apps (andy.goldstein@gmail.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Merge pull request #4594 from smarterclayton/tolerate_custom_carts_in_broker
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Tolerate custom cartridges in the broker in the console (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.16-1
- Adding back zend-5.6 until bug 1054654 is fixed (lnader@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.15-1
- Merge pull request #4570 from
  liggitt/bug_1055906_downloadable_cartridge_scheme (ccoleman@redhat.com)
- Fix bug 1055906: Add http:// to cartridge url if no scheme provided
  (jliggitt@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.14-1
- bump console Release to test build scripts for chainbuild case
  (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.13-1
- bump console Release to test build scripts for chainbuild case
  (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Merge pull request #4557 from liggitt/bug_1056441_member_error_color
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1056441: Member add message color (jliggitt@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Bug 1056349 (dmcphers@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Merge pull request #4520 from smarterclayton/update_custom_cart_error
  (dmcphers+openshiftbot@redhat.com)
- Test case for custom cart failure is checking a nonexistent message
  (ccoleman@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Fix bug 1054692: avoid currency symbol wrapping (jliggitt@redhat.com)
- Add an additional failing test for cart output (ccoleman@redhat.com)
- Hide small app type icon in origin Minor haml change Reverting back to use
  usage_rate_indicator Added mixin to adjust $ sign size to match related group
  icon size (sgoodwin@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4496 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051203 (dmcphers@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4492 from VojtechVitek/obsolete_zend-5.6
  (dmcphers+openshiftbot@redhat.com)
- remove zend-5.6 rest_api tests (vvitek@redhat.com)
- For bug 1045566 Updates to the display of app meta data using icon/text so
  the user knows: if an app is a cartridge or quickstart if it's OpenShift
  maintained and receives automatic security updates or if it's partner,
  community created (sgoodwin@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Bug 1045559 - Show featured apps at the top of their app category
  (jforrest@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.5-1
- Fix bug 1048992: Define remote_request? in console controller
  (jliggitt@redhat.com)
- Bug 1045971 - add alias display overlaps on iphone 4S (jforrest@redhat.com)
- Merge pull request #4398 from bparees/rename_jee
  (dmcphers+openshiftbot@redhat.com)
- Bug 1047920 - application edit route should not be enabled
  (jforrest@redhat.com)
- rename jee to java_ee_6 (bparees@redhat.com)

