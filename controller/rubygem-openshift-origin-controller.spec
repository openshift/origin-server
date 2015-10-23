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
Version: 1.38.4
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
Requires:      %{?scl:%scl_prefix}rubygem(httpclient)
Requires:      %{?scl:%scl_prefix}rubygem-net-ssh
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
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.38.4-1
- Bug 1268080: Handling missing parent domain ops during app op execution
  (abhgupta@redhat.com)

* Thu Oct 15 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.3-1
- controller: execute_connections: reformat, comment (miciah.masters@gmail.com)
- Merge pull request #6271 from Miciah/bug-1261540-controller-
  execute_connections-nix-client-output (dmcphers+openshiftbot@redhat.com)
- controller: execute_connections: nix client output (miciah.masters@gmail.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.2-1
- gear-placement plugin: provide namespace to plugin (miciah.masters@gmail.com)

* Thu Sep 17 2015 Unknown name 1.38.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.37.4-1
- Merge pull request #6230 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Bug 1095610: Validation for zone names (abhgupta@redhat.com)
- Bug 1234603: spreading gears for an app evenly across zones
  (abhgupta@redhat.com)
- Removing oo-broker prefixes for admin commands (abhgupta@redhat.com)

* Mon Aug 17 2015 Wesley Hearn <whearn@redhat.com> 1.37.3-1
- Bug 1095610: Additional validations for region/zone names  - an alphanumeric
  character anywhere in the name is now required  - there is no regex
  validation for zone name during deletion (abhgupta@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.37.2-1
- Merge pull request #6213 from abhgupta/bug_1244126
  (dmcphers+openshiftbot@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Bug 1244126: Allowing 4096 char limit for env variable values
  (abhgupta@redhat.com)
- Merge pull request #6182 from tiwillia/bz1197123
  (dmcphers+openshiftbot@redhat.com)
- Round up if base filesystem quota is less than 1Gb (tiwillia@redhat.com)
- Bug 1238816: Fixing mongo query that referenced older app structure
  (abhgupta@redhat.com)
- Merge pull request #6164 from tiwillia/bz1191283
  (dmcphers+openshiftbot@redhat.com)
- Resolve race condition where cartridges activated within the same second
  conflicted (tiwillia@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.37.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.36.3-1
- Merge pull request #6121 from kevinearls/ENTESB-2753
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6047 from Filirom1/patch-4
  (dmcphers+openshiftbot@redhat.com)
- Adjust version of unified push cart (dmcphers@redhat.com)
- Add hidden gear sizes concept (dmcphers@redhat.com)
- Formatting fixes (dmcphers@redhat.com)
- oo-admin-ctl-domain uses underscores in command options (tiwillia@redhat.com)
- Merge pull request #6123 from tiwillia/bz1210489
  (dmcphers+openshiftbot@redhat.com)
- Add membership manipulation to oo-admin-ctl-domain (tiwillia@redhat.com)
- BZ1210489 -  Enable-HA registers routing appliaction DNS twice, breaking
  functionality for some custom DNS plugins (tiwillia@redhat.com)
- ENTESB-2753 updated quick start name and location of test data for Fuse
  smoketest (kevin@kevinearls.com)
- update mongo read_preference for OpenShift Stats (filirom1@gmail.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 1.36.2-1
- Bug 1218841 - Adding the net-ssh requirement to the controller RPM
  (bleanhar@redhat.com)

* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.36.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Tue Apr 07 2015 Wesley Hearn <whearn@redhat.com> 1.35.4-1
- Merge pull request #6093 from timothyh/dev/timothyh/rfe/1200123
  (dmcphers+openshiftbot@redhat.com)
- Clean up sso_service (thunt@redhat.com)
- Initial commit of controller hooks for SSO Service (thunt@redhat.com)

* Mon Mar 30 2015 Troy Dawson <tdawson@redhat.com> 1.35.3-1
- Remove invalid test (dmcphers@redhat.com)
- Fix typo (dmcphers@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.35.2-1
- Add option to have the default application URL use https - updated
  (bedin@redhat.com)
- Update rest-keys tests for ssh key length validation (sdodson@redhat.com)
- Add net-ssh to controller gem-spec and validator (sdodson@redhat.com)
- Updated key_content_validator.rb with better exception handling for invalid
  keys (bedin@redhat.com)
- Change for SSH minimum key size check (bedin@redhat.com)
- Card devexp_483 - Obsoleting 10gen cartridge (maszulik@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.35.1-1
- Merge pull request #6066 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6058 from Miciah/bug-1186036-routing-spi-send-
  notifications-on-rollbacks (dmcphers+openshiftbot@redhat.com)
- Bug 1183048: Fix stale keys/envvars in domains with no apps
  (abhgupta@redhat.com)
- Merge pull request #6052 from kwoodson/regions
  (dmcphers+openshiftbot@redhat.com)
- Routing SPI: Send notifications on rollbacks (miciah.masters@gmail.com)
- Removing duplicate servers strings from fields. (kwoodson@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)
- Add region level reporting to oo-stats (cewong@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.34.2-1
- Bug 1175489: Wrong grep regexp in jbossews (j.hadvig@gmail.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.34.1-1
- Merge pull request #5997 from pravisankar/bug-1163893
  (dmcphers+openshiftbot@redhat.com)
- Bug 1163893 - Encode artifact url for app deployments (rpenta@redhat.com)
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Mon Dec 01 2014 Adam Miller <admiller@redhat.com> 1.33.2-1
- Merge pull request #5947 from sosiouxme/predictable-gear-uuids
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5971 from nak3/patch01 (dmcphers+openshiftbot@redhat.com)
- controller: option LIMIT_APP_NAME_CHARS (lmeyer@redhat.com)
- controller: make gear UUIDs predictable (lmeyer@redhat.com)
- controller: whitespace fixes (lmeyer@redhat.com)
- Default configuration parameter to set Private SSL certificates allowed
  (nakayamakenjiro@gmail.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)
- Add cucumber tests for Unified Push Server cartridge (vvitek@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.32.3-1
- BZ1158704 - Broker fails to create HA DNS entry for HA app
  (calfonso@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Analytics additions (dmcphers@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- Fix race condition in team creation (decarr@redhat.com)
- Bug 1158737 - exposes the "ha" attribute on the "application" rest endpoint
  (contact@fabianofranz.com)
- Bug 1158737 - exposes DISABLE_HA on broker (contact@fabianofranz.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.31.8-1
- ssh keys: remove special logins (lmeyer@redhat.com)
- fix whitespace (lmeyer@redhat.com)
- app container proxy: Add user login to ssh authorized_keys file
  (thunt@redhat.com)

* Mon Oct 13 2014 Adam Miller <admiller@redhat.com> 1.31.7-1
- disable ha feature (rchopra@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.31.6-1
- Merge pull request #5743 from dobbymoodge/node_block_rollback
  (dmcphers+openshiftbot@redhat.com)
- node archive: improve doc, config logic (jolamb@redhat.com)
- broker/node: Add parameter for gear destroy to signal part of gear creation
  (jolamb@redhat.com)
- Preventing rollback for PatchUserEnvVarsOp in case of gear creation
  (abhgupta@redhat.com)

* Thu Oct 02 2014 Adam Miller <admiller@redhat.com> 1.31.5-1
- Bug 1145132 - Domain validation fails when adding size due to previously
  removed size (abhgupta@redhat.com)

* Tue Sep 30 2014 Adam Miller <admiller@redhat.com> 1.31.4-1
- Merge pull request #5845 from mfojtik/wildfly_test_fix
  (dmcphers+openshiftbot@redhat.com)
- Adding checks and repair logic for invalid gear sizes in domains
  (abhgupta@redhat.com)
- Fixed wildfly cartridge name in cucumber tests (mfojtik@redhat.com)
- Bug 1146681 - oo-admin-ctl-domain cannot change allowed gear sizes for a
  mixed-case domain (abhgupta@redhat.com)
- Merge pull request #5839 from bparees/fix_jboss_test
  (dmcphers+openshiftbot@redhat.com)
- use regex handling for jboss string (bparees@redhat.com)

* Wed Sep 24 2014 Adam Miller <admiller@redhat.com> 1.31.3-1
- Merge pull request #5829 from mfojtik/wildfly_test
  (dmcphers+openshiftbot@redhat.com)
- Card origin_devexp_328 - Initial Wildfly 8 cucumber tests
  (mfojtik@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.31.2-1
- Multiple bug fixes Bug 1109647 - Loss of alias on SYNOPSIS part for oo-admin-
  ctl-app Bug 1144610 - oo-admin-usage is broken Bug 1130435 - Setting a same
  scale info on a cartridge makes connection hooks being run
  (abhgupta@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- Multiple bug fixes: Bug 1086061 - Should update the description of clean
  command for oo-admin-ctl-cartridge tool Bug 1109647 - Loss of alias on
  SYNOPSIS part for oo-admin-ctl-app Bug 1065853 - Should prompt warning when
  leaving source code url blank but add branch/tag during app creation Bug
  1143024 - A setting of ZONES_MIN_PER_GEAR_GROUP=2 with two available zones
  will always error as though only one zone is available Bug 1099796 - Should
  refine the error message when removing a nonexistent global team from file
  (abhgupta@redhat.com)
- Multiple bug fixes  - Bug 1108556: incorrect layout in oo-admin-ctl-domain
  man page  - Bug 1117643: Missing '--allowed_gear_sizes' option in help of oo-
  admin-ctl-domain  - Bug 1112455: Should give proper info when the same addon
  cartridges added to one application  - Bug 1112636: zend-5.6 should be
  removed from warning message when try to create an app using invalid download
  cartridge  - Bug 1109647: Loss of alias on SYNOPSIS part for oo-admin-ctl-app
  (abhgupta@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- Bug 1084090: False positives reported for stale ssh keys  - In cases where
  the user had multiple domains, false positives could be reported for stale
  domain ssh keys (abhgupta@redhat.com)

* Mon Sep 08 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- Merge pull request #5787 from bparees/unique_domain_env_vars
  (dmcphers+openshiftbot@redhat.com)
- check for domain environment variable uniqueness on app create
  (bparees@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Merge pull request #5766 from ncdc/fix-scale-snapshot-test
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5762 from bparees/xpaas_tests
  (dmcphers+openshiftbot@redhat.com)
- Fix scalable platform snapshot test (agoldste@redhat.com)
- broker: ensure normalization is idempotent (lmeyer@redhat.com)
- move xpaas cucumber tests upstream (bparees@redhat.com)

* Fri Aug 22 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- remove the check on Apache DB files because the plugin may not be present
  (rchopra@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- Merge pull request #5731 from bparees/unique_json_filenames
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 50 (admiller@redhat.com)
- use unique filenames for each TestApp persisted file (bparees@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.29.6-1
- Update extended test for online/enterprise (jdetiber@redhat.com)
- Bug 1130496: Blocking carts with 2+ min gears in non-scalable apps
  (abhgupta@redhat.com)

* Mon Aug 18 2014 Adam Miller <admiller@redhat.com> 1.29.5-1
- Bug 1126826: cleaning up domain env vars and ssh keys on rollback
  (abhgupta@redhat.com)

* Thu Aug 14 2014 Adam Miller <admiller@redhat.com> 1.29.4-1
- Update README.md (dmcphers@redhat.com)
- Merge pull request #5683 from soltysh/binary_deploy_tests
  (dmcphers+openshiftbot@redhat.com)
- Reafactored binary deployment tests for running them faster.
  (maszulik@redhat.com)

* Wed Aug 13 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Merge pull request #5709 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix path for oo-accept-systems (rchopra@redhat.com)
- cloud_user: enable normalization of user logins. (lmeyer@redhat.com)
- fix whitespace (lmeyer@redhat.com)
- fix node extended tests (rchopra@redhat.com)

* Mon Aug 11 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Add broker flag to disable user selection of region (cewong@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Merge pull request #5689 from derekwaynecarr/region_description
  (dmcphers+openshiftbot@redhat.com)
- Test improvements that were affecting enterprise test scenarios
  (jdetiber@redhat.com)
- Add support for description on region object (decarr@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.28.7-1
- Merge pull request #5669 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5666 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1124306: Handling nil min/max scale values for cartridge
  (abhgupta@redhat.com)
- Bug 1122809 (lnader@redhat.com)

* Tue Jul 29 2014 Adam Miller <admiller@redhat.com> 1.28.6-1
- Bug 1123371: Fixing issue with setting the cartridge multiplier
  (abhgupta@redhat.com)

* Mon Jul 28 2014 Adam Miller <admiller@redhat.com> 1.28.5-1
- Bug 1122657: Fixing logic to select gear for scaledown (abhgupta@redhat.com)

* Thu Jul 24 2014 Adam Miller <admiller@redhat.com> 1.28.4-1
- Merge pull request #5649 from jwhonce/origin_node_401
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5644 from fabianofranz/bugs/1122413
  (dmcphers+openshiftbot@redhat.com)
- Card origin_node_401 - Fix extended tests (jhonce@redhat.com)
- Bug 1122413 - handle server without explicit regions
  (contact@fabianofranz.com)

* Wed Jul 23 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- use ident instead of name in deconfigure invocation (bparees@redhat.com)
- Bug 1121971: Validate based on domain owner capabilities during app create
  (jliggitt@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- Merge pull request #5613 from derekwaynecarr/bug_1120413
  (dmcphers+openshiftbot@redhat.com)
- Added LIST_REGIONS (lnader@redhat.com)
- Ensure domain environment variables are passed to cartridge install scripts
  (decarr@redhat.com)
- Added ruby-2.0 test cases (mfojtik@redhat.com)
- Add currency_cd field to CloudUser (jliggitt@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Tue Jul 08 2014 Adam Miller <admiller@redhat.com> 1.27.5-1
- Do not attempt to filter if no conf is provided (decarr@redhat.com)

* Mon Jul 07 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Merge pull request #5566 from soltysh/card224
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_224 - Upgrading nodejs quickstarts to version 0.10
  (maszulik@redhat.com)

* Thu Jul 03 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Bug 1115309 - Default region will be selected when optional param 'region' is
  not set during app creation. (rpenta@redhat.com)
- Bug 1115274 - Fix 'default' field in /regions REST api (rpenta@redhat.com)
- Bug 1115244 - Add 'region' as optional param to ADD_APPLICATION link
  (rpenta@redhat.com)
- Bug 1115321 - Fix zone name in gear_groups rest api responsew
  (rpenta@redhat.com)
- Merge pull request #5559 from derekwaynecarr/restrict_cart_gear_size
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5564 from sosiouxme/relax-alias-validation
  (dmcphers+openshiftbot@redhat.com)
- broker: add PREVENT_ALIAS_COLLISION option. (lmeyer@redhat.com)
- application.rb: allow vim to fix whitespace (lmeyer@redhat.com)
- Restrict carts to set of gear sizes (decarr@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Enables user to specify a region when creating an application
  (lnader@redhat.com)
- Expose region and zones of gears in REST API (lnader@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Tue Jun 17 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Bug 1067404: Handling additional storage correctly at the group level
  (abhgupta@redhat.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Merge pull request #5307 from dobbymoodge/test_php_env_scan
  (dmcphers+openshiftbot@redhat.com)
- php cart: dynamic, controllable php.d seeding (jolamb@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- Bug 1103131: Remove authorize! check and let Team.accessible() limit which
  global teams a user can see (jliggitt@redhat.com)
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.4-1
- Ensure at least one scope's conditions are met, even when combined with
  complex queries (jliggitt@redhat.com)
- Bug 1102273: Make domain scopes additive (jliggitt@redhat.com)

* Wed May 28 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Change GroupOverride.empty? so group overrides with 1 component is not
  considered empty. Change logic that splits group overrides up if their
  component don't belong to the same platform. (vlad.iovanov@uhurusoftware.com)

* Wed May 21 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Add Team management UI (jliggitt@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.9-1
- Merge pull request #5396 from ironcladlou/scalable-unidling
  (dmcphers+openshiftbot@redhat.com)
- Fix idler cucumber tests (ironcladlou@gmail.com)
- Bug 1095186 - corrected args passed to district (lnader@redhat.com)

* Wed May 07 2014 Troy Dawson <tdawson@redhat.com> 1.24.8-1
- Bug 1094541 - check for null values (lnader@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Bug 1094108 - show obsolete carts if ALLOW_OBSOLETE_CARTRIDGES=true
  (lnader@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 1.24.7-1
- Merge pull request #5375 from ironcladlou/scalable-unidling
  (dmcphers+openshiftbot@redhat.com)
- Bug 1093804: Validating the node returned by the gear-placement plugin
  (abhgupta@redhat.com)
- Support unidling scalable apps (ironcladlou@gmail.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.24.6-1
- Add support for multiple platforms to districts
  (daniel.carabas@uhurusoftware.com)
- Bug 1091044 (lnader@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 1.24.5-1
- Annual Online SKU Support (lnader@redhat.com)
- Making the domain_op complete? method more robust (abhgupta@redhat.com)
- Merge pull request #5343 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bugs 1084980 and 889947 (lnader@redhat.com)

* Tue Apr 29 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Adding test coverage for remote-user auth (bleanhar@redhat.com)

* Mon Apr 28 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Merge pull request #5341 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Remove unused code (dmcphers@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.9-1
- Bug 1088845: Blocking external carts from adding storage and setting
  multiplier (abhgupta@redhat.com)
- Merge pull request #5262 from
  liggitt/bug_1083544_reentrant_membership_change_ops
  (dmcphers+openshiftbot@redhat.com)
- Bug 1083544: Make member change ops re-entrant (jliggitt@redhat.com)
- Allow setting parent op for member changes (jliggitt@redhat.com)

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.8-1
- Bug 1088941: Exclude non-member global teams from index (jliggitt@redhat.com)
- Merge pull request #5290 from liggitt/bug_1086920_check_domain_ssl_capability
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086920: Check ssl certificate capability on domain, not on user
  (jliggitt@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.7-1
- Merge pull request #5287 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5253 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Adding a config flag in the broker to selectively manage HA DNS entries
  (abhgupta@redhat.com)
- Merge pull request #5192 from liggitt/user_email
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086094: Multiple changes for cartridge colocation We are:  - taking into
  account the app's complete group overrides  - allowing only plugin carts to
  colocate with web/service carts  - blocking plugin (except sparse) carts from
  responding to scaling min/max changes (abhgupta@redhat.com)
- Merge pull request #5284 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Adding test coverage for to_xml (dmcphers@redhat.com)
- Add email field to CloudUser (jliggitt@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.6-1
- Fix formatting (dmcphers@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.5-1
- Bug 1087710: Removing explicit role with implicit role present leaves higher
  role in place (jliggitt@redhat.com)
- added oo-admin-ctl-team (lnader@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Bug 1086567: Handle implicit members leaving (jliggitt@redhat.com)
- BZ1083475 - HA scalable application DNS is not deleted after app is destroyed
  (calfonso@redhat.com)
- Merge pull request #5229 from liggitt/bug_1086115_change_explicit_role
  (dmcphers+openshiftbot@redhat.com)
- Add test for elevating and lowering the explicit role of a member who also
  has an implicit grant (jliggitt@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Merge pull request #5226 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Setting domain op state to completed after updating capabilities
  (abhgupta@redhat.com)
- Add domain to analytics tracking (dmcphers@redhat.com)
- Merge pull request #5218 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5217 from liggitt/team_remove
  (dmcphers+openshiftbot@redhat.com)
- Removing Start-Order and Stop-Order from the manifest (abhgupta@redhat.com)
- Bug 1086370: removing one team removes all explicit members
  (jliggitt@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Add support for SSLv2 when downloading cartridges (mfojtik@redhat.com)
- Merge pull request #5206 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5187 from pravisankar/dev/ravi/fix-testcases
  (dmcphers+openshiftbot@redhat.com)
- Add validations to district model and move gear_size initialization from
  create_district() to initialize(). (rpenta@redhat.com)
- Fix cucumber test platform-oo-admin.feature: Need to look at exit code and
  not the output for errors, output can have warning messages
  (rpenta@redhat.com)
- Bug 1084542: Fixing Start/Stop order for components  - Start now follows
  post-configure order  - Stop now follows the reverse of the start order  -
  post-configure order follows the configure order with the one exception that
  the web_framework is at the end (abhgupta@redhat.com)
- Bug 1082464 - do not show member links for update and delete if team in
  global (lnader@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Use consistent naming on alias_add and more detail on cartridge scale
  (dmcphers@redhat.com)
- Fixing error message around submodule repo (dmcphers@redhat.com)
- Merge pull request #5184 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1071393 - Fix DNSLoginException (rpenta@redhat.com)
- Bug 1071272 - oo-admin-repair: Only allow node removal from its district when
  no apps are referencing that node (rpenta@redhat.com)
- separate scaling and storage tracking events (dmcphers@redhat.com)
- Use mock cart for testing (dmcphers@redhat.com)
- Bug 1084054: Check for external cartridge for group instance without gears
  (abhgupta@redhat.com)
- Use configured default (jliggitt@redhat.com)
- Add global_teams capability (jliggitt@redhat.com)
- Bug 1084419 - Fix tracking for update alias (dmcphers@redhat.com)
- Merge pull request #5167 from bparees/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5166 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5165 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- remove duplicate test check line (bparees@redhat.com)
- Formatting fixes (dmcphers@redhat.com)
- Bug 1084090: Using as_document instead of serializable_hash to add/remove
  keys (abhgupta@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Merge pull request #5155 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5137 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5151 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #5152 from
  pravisankar/dev/ravi/bugs-1081381-1073342-1008654
  (dmcphers+openshiftbot@redhat.com)
- Bug 1082464 - Do not show links for ADD_MEMBER, UPDATE_MEMBERS, DELETE AND
  LEAVE for global teams (lnader@redhat.com)
- Split user errors and internal errors for analytics (dmcphers@redhat.com)
- Bug 1008654 - oo-admin-chk: Report app gears with out server_identity field
  set in mongo (rpenta@redhat.com)
- Bug 1073342 - oo-admin-chk fix: don't print duplicate error messages when
  login is null/empty (rpenta@redhat.com)
- Adding user create tracking event (dmcphers@redhat.com)
- Make non-global search more efficient (jliggitt@redhat.com)
- Removed global flag - using owner_id=nil as indicator for global team
  (lnader@redhat.com)
- Require global flag on search (lnader@redhat.com)
- changed min length for team name to 2 (lnader@redhat.com)
- corrected typo - Search string must be at least 2 characters
  (lnader@redhat.com)
- fixed validation and tests (lnader@redhat.com)
- use rest_teams for search count (lnader@redhat.com)
- changed global=true to owner_id=nil (lnader@redhat.com)
- modified error message - use same message for leave (lnader@redhat.com)
- cleaned up team validation (lnader@redhat.com)
- escape search string (lnader@redhat.com)
- change validation on globally unique (lnader@redhat.com)
- remove membership management links if team syncs to group (lnader@redhat.com)
- added sorting (lnader@redhat.com)
- moved global checking to before_filter (lnader@redhat.com)
- Global teams (lnader@redhat.com)
- Merge pull request #5114 from danmcp/analytics
  (dmcphers+openshiftbot@redhat.com)
- Analytics Tracker (dmcphers@redhat.com)
- Bug 1079844: Fixed error message when removing an invalid cartridge
  (abhgupta@redhat.com)
- Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore" (bparees@redhat.com)
- Fix php file permissions cucumber tests (vvitek@redhat.com)
- Merge pull request #5099 from liggitt/fix_app_locking_from_team_member_change
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)
- Use application.owner_id in unlock_app (jliggitt@redhat.com)
- Fix app locking from team member change (jliggitt@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.8-1
- Merge pull request #5089 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- REST API docs for team (lnader@redhat.com)
- Merge pull request #5087 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5082 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 989941: preventing colocation of cartridges that independently scale
  (abhgupta@redhat.com)
- Merge pull request #5072 from pravisankar/dev/ravi/bug1072289
  (dmcphers+openshiftbot@redhat.com)
- Bug 1072289 - Execute patching user env vars only on current group instance
  gears when gear_instance_id is passed (rpenta@redhat.com)
- corrected missing comma (lnader@redhat.com)
- corrected UPDATE_MEMBER link for domain and team (lnader@redhat.com)
- Bug 1065276 - Skip *.rpmnew when loading environments (jhonce@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.7-1
- Merge pull request #5069 from pravisankar/dev/ravi/bug1078008
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5070 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1078008 - Restrict cloning app if storage requirements are not matched
  (rpenta@redhat.com)
- Bug 1078119 (lnader@redhat.com)
- Bug 1078814: Adding more validations for cartridge manifests
  (abhgupta@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.6-1
- Merge pull request #5054 from bparees/missing_log_dirs
  (dmcphers+openshiftbot@redhat.com)
- remove checks for cart specific log dirs (bparees@redhat.com)
- remove check for jbosseap log dir (bparees@redhat.com)
- Merge pull request #5049 from pravisankar/dev/ravi/bug1079301
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5035 from liggitt/team_pending_ops
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Bug 1079301 - Fix oo-admin-ctl-district remove-node error output
  (rpenta@redhat.com)
- Remove parent_op from team_pending_ops (jliggitt@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Fix typo in authorize call (jliggitt@redhat.com)
- Use rails http basic auth parsing, reuse controller, correctify comments
  (jliggitt@redhat.com)
- Allow filtering authorizations by scope when deleting all
  (jliggitt@redhat.com)
- Update tests (jliggitt@redhat.com)
- Return errors other than client_id or redirect_uri (jliggitt@redhat.com)
- SSO OAuth support (jliggitt@redhat.com)
- Merge pull request #5030 from liggitt/teams_api_includes_members
  (dmcphers+openshiftbot@redhat.com)
- Fixing gear extended (dmcphers@redhat.com)
- Include members in /team/:id, and optionally in /teams (jliggitt@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Fixing extended tests (dmcphers@redhat.com)
- Update tests to not use any installed gems and use source gems only Add
  environment wrapper for running broker util scripts (jforrest@redhat.com)
- Bug 1079072 - Hide quota error messsages (jhonce@redhat.com)
- Merge pull request #4990 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Checking and fixing stale sshkeys and env_vars  - using oo-admin-chk and oo-
  admin-repair (abhgupta@redhat.com)
- Multiple fixes  - Checking the provides list for cartridge matches for
  Configure-Order  - Skipping rollback for configure and similar operations in
  case of a new gear creation. Instead, we will just delete the gear  - Fixing
  exception raising logic on rollback success/failure (abhgupta@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #4987 from jhadvig/10gen_new
  (dmcphers+openshiftbot@redhat.com)
- 10gen cartridge update (jhadvig@redhat.com)
- Merge pull request #4993 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4995 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Fixing condition in run_jobs to prevent infinite loop (abhgupta@redhat.com)
- fix https://bugzilla.redhat.com/show_bug.cgi?id=1076720 : embedded cart
  should follow web_framework (rchopra@redhat.com)
- Cleanup (dmcphers@redhat.com)
- Merge pull request #4968 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4929 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4977 from nhr/test_fix (dmcphers+openshiftbot@redhat.com)
- cart configure should expose ports as well (rchopra@redhat.com)
- Merge pull request #4978 from pravisankar/dev/ravi/fix-pending-apps-domains
  (dmcphers+openshiftbot@redhat.com)
- Refactor find_by existing member lookup (jliggitt@redhat.com)
- Make membership check more efficient, explicitly return (jliggitt@redhat.com)
- Make rest_member more resilient to additional types (jliggitt@redhat.com)
- Change "edit" example to "none" for team member role (jliggitt@redhat.com)
- Remove show/create/update implementations from team_members_controller.
  Require role param when adding team members. Test for missing/empty role
  param (jliggitt@redhat.com)
- Distinguish between non-members and indirect members in warning messages. Do
  not include login field for members of type 'team' (jliggitt@redhat.com)
- User can only add teams to domain that he owns (lnader@redhat.com)
- Added allowed_roles/member_types, removed team add by name, refactored
  removed_ids (lnader@redhat.com)
- Updated scopes for application and domain (lnader@redhat.com)
- Added validate_role and validate_type to base class and overide
  (lnader@redhat.com)
- Bug 1075437 (lnader@redhat.com)
- Bug 1077047 (lnader@redhat.com)
- fixed test failure (lnader@redhat.com)
- Bug 1075445 (lnader@redhat.com)
- team member update should only allow roles view and none (lnader@redhat.com)
- Revised members controller to type qualify (lnader@redhat.com)
- Type qualify member links (lnader@redhat.com)
- Added LIST_TEAMS_BY_OWNER GET /teams?owner=@self (lnader@redhat.com)
- Removed update ability from teams.  Teams cannot be renamed
  (lnader@redhat.com)
- Provide valid options for role (lnader@redhat.com)
- Added :create_team ability (lnader@redhat.com)
- corrected domain links and descriptions (lnader@redhat.com)
- Bug 1075421 - corrected team GET link to use id instread of name
  (lnader@redhat.com)
- Delete user teams on force_delete (lnader@redhat.com)
- Bug 1074861 - Added error code for team limit reached (lnader@redhat.com)
- Bug 1075048 - null checking on role to update (lnader@redhat.com)
- Teams API (lnader@redhat.com)
- Update stub generator to provide fallback handling for JBoss cart
  (hripps@redhat.com)
- Remove on_domains/on_apps from user/domain/team pending op. Now
  on_domains/on_apps are not passed from op-group instead current domains/apps
  are used during pending op execution. (rpenta@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Merge pull request #4959 from bparees/remove_rhc_debug
  (dmcphers+openshiftbot@redhat.com)
- Revert "Rebalancing tests" (dmcphers@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)
- remove debug flag for rhc get status operations in cucumber tests
  (bparees@redhat.com)
- Added User pending-op-group/pending-op functionality Added pending op groups
  for user add_ssh_keys/remove_ssh_keys (rpenta@redhat.com)
- Merge pull request #4954 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4924 from jhadvig/perl_deps
  (dmcphers+openshiftbot@redhat.com)
- Bug 1030305 - 'rhc app show --state/--gear' shows db gear stop after restore
  snapshot for scalable app (bparees@redhat.com)
- Merge pull request #4955 from fabianofranz/dev/163
  (dmcphers+openshiftbot@redhat.com)
- Bug 1075470 - Met "undefined method `platform' for nil" error when creating
  application of download cartridge. (vlad.iovanov@uhurusoftware.com)
- [origin-server-ui-163] When filtering by owner must respect token visibility
  (contact@fabianofranz.com)
- LIST_APPLICATIONS_BY_OWNER and LIST_DOMAINS_BY_OWNER only support @self as
  the owner argument (contact@fabianofranz.com)
- [origin-server-ui-163] Adding support to query apps owned by the user
  (contact@fabianofranz.com)
- cpanfila and Makefile.PL support (jhadvig@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Merge pull request #4944 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1007830 - Better error handling around quickstarts.json loading
  (dmcphers@redhat.com)
- Fix "create scalable app with custom web_proxy" test expectation. Fix getting
  cart from CartridgeCache in the context of an application.
  (vlad.iovanov@uhurusoftware.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Speeding up tests (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Blocking rollback once the gear/cart removal is underway
  (abhgupta@redhat.com)
- Create less apps in tests (dmcphers@redhat.com)
- Merge pull request #4840 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Added max_teams capability (lnader@redhat.com)
- Deleting applications on app creation rollbacks (abhgupta@redhat.com)
- Checking for empty string in ObjectId (abhgupta@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)
- Adding additional gear extended queue (dmcphers@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)
- Merge pull request #4896 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Cleaning up cuc tags (dmcphers@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.6-1
- Merge pull request #4895 from pmorie/bugs/1072663
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1072663, 1072663: (pmorie@gmail.com)
- Merge pull request #4889 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 1072249 (dmcphers@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Merge pull request #4874 from liggitt/bug_1070450_improve_no_storage_message
  (dmcphers+openshiftbot@redhat.com)
- Bug 1070450: Improve message when an application cannot have additional
  storage (jliggitt@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4867 from pravisankar/dev/ravi/bug-1069531
  (dmcphers+openshiftbot@redhat.com)
- Bug 1069531 - Fix populate_district_hash helper method for oo-admin-chk/oo-
  admin-repair (rpenta@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Fixing typos (dmcphers@redhat.com)
- remove old code (dmcphers@redhat.com)
- Merge pull request #4684 from liggitt/domain_capabilities
  (dmcphers+openshiftbot@redhat.com)
- Python - DocumentRoot logic, Repository Layout simplification
  (vvitek@redhat.com)
- Template cleanup (dmcphers@redhat.com)
- Merge pull request #4825 from bparees/jboss_config
  (dmcphers+openshiftbot@redhat.com)
- Surface owner storage capabilities and storage rates (jliggitt@redhat.com)
- allow users to prevent overwrite of local jboss config from repository
  (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Merge pull request #4812 from jhadvig/wip_perl
  (dmcphers+openshiftbot@redhat.com)
- Revert "Multiple fixes for stability" (dmcphers@redhat.com)
- Perl repository layout changes (jhadvig@redhat.com)
- Fixing tests (dmcphers@redhat.com)
- Merge pull request #4806 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Bug 1070168 - Handle equal cart names different from equal cart name and
  version (dmcphers@redhat.com)
- <Extended Tests> Cartridge Extended Test fixes (jdetiber@redhat.com)
- Merge pull request #4822 from
  smarterclayton/bug_1069457_update_comp_limits_drops_gear_size
  (dmcphers+openshiftbot@redhat.com)
- Bug 1069457 - UpdateCompLimits drops gear size (ccoleman@redhat.com)
- Improve finding a member in a members collection (jliggitt@redhat.com)
- Validate roles (jliggitt@redhat.com)
- Handle duplicate removes, removal of non-members (jliggitt@redhat.com)
- Code review comments (jliggitt@redhat.com)
- Team object, team membership (jliggitt@redhat.com)
- Merge pull request #4814 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Bug 1069186: handling missing group instance (abhgupta@redhat.com)
- PHP - DocumentRoot logic (optional php/ dir, simplify template repo)
  (vvitek@redhat.com)
- Merge pull request #4723 from liggitt/recalc_tracked_usage
  (dmcphers+openshiftbot@redhat.com)
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- Recalc tracked storage (jliggitt@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.20.7-1
- Bug 1065318 - Multiplier being reset (ccoleman@redhat.com)
- Fix typos (dmcphers@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.6-1
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #4773 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4772 from smarterclayton/bug_1065318_multiplier_lost
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055356 - Man page and help fixes (dmcphers@redhat.com)
- Bug 1065318 - Multiplier overrides lost during deserialization
  (ccoleman@redhat.com)
- cleanup (dmcphers@redhat.com)
- Merge pull request #4761 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4762 from
  smarterclayton/bug_1064720_group_overrides_lost_in_scale
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064239 and 1064141:  - Determining what components go on a gear upfront
  - Fetching ssl certs from an alternate haproxy gear, in case the previous one
  did not return it (abhgupta@redhat.com)
- Bug 1064720 - Group overrides lost during scale (ccoleman@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4753 from
  smarterclayton/make_configure_order_define_requires
  (dmcphers+openshiftbot@redhat.com)
- Configure-Order should influence API requires (ccoleman@redhat.com)
- Fix for bug 1064838 and partial fix for bug 1064141  - Setting comp_spec
  attributes for ha apps only if the app is ha  - fixing a typo in variable
  name where 'gear' was used instead of 'g' (abhgupta@redhat.com)
- Merge pull request #4752 from bparees/restore_test
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063764 and 1064239:  - Unsubscribe connections was not being called  -
  ALLOW_MULTIPLE_HAPROXY_ON_NODE config was not being honored
  (abhgupta@redhat.com)
- add test for jboss snapshot/restore that includes app content
  (bparees@redhat.com)
- Merge pull request #4750 from pravisankar/dev/ravi/bug1028919
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4674 from fabianofranz/dev/155
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064107 - Minor fix in district_nodes_clone(), maker.rb
  (rpenta@redhat.com)
- [origin-ui-155] Improves error and debug messages on the REST API and web
  console (contact@fabianofranz.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Gear size conflicts should be covered by a unit test (ccoleman@redhat.com)
- Test case cleanup (dmcphers@redhat.com)
- Merge pull request #4732 from
  smarterclayton/bug_1062852_cant_remove_shared_cart
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4738 from
  smarterclayton/bug_1063654_prevent_obsolete_cart_creation
  (dmcphers+openshiftbot@redhat.com)
- Bug 1062852 - Can't remove mysql from shared gear (ccoleman@redhat.com)
- Merge pull request #4735 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4736 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4699 from caruccio/fix-cart-props
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063654 - Prevent obsolete cartridge use except for builders
  (ccoleman@redhat.com)
- Adding groups for gear extended (dmcphers@redhat.com)
- Merge pull request #4731 from sosiouxme/duhhhh
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063455: Rescuing user ops in case the app gets deleted mid-way
  (abhgupta@redhat.com)
- <application model> select => compact (lmeyer@redhat.com)
- Fix cart props split value (mateus.caruccio@getupcloud.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Rebalancing cart extended tests (dmcphers@redhat.com)
- Splitting out gear tests (dmcphers@redhat.com)
- Merge pull request #4708 from smarterclayton/bug_1063109_trim_required_carts
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4700 from pravisankar/dev/ravi/bug1060339
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4713 from smarterclayton/report_503_only_in_maintenance
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4710 from jwhonce/bug/1063142
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4706 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1060339 - Move blacklisted check for domain/application to the controller
  layer. oo-admin-ctl-domain/oo-admin-ctl-app will use domain/application model
  and will be able to create/update blacklisted name. (rpenta@redhat.com)
- Report 503 only when server actually in maintenance (ccoleman@redhat.com)
- Only check dependencies on add/remove, not during elaborate
  (ccoleman@redhat.com)
- Bug 1063109 - Required carts should be handled higher in the model
  (ccoleman@redhat.com)
- Bug 1063142 - Ignore .stop_lock on gear operations (jhonce@redhat.com)
- Bug 1063277: Fixing typo where ResendAliasesOp was being added twice
  (abhgupta@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Merge pull request #4688 from
  smarterclayton/bug_1059858_expose_requires_to_clients
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055456 - Handle node env messages better (dmcphers@redhat.com)
- Support changing categorizations (ccoleman@redhat.com)
- Merge pull request #4690 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4692 from liggitt/usage_sync_multiplier
  (dmcphers+openshiftbot@redhat.com)
- Compute usage multiplier (jliggitt@redhat.com)
- fix https://bugzilla.redhat.com/show_bug.cgi?id=1062531 (rchopra@redhat.com)
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Use as_document instead of serializable_hash (ccoleman@redhat.com)
- Merge pull request #4685 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Removing os specific logic from tests (dmcphers@redhat.com)
- Bug 106321 - Stop cartridge is running on the wrong cart
  (ccoleman@redhat.com)
- test cleanup (dmcphers@redhat.com)
- Merge pull request #4681 from pravisankar/dev/ravi/misc-bugfixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4682 from danmcp/cleaning_specs
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4678 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4677 from pravisankar/dev/ravi/bug1059902
  (dmcphers+openshiftbot@redhat.com)
- Fix error message in case of invalid name for region/zone/district
  (rpenta@redhat.com)
- Bug 1061098 (dmcphers@redhat.com)
- Merge pull request #4668 from sosiouxme/custom-app-templates-2
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055781 - Rollback in case of district add node failure
  (rpenta@redhat.com)
- Bug 1059902 - oo-admin-chk fix: Try to re-populate user/domain info for
  user_id/domain_id if not found (rpenta@redhat.com)
- Bug 1060834 (dmcphers@redhat.com)
- <broker func tests> for custom default templates (lmeyer@redhat.com)
- <broker> enable customizing default app templates (lmeyer@redhat.com)
- Merge pull request #4454 from pravisankar/dev/ravi/card178
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4649 from ncdc/dev/rails-syslog
  (dmcphers+openshiftbot@redhat.com)
- Use NodeProperties model for server_infos in find_all_available_impl and
  related methods (rpenta@redhat.com)
- Use flexible array of optional parameters for find_available and underlying
  methods (rpenta@redhat.com)
- Removed REGIONS_ENABLED config param and preferred zones fixes
  (rpenta@redhat.com)
- Allow alphanumeric, underscore, hyphen, dot chars for district/region/zone
  name (rpenta@redhat.com)
- Bug 1055781 - Update district info in mongo only when node operation is
  successful (rpenta@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Added test case for set/unset region (rpenta@redhat.com)
- Add set-region/unset-region options to oo-admin-ctl-distict to allow
  set/unset of region/zone after node addition to district (rpenta@redhat.com)
- Bug fixes: 1055382, 1055387, 1055433 (rpenta@redhat.com)
- Added oo-admin-ctl-region script to manipulate regions/zones
  (rpenta@redhat.com)
- Merge pull request #4602 from jhadvig/mongo_update
  (dmcphers+openshiftbot@redhat.com)
- Add optional syslog support to Rails apps (andy.goldstein@gmail.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4662 from danmcp/fix_cart_tests
  (dmcphers+openshiftbot@redhat.com)
- Fixing cart tests (dmcphers@redhat.com)
- Card #185: Adding SSL certs to secondary web_proxy gears
  (abhgupta@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)
- Fix failing test, add an LRU cache for cart by id (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Support --node correctly on oo-admin-ctl-cartridge (ccoleman@redhat.com)
- Preventing multiple web proxies for an app to live on the same node
  (abhgupta@redhat.com)
- Merge pull request #4625 from mfojtik/card_89_tests
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Broker should allow version to be specified in Content-Type as well
  (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- default to Rails.configuration if show_obsolete is nil (lnader@redhat.com)
- Bug 1059458 (lnader@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Test cases for the nodejs use_npm marker (mfojtik@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Merge pull request #4610 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4532 from bparees/jenkins_by_uuid
  (dmcphers+openshiftbot@redhat.com)
- Card #185: sending app alias to all web_proxy gears (abhgupta@redhat.com)
- Bug 1048758 (dmcphers@redhat.com)
- Merge pull request #4608 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4401 from sosiouxme/bug1040257
  (dmcphers+openshiftbot@redhat.com)
- bug 1054654 (lnader@redhat.com)
- <broker> always prevent alias conflicts with app names (lmeyer@redhat.com)
- <broker> conf to allow alias under cloud domain - bug 1040257
  (lmeyer@redhat.com)
- <models/application.rb> standardize whitespace (lmeyer@redhat.com)
- Speeding up merges (dmcphers@redhat.com)
- Pairing down cuc tests (dmcphers@redhat.com)
- Pairing down cuc tests (dmcphers@redhat.com)
- Merge pull request #4596 from smarterclayton/allow_local_spec_dev
  (dmcphers+openshiftbot@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Keeping tests of same type in same group (dmcphers@redhat.com)
- Make it possible to run oo-admin-* scripts from source (ccoleman@redhat.com)
- Fixing common test case timeout (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)
- Speeding up cart test cases (dmcphers@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.16-1
- Merge pull request #4580 from pravisankar/dev/ravi/admin-repair-fixes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair: Print info related to usage errors for paid users in usage-
  refund.log (rpenta@redhat.com)
- Add begin usage ops after update-cluster/execute-connects op
  (rpenta@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.15-1
- Merge pull request #4568 from danmcp/bug1049044
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049044: Creating a single sshkey for each scalable application
  (abhgupta@redhat.com)
- Bug 1055371 (dmcphers@redhat.com)
- fix bz 1049063 - do not throw exception for status call (rchopra@redhat.com)
- Merge pull request #4555 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1056657: Fixing typo (abhgupta@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.14-1
- Adding gem to ignore list (dmcphers@redhat.com)
- Rebalancing cartridge tests (dmcphers@redhat.com)
- Add API for getting a single cartridge (lnader@redhat.com)
- Merge pull request #4551 from pravisankar/dev/ravi/bug1049626
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4543 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Rebalancing cartridge extended tests (dmcphers@redhat.com)
- Bug 1056178 - Add useful error message during node removal from district
  (rpenta@redhat.com)
- Bug 1055878: calling tidy once per gear instead of per gear per cart
  (abhgupta@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.13-1
- Add more tests around downloadable cartridges (ccoleman@redhat.com)
- Merge pull request #4531 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4536 from danmcp/bug982921
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4529 from pravisankar/dev/ravi/bug1049626
  (dmcphers+openshiftbot@redhat.com)
- Bug 1040113: Handling edge cases in cleaning up downloaded cart map Also,
  fixing a couple of minor issues (abhgupta@redhat.com)
- Bug 982921 (dmcphers@redhat.com)
- Bug 1028919 - Do not make mcollective call for unsubscribe connection op when
  there is nothing to unsubscribe (rpenta@redhat.com)
- Better error message (dmcphers@redhat.com)
- Merge pull request #4506 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1054406 (lnader@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Remove component_(start|stop|configure)_order from Mongo
  (ccoleman@redhat.com)
- Bug 1054610 - Fix total_error_count in oo-admin-chk (rpenta@redhat.com)
- Merge pull request #4504 from bparees/revert_jenkins_dl
  (dmcphers+openshiftbot@redhat.com)
- Revert "Bug 995807 - Jenkins builds fail on downloadable cartridges"
  (bparees@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)
- Merge pull request #4496 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051203 (dmcphers@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Merge pull request #4389 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4477 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4481 from abhgupta/sshkey_removal_fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4480 from abhgupta/bug_1052395
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4478 from pravisankar/dev/ravi/fix-trackusage-order
  (dmcphers+openshiftbot@redhat.com)
- Moving test to functional tests and adding request_time to send to plugin
  (abhgupta@redhat.com)
- Separating out node selection algorithm (abhgupta@redhat.com)
- Merge pull request #4437 from bparees/jenkins_dl_cart_test
  (dmcphers+openshiftbot@redhat.com)
- Bug 1035186 (dmcphers@redhat.com)
- Removing sshkeys and env_vars in pending ops (abhgupta@redhat.com)
- Fix for bug 1052395 (abhgupta@redhat.com)
- Push only begin track usage ops to the end of the op group
  (rpenta@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Merge pull request #4436 from bparees/jenkins_dl_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bug 1040700 (dmcphers@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4435 from bparees/ci_timeouts
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4429 from pravisankar/dev/ravi/usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair refactor Added repair for usage inconsistencies
  (rpenta@redhat.com)
- Use mongoid 'save\!' instead of 'save' to raise an exception in case of
  failures (rpenta@redhat.com)
- Execute track usage ops in the end for any opgroup (rpenta@redhat.com)
- redistribute some group 1 extended cartridge tests into group 4
  (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.6-1
- Mongoid error on app.save results in gear counts being out of sync
  (ccoleman@redhat.com)
- Merge pull request #4430 from worldline/default-allow-ha
  (dmcphers+openshiftbot@redhat.com)
- Add default user capability to create HA apps (filirom1@gmail.com)
- Merge pull request #4428 from mrunalp/test_routing
  (dmcphers+openshiftbot@redhat.com)
- Route changes (ccoleman@redhat.com)
- allow custom ha prefix and suffix (filirom1@gmail.com)
- Merge pull request #4421 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1047950 and bug 1047952 (abhgupta@redhat.com)
- Fix for bug 1040673 (abhgupta@redhat.com)
- Add --quiet, --create, and --logins-file to oo-admin-ctl-user
  (jliggitt@redhat.com)
- oo-admin-usage enhancements: Show aggregated usage data for the given
  timeframe. (rpenta@redhat.com)
