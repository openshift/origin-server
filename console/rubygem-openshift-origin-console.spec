%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-console
%global rubyabi 1.9.1

Summary:        OpenShift Origin Management Console
Name:           rubygem-%{gem_name}
Version:        0.0.12
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            https://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(rails)
Requires:       %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:       %{?scl:%scl_prefix}rubygem(rdiscount)
Requires:       %{?scl:%scl_prefix}rubygem(formtastic)
Requires:       %{?scl:%scl_prefix}rubygem(net-http-persistent)
Requires:       %{?scl:%scl_prefix}rubygem(haml)
Requires:       %{?scl:%scl_prefix}rubygem(ci_reporter)
Requires:       %{?scl:%scl_prefix}rubygem(coffee-rails)
Requires:       %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:       %{?scl:%scl_prefix}rubygem(jquery-rails)
Requires:       %{?scl:%scl_prefix}rubygem(mocha)
Requires:       %{?scl:%scl_prefix}rubygem(sass-rails)
Requires:       %{?scl:%scl_prefix}rubygem(simplecov)
Requires:       %{?scl:%scl_prefix}rubygem(test-unit)
Requires:       %{?scl:%scl_prefix}rubygem(uglifier)
Requires:       %{?scl:%scl_prefix}rubygem(webmock)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif

BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildRequires:  %{?scl:%scl_prefix}rubygem(rails)
BuildRequires:  %{?scl:%scl_prefix}rubygem(compass-rails)
BuildRequires:  %{?scl:%scl_prefix}rubygem(mocha)
BuildRequires:  %{?scl:%scl_prefix}rubygem(simplecov)
BuildRequires:  %{?scl:%scl_prefix}rubygem(test-unit)
BuildRequires:  %{?scl:%scl_prefix}rubygem(ci_reporter)
BuildRequires:  %{?scl:%scl_prefix}rubygem(webmock)
BuildRequires:  %{?scl:%scl_prefix}rubygem(sprockets)
BuildRequires:  %{?scl:%scl_prefix}rubygem(rdiscount)
BuildRequires:  %{?scl:%scl_prefix}rubygem(formtastic)
BuildRequires:  %{?scl:%scl_prefix}rubygem(net-http-persistent)
BuildRequires:  %{?scl:%scl_prefix}rubygem(haml)
BuildRequires:  %{?scl:%scl_prefix}rubygem(therubyracer)

BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version
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

rm -f Gemfile.lock
bundle install --local

pushd test/rails_app/
CONSOLE_CONFIG_FILE=../../conf/console.conf.example RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
echo > log/production.log
popd

rm -f Gemfile.lock

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

%clean
rm -rf %{buildroot}

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

