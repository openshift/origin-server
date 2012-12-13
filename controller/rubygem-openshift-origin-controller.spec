%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-controller
%global rubyabi 1.9.1

Summary:        Cloud Development Controller
Name:           rubygem-%{gem_name}
Version: 1.3.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(state_machine)
Requires:       rubygem(openshift-origin-common)
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version
Obsoletes: 	rubygem-stickshift-controller

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
