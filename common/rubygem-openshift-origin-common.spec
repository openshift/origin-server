%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-common
%global rubyabi 1.9.1

Summary:       Cloud Development Common
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
Requires:      %{?scl:%scl_prefix}rubygem(activemodel)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(safe_yaml)
Requires:      %{?scl:%scl_prefix}rubygem(bundler)
%if 0%{?rhel}
Requires:      openshift-origin-util-scl
%endif
%if 0%{?fedora}
Requires:      openshift-origin-util
%endif
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

%package doc
Summary:        Cloud Development Common Library Documentation

%description
This contains the Cloud Development Common packaged as a rubygem.

%description doc
This contains the Cloud Development Common packaged as a ruby site library
documentation files.

%prep
%setup -q

%build
mkdir -p ./%{gem_dir}

%{?scl:scl enable %scl - << \EOF}
gem build %{gem_name}.gemspec
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
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
%dir %{gem_instdir}
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/COPYRIGHT
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/%{gem_name}.gemspec
%{gem_instdir}
%{gem_spec}
%{gem_libdir}

%if 0%{?scl:1}
%attr(0750,-,-) %{_root_sbindir}/oo-diagnostics
%{_root_mandir}/man8/oo-diagnostics.8.gz
%else
%attr(0750,-,-) %{_sbindir}/oo-diagnostics
%{_mandir}/man8/oo-diagnostics.8.gz
%endif

%exclude %{gem_cache}
%exclude %{gem_instdir}/rubygem-%{gem_name}.spec

%files doc 
%doc %{gem_docdir}

%changelog
* Mon Sep 30 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #2950 from adelton/oo-diagnostics-test_auth_conf_files
  (dmcphers+openshiftbot@redhat.com)
- Compare config files in /var/www/openshift, not with /etc.
  (jpazdziora@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3663 from dobbymoodge/oo-util-fixes
  (dmcphers+openshiftbot@redhat.com)
- Add support for cartridge protocol types in manifest (rchopra@redhat.com)
- <oo-diagnostics> Improve regexes for tests on Origin (jolamb@redhat.com)
- Fix type error, typos in oo-diagnostics test_auth_conf_files
  (jolamb@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- The mcollective logs need the scl prefix (bleanhar@redhat.com)
- Adding oo-mco and updating oo-diagnostics to support the SCL'd mcollective
  (bleanhar@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-0
- Bump up version to 1.15

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Merge pull request #3104 from Miciah/rubygem-openshift-origin-common-drop-
  rubygem-yard-dependency (dmcphers+openshiftbot@redhat.com)
- Handle .resultset.json (dmcphers@redhat.com)
- Drop spurious yard dependency from common pkg (miciah.masters@gmail.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Merge pull request #3435 from
  smarterclayton/bug_997848_capabilities_not_shown_via_api
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3327 from Miciah/oo-diagnostics-add-
  test_node_containerization_plugin (dmcphers+openshiftbot@redhat.com)
- Bug 997848 - Inherited capabilities not in REST API (ccoleman@redhat.com)
- oo-diagnostics: test_node_containerization_plugin (miciah.masters@gmail.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3373 from pmorie/bugs/997158
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 997158: always sort cartridge versions using Manifest.sort_versions
  (pmorie@gmail.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Upgrade tool enhancements (ironcladlou@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- <broker> improve Gemfile loading + bug 993250 (lmeyer@redhat.com)
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
- Bug 987155 (pmorie@gmail.com)
- <oo-diagnostics> - Fixes for checks related to apache config
  (jdetiber@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Bug 988255 (lnader@redhat.com)
- Set 'register_dns' op to 'rolledback' state in case of DNSLoginException.
  (rpenta@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Merge pull request #3192 from rmillner/origin_runtime_183_and_191_merge
  (dmcphers+openshiftbot@redhat.com)
- Origin uses single quotes in config files. (rmillner@redhat.com)
- Separate out libcgroup based functionality and add configurable templates.
  (rmillner@redhat.com)
- Bug 980376 (lnader@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- make haproxy a sparse cart (rchopra@redhat.com)
- support for sparse cartridges (multiple haproxy) (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  handle_global_exceptions_properly (ccoleman@redhat.com)
- Bug 980253 - Map illegal versions to 0.0.0 (jhonce@redhat.com)
- Move most DocumentNotFound handling to ApiResponse#render_exception
  (ccoleman@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.6-1
- Merge pull request #2979 from jwhonce/bug/980253
  (dmcphers+openshiftbot@redhat.com)
- Bug 980253 - Validate version numbers from manifest (jhonce@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.5-1
- Fix for bug 980760  - Preventing multiple versions of a cartridge from being
  added to the application (abhgupta@redhat.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
-  Revamp the cgroups and pam scripts to leverage the system setup for better
  performance and simplify the code. (rmillner@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Merge pull request #2934 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Changing File.join to PathUtils.join in node and common packages Uncommenting
  cgroups Fixing signal handling in oo-gear-init (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Merge pull request #2927 from smarterclayton/bug_970257_support_git_at_urls
  (dmcphers+openshiftbot@redhat.com)
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
- Tests pass fully (add initial_git_url for earlier api versions).  Control
  what values of URI get persisted to DB (passwords and userinfo from clone
  specs should not be) (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Merge pull request #2938 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- some strictures on broker's manifest parsing (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Allow clients to pass an initial_git_url of "empty", which creates a bare
  repo but does not add a commit.  When 'empty' is passed, the node will skip
  starting the gear and also skip the initial build.  This allows clients that
  want to send a local Git repository (one that isn't visible to OpenShift.com,
  for example) to avoid having to push/merge/delete the initial commit, and
  instead submit their own clean repo.  In this case, the user will get a
  result indicating that their repository is empty. (ccoleman@redhat.com)
- Bug 970257 - Allow git@ urls (ccoleman@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Fri Jun 21 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- <oo-diagnostics> Bug 976874 - Detect abrt-addon-python conflicts
  (jdetiber@redhat.com)
- <common> bug 976173 oo-diagnostics requires bundler (lmeyer@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Merge pull request #2805 from BanzaiMan/dev/hasari/bz972757
  (dmcphers+openshiftbot@redhat.com)
- Bug 972757: Allow vendor names to start with a numeral (asari.ruby@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- Bump up version (tdawson@redhat.com)
- <oo-diagnostics> Bug 970805 - Add check for broker SSL cert
  (jdetiber@redhat.com)
- Fixing optional scl macros in rubygem-openshift-origin-common
  (kraman@gmail.com)
- Merge pull request #2707 from kraman/f19_fixes
  (dmcphers+openshiftbot@redhat.com)
- <common> fix .spec so oo-diag is in non-scl locations (lmeyer@redhat.com)
- Fixed spurious yardoc inclusion as this causes build to break on F19
  (kraman@gmail.com)
- origin_runtime_138 - Add SSL_ENDPOINT variable and filter whether carts use
  ssl_to_gear. (rmillner@redhat.com)
- Add ssl_to_gear option. (mrunalp@gmail.com)
- <common> add oo-diagnostics and man page (lmeyer@redhat.com)
- Make Install-Build-Required default to false (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.8.8-1
- Merge pull request #2654 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz 967779, 967409, 967395 (rchopra@redhat.com)
- Merge pull request #2658 from rmillner/out_of_date
  (dmcphers+openshiftbot@redhat.com)
- These policies are long deprecated, removing them to avoid confusion.
  (rmillner@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- vendoring of cartridges (rchopra@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Bug 965317 - Add way to patch File class so all files have sync enabled.
  (rmillner@redhat.com)
- Bug 966759 - Ensure mappings start with / (jhonce@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Fix for bug 960757  - Sending init_git_url only for deployable cartridge
  configure/post-configure  - Removing is_primary_cart method in favor of
  is_deployable (abhgupta@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- WIP Cartridge Refactor - V2 -> V2 Migration (jhonce@redhat.com)
- safe yaml for parsing of downloaded yaml (rchopra@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.8.3-1
- WIP Cartridge Refactor - V2 -> V2 Migration (jhonce@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2491 from ironcladlou/dev/v2carts/private-endpoints-fix
  (dmcphers+openshiftbot@redhat.com)
- Escape early from endpoint creation when there are none to create
  (ironcladlou@gmail.com)
- Bug 958653 (lnader@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)
- Merge pull request #2341 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bugs 958653, 959676, 959214 and Cleaned up UserException (lnader@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.7.6-1
- Merge pull request #2392 from BanzaiMan/dev/hasari/bz959843
  (dmcphers+openshiftbot@redhat.com)
- Do not validate vendor and cartridge names when instantiating Manifest from
  filesystem. (asari.ruby@gmail.com)
- Bug 958694: Make .state gear scoped and refactor primary cart concept
  (ironcladlou@gmail.com)
- Merge pull request #2374 from BanzaiMan/dev/hasari/reserved_cartridge_names
  (dmcphers+openshiftbot@redhat.com)
- Bug 960375: restrict vendor and cartridge names to 32 characters.
  (asari.ruby@gmail.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- Check cartridge name for reserved names ('app-root', 'git')
  (asari.ruby@gmail.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Merge pull request #2342 from BanzaiMan/dev/hasari/c288_followup
  (dmcphers+openshiftbot@redhat.com)
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Special file processing (fotios@redhat.com)
- Validate cartridge and vendor names under certain conditions
  (asari.ruby@gmail.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Card 551 (lnader@redhat.com)
- Move Runtime::Cartridge to openshift-origin-common (ironcladlou@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Keep a separate cache for each config file. (rmillner@redhat.com)
- Cache the node conf into a singleton instance so we do not constantly reload
  and re-parse it. (rmillner@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Card 534 (lnader@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Fix bug 927893 - calculate is_premium? by checking for usage rates
  (jliggitt@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Add SNI upload support to API (lnader@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Merge pull request #1643 from kraman/update_parseconfig (dmcphers@redhat.com)
- Replacing get_value() with config['param'] style calls for new version of
  parseconfig gem. (kraman@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- reverted US2448 (lnader@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Added validation for SSL certificate and private key (lnader@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- fix rubygem sources (tdawson@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Fixes for ruby193 (john@ibiblio.org)
- providing stub for usage_rates and changing rest response field to
  usage_rates from usage_rate_usd (abhgupta@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- US2626 changes based on feedback - Add application name in Usage and
  UsageRecord models - Change 'price' to 'usage_rate_usd' in rest cartridge
  model - Change 'charges' to 'usage_rates' in rails configuration - Rails
  configuration stores usage_rates for different currencies (currently only
  have usd) (rpenta@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Collect/Sync Usage data for EAP cart (rpenta@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- fix for bug 896333 (abhgupta@redhat.com)
- fixed runtime tests and Lock exception handling (lnader@redhat.com)
- fix for bug 895730 and 895733 (abhgupta@redhat.com)
- 892068 (dmcphers@redhat.com)
- Bug 893879 (dmcphers@redhat.com)
- Bug 889958 (dmcphers@redhat.com)
- fix for bug 893365 (abhgupta@redhat.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- fix require for fedora (dmcphers@redhat.com)
- add util package for oo-ruby (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Fix for bug# 876516 (rpenta@redhat.com)
- Fix bug# 876124: caused due to ruby 1.8 to 1.9 upgrade (rpenta@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- remove %%prep steps that add gem pre-processing since we're using a .tar.gz
  (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- getting specs up to 1.9 sclized (dmcphers@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
