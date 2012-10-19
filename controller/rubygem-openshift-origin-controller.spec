%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-controller
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Controller
Name:           rubygem-%{gemname}
Version: 0.17.16
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(activemodel)
Requires:       rubygem(highline)
Requires:       rubygem(cucumber)
Requires:       rubygem(json_pure)
Requires:       rubygem(mocha)
Requires:       rubygem(mongo)
Requires:       rubygem(parseconfig)
Requires:       rubygem(state_machine)
Requires:       rubygem(dnsruby)
Requires:       rubygem(openshift-origin-common)
Requires:       rubygem(open4)
Requires:       rubygem(rcov)
Requires:       rubygem(dnsruby)
Obsoletes: 	rubygem-stickshift-controller

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Controller Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the Cloud Development Controller packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Controller packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.17.16-1
- Merge pull request #719 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- Merge pull request #720 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #718 from pravisankar/dev/ravi/bug/867775
  (openshift+bot@redhat.com)
- logging success in user_action.log file if access denied because of invalid
  credentials or insufficient previleges (abhgupta@redhat.com)
- fix for bugs 868017, 867349 (rchopra@redhat.com)
- Fix for bug# 867775 (rpenta@redhat.com)
- Fix up hot deployment test for nodejs to handle the case that supervisor
  starts up on the very first hot_deploy marker git push. (ramr@redhat.com)
- Add node.js hot deployment test (commented for now). (ramr@redhat.com)
- Merge pull request #706 from lnader/master (dmcphers@redhat.com)
- US2108: Better DNS experience (lnader@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.17.15-1
- Consistent naming (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Merge pull request #689 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #686 from lnader/master (openshift+bot@redhat.com)
- fixes for bugs 866650, 866626, 866544, 866555; also set user-agent while
  creation of apps (rchopra@redhat.com)
- US2108: Better DNS experience (lnader@redhat.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.17.14-1
- Merge pull request #681 from pravisankar/dev/ravi/bug/821107
  (openshift+bot@redhat.com)
- Merge pull request #676 from pravisankar/dev/ravi/bug/852324
  (openshift+bot@redhat.com)
- Support more ssh key types (rpenta@redhat.com)
- Fix for bug# 852324 (rpenta@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.17.13-1
- added ews tests (bdecoste@gmail.com)
- Merge pull request #668 from bdecoste/master (openshift+bot@redhat.com)
- updated ews tests (bdecoste@gmail.com)
- get_application cleanup for user-agent (rchopra@redhat.com)
- Update mysql connection URL parsing to fix tests (ironcladlou@gmail.com)
- Merge pull request #660 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #659 from ironcladlou/idler-tests
  (openshift+bot@redhat.com)
- Merge pull request #644 from bdecoste/master (openshift+bot@redhat.com)
- Merge pull request #654 from pravisankar/dev/ravi/bug/858203
  (openshift+bot@redhat.com)
- spell collocation; gear_profile in the cartridge (rchopra@redhat.com)
- fix for bug#865497 (rchopra@redhat.com)
- Don't follow redirects for health checks (ironcladlou@gmail.com)
- Fix for Bug# 858203 (rpenta@redhat.com)
- Fix for bug# 863973 (rpenta@redhat.com)
- added tests and enabled ews (bdecoste@gmail.com)
- rename max_scale/min_scale to scales_to/scales_from (rchopra@redhat.com)
- Merge pull request #619 from kraman/master (openshift+bot@redhat.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- rework set_min_max on cartridge (rchopra@redhat.com)
- Fix for 862086 (rpenta@redhat.com)
- Merge pull request #613 from kraman/master (openshift+bot@redhat.com)
- Module name and gem path fixes for auth plugins (kraman@gmail.com)

* Mon Oct 08 2012 Adam Miller <admiller@redhat.com> 0.17.12-1
- Merge pull request #607 from brenton/streamline_auth_misc1-rebase
  (openshift+bot@redhat.com)
- Minor refactoring needed to work with the hosted service
  (bleanhar@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.17.11-1
- fix obsoletes (dmcphers@redhat.com)
- set scaling info for each cart - on-prem rework (rchopra@redhat.com)
- renaming crankcase -> origin-server (dmcphers@redhat.com)
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.17.10-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.17.9-1
- Revert "Merge pull request #585 from pravisankar/dev/ravi/bug862086"
  (dmcphers@redhat.com)
- Merge pull request #592 from rajatchopra/bug_fixes (dmcphers@redhat.com)
- Merge pull request #585 from pravisankar/dev/ravi/bug862086
  (dmcphers@redhat.com)
- Merge pull request #595 from mrunalp/dev/typeless (dmcphers@redhat.com)
- on-prem rework of storage REST api (rchopra@redhat.com)
- Typeless gear changes (mpatel@redhat.com)
- BugFix# 862086 (rpenta@redhat.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.17.8-1
- provide global flag for whether analytics is enabled (dmcphers@redhat.com)
- Merge pull request #587 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- Merge pull request #584 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #581 from pravisankar/dev/ravi/bug861967
  (openshift+bot@redhat.com)
- fixing test typo and specifying parseconfig gem version to get rid of
  warnings (abhgupta@redhat.com)
- default api version is 1.2 (rchopra@redhat.com)
- Fix for bug# 861967 (rpenta@redhat.com)
- excluding nodejs tests from origin (abhgupta@redhat.com)
- Merge pull request #569 from rajatchopra/bug_fixes (openshift+bot@redhat.com)
- rest api applications controller changes - pull in from refactor for on-prem
  (rchopra@redhat.com)
- Merge pull request #562 from pravisankar/dev/ravi/subaccount-deletion
  (openshift+bot@redhat.com)
- Subaccount user deletion changes (rpenta@redhat.com)
- fixes for bugs 860993 and 861005 (rchopra@redhat.com)

* Sat Sep 29 2012 Adam Miller <admiller@redhat.com> 0.17.7-1
- Keeping the controller engine from overwriting the auth config if it's
  already set (bleanhar@redhat.com)
- Moving the broker auth test to the controller (bleanhar@redhat.com)
- Moving the openssl based generate_broker_key logic into the base AuthService
  class (bleanhar@redhat.com)

* Fri Sep 28 2012 Adam Miller <admiller@redhat.com> 0.17.6-1
- Fix bugz 860536 - gears info will not record into gear-registry.db and failed
  to redirect connection to gears when access the scalable app dns
  (ramr@redhat.com)

* Thu Sep 27 2012 Adam Miller <admiller@redhat.com> 0.17.5-1
- changes status_message to status_messages (lnader@redhat.com)
- US2754 and  US2862 part 1 (lnader@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.17.4-1
- BZ857824 The response message of do threadump to unsupported app by REST API
  need update (calfonso@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.17.3-1
- Strip colorization control characters from test output
  (ironcladlou@gmail.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.17.2-1
- fixing runtime extended cucumber tests under Origin (abhgupta@redhat.com)
- BZ857205 (bdecoste@gmail.com)
- fixing origin tests (abhgupta@redhat.com)
- Merge pull request #493 from rmillner/US2755 (admiller@redhat.com)
- US2538: Exposing scaling info in REST APIs (rchopra@redhat.com)
- New mongodb-2.2 cartridge (rmillner@redhat.com)
- adding not-origin tags to cucumber feature files (abhgupta@redhat.com)
- US2861 No threaddump API present (calfonso@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.17.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.16.5-1
- Merge pull request #472 from rajatchopra/bug_fix (openshift+bot@redhat.com)
- Merge pull request #470 from jwhonce/bz855186 (openshift+bot@redhat.com)
- ruby 1.8.7 does not have order for a hash, get around it (rchopra@redhat.com)
- Fix for Bug 855186 (jhonce@redhat.com)

* Tue Sep 11 2012 Troy Dawson <tdawson@redhat.com> 0.16.4-1
- increase mongo connection timeout (rchopra@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.16.3-1
- Fix for Bug 852268 (jhonce@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- Add <broker>/rest/environment REST call to expose env variables like
  domain_suffix, etc. (rpenta@redhat.com)
- Expose capabilities in the Rest user model (rpenta@redhat.com)
- Fix for 851345, cleanup gear group resources rest api (rpenta@redhat.com)
- Increase timeout for jenkins job (jhonce@redhat.com)
- Merge pull request #436 from danmcp/master (openshift+bot@redhat.com)
- reorg broker extended tests (dmcphers@redhat.com)
- Patch for BZ850962 (jhonce@redhat.com)
- Merge pull request #428 from jwhonce/testing (openshift+bot@redhat.com)
- optimize nolinks (dmcphers@redhat.com)
- Removed unused stepdefs (jhonce@redhat.com)
- Introduce cucumber formatter to print out unused steps (jhonce@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)
- Merge pull request #422 from brenton/gemspec_fixes3
  (openshift+bot@redhat.com)
- minor openshift-origin-controller specfix (bleanhar@redhat.com)
- lib/openshift/mongo_data_store.rb requires rubygem-mongo
  (bleanhar@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.15.11-1
- resolve merge conflicts (rpenta@redhat.com)
- Merge pull request #417 from danmcp/master (openshift+bot@redhat.com)
- more ctl usage test cases and related fixes (dmcphers@redhat.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.15.10-1
- cleanup based on test case additions (dmcphers@redhat.com)
- Merge pull request #409 from rajatchopra/master (openshift+bot@redhat.com)
- support for removing app local environment variables (rchopra@redhat.com)

* Mon Aug 20 2012 Adam Miller <admiller@redhat.com> 0.15.9-1
- Improve database cartridge runtime test coverage (ironcladlou@gmail.com)
- fix for bug#849385 (rchopra@redhat.com)
- Merge pull request #399 from abhgupta/bug/849117 (openshift+bot@redhat.com)
- fix for bug 849098 (abhgupta@redhat.com)
- fix for bug 849117 (abhgupta@redhat.com)

* Fri Aug 17 2012 Adam Miller <admiller@redhat.com> 0.15.8-1
- Merge pull request #392 from nhr/US2457_auth_changes
  (openshift+bot@redhat.com)
- Merge pull request #390 from brenton/gemspec_fixes2
  (openshift+bot@redhat.com)
- minor debug statement cleanup (dmcphers@redhat.com)
- Refactored per review feedback (nhr@redhat.com)
- US2457 Relaxed auth for cart type and app templates (nhr@redhat.com)
- Gemspec fixes for Fedora packaging (bleanhar@redhat.com)

* Fri Aug 17 2012 Adam Miller <admiller@redhat.com> 0.15.7-1
- Ported DIY cartridge to new framework (jhonce@redhat.com)
- BugZ# 848940. Fixed expose port REST event to skip calling expose-port on
  webproxy cartridge (kraman@gmail.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.15.6-1
- Merge pull request #382 from pravisankar/dev/ravi/story/US2614
  (openshift+bot@redhat.com)
- find_all() ':with_plan' option finds all users having either plan_id or
  pending_plan_id (rpenta@redhat.com)
- Changes: - Added 'pending_plan_id', 'pending_plan_uptime' fields to CloudUser
  model - Removed 'vip' field from CloudUser model - find_all() can take
  ':with_pending_plan' option to list all users with pending plan.
  (rpenta@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.15.5-1
- Merge pull request #387 from rmillner/US2102 (openshift+bot@redhat.com)
- Merge pull request #380 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- Merge pull request #385 from jwhonce/domains_controller
  (openshift+bot@redhat.com)
- US2102: Allow PostgreSQL to be embedded in a scalable application.
  (rmillner@redhat.com)
- adding rest api to fetch and update quota on gear group (abhgupta@redhat.com)
- Use correct variable name (jhonce@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.15.4-1
- Merge pull request #381 from jwhonce/testing (openshift+bot@redhat.com)
- Merge pull request #379 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #374 from rajatchopra/US2568 (openshift+bot@redhat.com)
- fixing ctl usage to handle multiple begin and end events
  (dmcphers@redhat.com)
- Merge pull request #378 from danmcp/master (openshift+bot@redhat.com)
- Runtime test Refactor (jhonce@redhat.com)
- better comment with the ssh key being added (rchopra@redhat.com)
- Bug 848083 (dmcphers@redhat.com)
- support for app-local ssh key distribution (rchopra@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.15.3-1
- Merge pull request #357 from brenton/gemspec_fixes1
  (openshift+bot@redhat.com)
- Merge pull request #365 from danmcp/master (openshift+bot@redhat.com)
- fixing broker extended tests (dmcphers@redhat.com)
- Merge pull request #363 from danmcp/master (openshift+bot@redhat.com)
- make tests use more random values (dmcphers@redhat.com)
- zend server (lnader@redhat.com)
- Bug 847248 (dmcphers@redhat.com)
- Fixing my gemspec typo (bleanhar@redhat.com)
- gemspec refactorings based on Fedora packaging feedback (bleanhar@redhat.com)
- Merge pull request #354 from rajatchopra/master (openshift+bot@redhat.com)
- fix for gear's group_instance_name being stale (rchopra@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- Increase URL matcher to 5mins (jhonce@redhat.com)
- move debugging to logger (jhonce@redhat.com)
- Refactor runtime tests to improve retry times (jhonce@redhat.com)
- Fixing a few mode issues for Fedora packaging (bleanhar@redhat.com)
- Merge pull request #345 from ironcladlou/hot-deploy-ruby
  (openshift+bot@redhat.com)
- adding not-origin tag to postgres cucumber feature and specifying complete
  path for ip program (abhgupta@redhat.com)
- Enable hot deployment support for Ruby cartridges (ironcladlou@gmail.com)
- Fixing comments (dmcphers@redhat.com)
- Deregister DNS when domain creation fails at mongo layer (rpenta@redhat.com)
- Merge pull request #318 from pravisankar/dev/ravi/story/US1896
  (kraman@gmail.com)
- Added 'nolinks' parameter to suppress link generation in the REST API replies
  to make the output terse and improve general processing speed
  (rpenta@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Wed Aug 01 2012 Adam Miller <admiller@redhat.com> 0.14.15-1
- fix syntax (dmcphers@redhat.com)
- Split tests to allow granular retries (jhonce@redhat.com)

* Tue Jul 31 2012 Dan McPherson <dmcphers@redhat.com> 0.14.14-1
- clearing save jobs too early (dmcphers@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.14.13-1
- send mcollective requests to multiple nodes at the same time
  (dmcphers@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.14.12-1
- Don't allow more than one domain for the user (rpenta@redhat.com)
- fix for bug#844490 - max_gears consistency check need not apply when
  decrementing consumed_gears (rchopra@redhat.com)

* Mon Jul 30 2012 Dan McPherson <dmcphers@redhat.com> 0.14.11-1
- Merge pull request #299 from pravisankar/dev/ravi/bug/813660
  (abhgupta@redhat.com)
- Fix for bug# 813660 (rpenta@redhat.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.14.10-1
- Merge pull request #293 from jwhonce/node_steps (ironcladlou@gmail.com)
- restore lifecycle nodejs steps (jhonce@redhat.com)
- Fixed nil object error when destroying an application what has not been
  elaborated yet (kraman@gmail.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.14.9-1
- fix typo (dmcphers@redhat.com)
- keep usage_records out of the db unless there are entries
  (dmcphers@redhat.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.14.8-1
- Bug 843710 (dmcphers@redhat.com)
- restrict to single jenkins (bdecoste@gmail.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.14.7-1
- Runtime cucumber test refactor (ironcladlou@gmail.com)
- Mongo deleted_gears fix (rpenta@redhat.com)
- Fixes for Bug 806824 (kraman@gmail.com)
- Merge pull request #265 from kraman/dev/kraman/bugs/806824
  (dmcphers@redhat.com)
- take the highest priority component for each gear in deconfigure
  (dmcphers@redhat.com)
- still needed this deconfigure (dmcphers@redhat.com)
- Stop calling deconfigure on destroy (dmcphers@redhat.com)
- US2397 (dmcphers@redhat.com)
- Bug 806824 - [REST API] clients should be able to get informed about reserved
  application names (kraman@gmail.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.14.6-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-port-proxy out of cartridge hooks and into node. (rmillner@redhat.com)
- Generate fields in the descriptor only if they are not empty or default value
  (kraman@gmail.com)
- Bug 842267 (dmcphers@redhat.com)
- Rebalance threading for runtime tests (jhonce@redhat.com)
- adjust when tests run (jhonce@redhat.com)
- reorg runtime tests into 4 groups (dmcphers@redhat.com)

* Fri Jul 20 2012 Adam Miller <admiller@redhat.com> 0.14.5-1
- Bug 841073 (dmcphers@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- auth_key/iv for java client (bdecoste@gmail.com)
- Move lifecycle tests for php and ruby to libra_check (jhonce@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Merge pull request #244 from rmillner/dev/rmillner/bug/834668
  (mrunalp@gmail.com)
- test case reorg (dmcphers@redhat.com)
- BZ 834668: Dynect call to determine if domain is available not protected from
  exceptions. (rmillner@redhat.com)
- reorg some tests (short term fix) (dmcphers@redhat.com)
- Fix for bug 816020 (abhgupta@redhat.com)
- Merge pull request #240 from abhgupta/abhgupta-dev (kraman@gmail.com)
- Merge pull request #232 from lnader/master (rpenta@redhat.com)
- fix for cartridge-jenkins_build.feature cucumber test (abhgupta@redhat.com)
- Mongo safety check during deletion of app gears. If 2 requests are deleting
  the same gear, this check will ensure that one will succeed and the other
  will throw an error as expected. (rpenta@redhat.com)
- US2427: Broker add / change plan REST API (lnader@redhat.com)

* Fri Jul 13 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- several fixes related to migrations (dmcphers@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.13.14-1
- Merge pull request #228 from rajatchopra/master (admiller@redhat.com)
- Merge pull request #224 from kraman/dev/kraman/bugs/838611
  (rpenta@redhat.com)
- fix for Bug 836973  - Sometimes jbossas-7 auto scaling up doesn't work fine
  (rchopra@redhat.com)
- nicer error on user reaching max gear limit when creating scalable app
  (rchopra@redhat.com)
- Bump API version to 1.1. New version returns framework cartridge and related
  properties when listing cartridges for an app
  (.../applications/<id>/cartridges) Builds upon cartridge metadata which was
  added in 47d1b813a1a74228c9c95734043487d681f799d4. (kraman@gmail.com)
- Merge pull request #222 from pravisankar/dev/ravi/bug/834351
  (rchopra@redhat.com)
- Merge pull request #223 from abhgupta/abhgupta-dev (lnader@redhat.com)
- Merge pull request #212 from lnader/master (abhgupta@redhat.com)
- Commented current code related to checking gear scale limits in mongo to
  unblock the build. Proper fix comming soon. (rpenta@redhat.com)
- Fix for bug 839151 (abhgupta@redhat.com)
- Bug 838862 - add events to application dose not check the domain name in the
  URL (lnader@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.13.13-1
- Merge pull request #220 from pravisankar/dev/ravi/bug806273
  (abhgupta@redhat.com)
- minor text change: example cart as mongodb instead of metrics
  (rpenta@redhat.com)
- - Don't show postgresql-8.4 as valid options to embed cartridge when mysql is
  already installed and viceversa. (rpenta@redhat.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.13.12-1
- Add modify application dns and use where applicable (dmcphers@redhat.com)
- Merge pull request #209 from lnader/master (rmillner@redhat.com)
- Merge pull request #207 from pravisankar/dev/ravi/bug/834663
  (rchopra@redhat.com)
- Merge pull request #208 from pravisankar/dev/ravi/bug/835176
  (rchopra@redhat.com)
- Added test to cover Bug 838627 (lnader@redhat.com)
- Bug 837926 - changed application_template to application_templates
  (lnader@redhat.com)
- Application Gear min/max scaling limit check will also be done in mongo
  layer. (rpenta@redhat.com)
- Add gear will do cleanup in case of failures due to DNS timeouts/errors
  (rpenta@redhat.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.13.11-1
- remove any failable logic from track gear usage (dmcphers@redhat.com)

* Mon Jul 09 2012 Adam Miller <admiller@redhat.com> 0.13.10-1
- fix for bug#838694 - jenkins cartridge info is not shown in cartridge REST
  call (rchopra@redhat.com)
- blocking requires/conflicts/suggests/depends from RestCartridge model until
  further agreement on cartridge metadata is made (rchopra@redhat.com)

* Mon Jul 09 2012 Adam Miller <admiller@redhat.com> 0.13.9-1
- added missing attr accessor (lnader@redhat.com)

* Mon Jul 09 2012 Adam Miller <admiller@redhat.com> 0.13.8-1
- Merge pull request #201 from lnader/master (lnader@redhat.com)
- added max_gears to rest user and corrected parameter desc (lnader@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.13.7-1
- Merge pull request #191 from abhgupta/abhgupta-dev (kraman@gmail.com)
- fix for bug#837579 - handle better messaging on find_available_node failure
  (rchopra@redhat.com)
- fixes to cucumber test runs on OpenShift Origin (abhgupta@redhat.com)

* Fri Jul 06 2012 Adam Miller <admiller@redhat.com> 0.13.6-1
- changing categories to tags for site functional tests (rchopra@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.13.5-1
- Merge pull request #182 from pravisankar/dev/ravi/bug/806273
  (admiller@redhat.com)
- changes identified after writing integration tests (abhgupta@redhat.com)
- Fix for Bug 806273 (rpenta@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)
- Fix for bug#812802 (rpenta@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- More fixes to bug# 808425 (rpenta@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)
- Fix for Bug# 808425 (rpenta@redhat.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Removed destroyed_gears during querying mongo (rpenta@redhat.com)
- BugFix: 812800 (rpenta@redhat.com)
- Merge remote-tracking branch 'upstream/master' (rpenta@redhat.com)
- remove whitespaces (rchopra@redhat.com)
- fix for gear delete/add from group instance (rchopra@redhat.com)
- rejig gear saving flow. now save to mongo happens before create (with
  required rollback on failure). also, destroy failures are not ignored (the
  mongo entry will still exist). (rchopra@redhat.com)
- Fix for bug# 796458 (rpenta@redhat.com)
- BugFixes: 824973, 805983, 796458 (rpenta@redhat.com)
- better error message (dmcphers@redhat.com)
- Bug 834720 - Include the message at the rest level as well
  (dmcphers@redhat.com)
- Bug 834720 (dmcphers@redhat.com)
- rearrange tests (dmcphers@redhat.com)

* Thu Jun 21 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Enable ruby-1.9 cartridge is list of frameworks, bug fixes + cucumber tests.
  (ramr@redhat.com)
- Merge pull request #156 from abhgupta/abhgupta-dev (admiller@redhat.com)
- remove base m2_repository (dmcphers@redhat.com)
- Fix for bug 830642 (abhgupta@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.12.12-1
- Merge pull request #151 from rajatchopra/master (smitram@gmail.com)
- fix for build break - configure order is not random anymore (picked up from
  requires) (rchopra@redhat.com)
- reverse check on colocate with (dmcphers@redhat.com)
- Bug 833697 (dmcphers@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.12.11-1
- fix for bug#832745 and bug#833376 (rchopra@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.12.10-1
- bug 800188 (dmcphers@redhat.com)
- Fix for bug 806713 (abhgupta@redhat.com)

* Mon Jun 18 2012 Adam Miller <admiller@redhat.com> 0.12.9-1
- Merge pull request #136 from abhgupta/gearip (kraman@gmail.com)
- Bug 830656 - Update message for bad cartridge type to match current command
  line options (ccoleman@redhat.com)
- Fixes for bug 827337, 830309, 811066, and 832374 Exposing initial public ip
  in the rest response for application creation (abhgupta@redhat.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.12.8-1
- switch to using utc time (dmcphers@redhat.com)
- Fix for bug 812046 (abhgupta@redhat.com)
- Add hot deployment support via hot_deploy marker (dmace@redhat.com)
- Trap error case when user tried to specify subaccount but parent account
  cannot be found. Returning 401 instead of 500. (kraman@gmail.com)
- Checkpoint ruby-1.9 work (ruby-1.9 disabled for now in framework cartridges).
  Automatic commit of package [cartridge-ruby-1.9] release [0.1.1-1]. Match up
  spec file to first build version in brew and checkpoint with
  working/available ruby193 packages. (ramr@redhat.com)
- Adding ability to use sub-users using X-impersonate-user header Changes to
  query subaccounts by parent login (kraman@gmail.com)

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.12.7-1
- support for group overrides so that we do not rely on filesystem co-location
  - fix for bug#824124 (rchopra@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.12.6-1
- Strip out the unnecessary gems from rcov reports and focus it on just the
  OpenShift code. (rmillner@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- Fix missing requires (kraman@gmail.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- change rest test to verify from internal (dmcphers@redhat.com)
- Merge pull request #113 from lnader/master (dmcphers@redhat.com)
- added mini test for REST API workflow with @internals and @internals1 tag
  (lnader@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- registering users using ss-register-user in cucumber tests before creating
  domain/app (abhgupta@redhat.com)
- generating new ssh keys for cucumber tests instead of storing them in the
  repo (abhgupta@redhat.com)
- Bug fixes (abhgupta@redhat.com)
- allow helper methods to be used by all the code (dmcphers@redhat.com)
- deconfigure jboss after cucumber scenario (bdecoste@gmail.com)
- Revert "BZ824124 remove unused doc_root connector" (kraman@gmail.com)
- BZ824124 remove unused doc_root connector (jhonce@redhat.com)
- Updated gem info for rails 3.0.13 (admiller@redhat.com)
- US2307 - update test scenario names (bdecoste@gmail.com)
- US2307 - enable eap6 (bdecoste@gmail.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- fixes to cucumber tests to run under OpenShift Origin (abhgupta@redhat.com)
- add beginnings of broker integration tests (dmcphers@redhat.com)
- Add test step which verifies phpmyadmin httpd proxy configuration
  (dmace@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bumping spec versions (admiller@redhat.com)
- Passing back client message from update_namespace hook (kraman@gmail.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.11.20-1
- Merge pull request #94 from mrunalp/master (dmcphers@redhat.com)
- Merge pull request #89 from abhgupta/bz822722 (dmcphers@redhat.com)
- Support for customizing error pages in diy. (mpatel@redhat.com)
- Merge pull request #85 from abhgupta/bz823675 (mmcgrath+openshift@redhat.com)
- Merge pull request #84 from abhgupta/bz820337 (mmcgrath+openshift@redhat.com)
- Typo: used else if vs elsif (abhgupta@redhat.com)
- Fix for bug 822722 - Handling boolean as well as string input values for
  boolean parameters in rest controllers (abhgupta@redhat.com)
- Merge pull request #82 from kraman/dev/kraman/bugs/801923
  (mmcgrath+openshift@redhat.com)
- More strict regular expression to match cartridge names (kraman@gmail.com)
- Fix for bug 823675 - Exposing gear count in application and consumed gears in
  user object via rest calls (abhgupta@redhat.com)
- added cucumber test case for testing invalid application server alias
  (abhgupta@redhat.com)
- handling user exceptions separately and returning 400 instead of 500 HTTP
  response code (abhgupta@redhat.com)
- Fix for bug 820337 - validating against invalid server alias in the
  application model (abhgupta@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)
- Merge pull request #80 from kraman/dev/kraman/bugs/801923
  (mmcgrath+openshift@redhat.com)
- Fixed id constraint to account for period characters in cartridge name.
  (kraman@gmail.com)
- Merge pull request #75 from abhgupta/bz817172 (mmcgrath+openshift@redhat.com)
- Merge pull request #77 from rajatchopra/master
  (mmcgrath+openshift@redhat.com)
- Merge pull request #70 from kraman/dev/kraman/bugs/824521
  (mmcgrath+openshift@redhat.com)
- fix for bug#826002 (rchopra@redhat.com)
- Adding a dependency resolution step (using post-recieve hook) for all
  applications created from templates. Simplifies workflow by not requiring an
  additional git pull/push step Cucumber tests (kraman@gmail.com)
- Bug 821299 (dmcphers@redhat.com)
- Merge pull request #74 from rajatchopra/master (dmcphers@redhat.com)
- add extra catch on gear.create to handle any exception that might get thrown
  by future piece of code (rchopra@redhat.com)
- Fix for bug 817172 - adding gear profile on gear_groups rest call
  (abhgupta@redhat.com)
- addition to the earlier fix - in the corner case where ngears does not get
  incremented on create but gets decremented on destroy (rchopra@redhat.com)
- fix for bug#821972 (rchopra@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.11.19-1
- This broke the build. BZ 824312 is being revisited. (admiller@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.11.18-1
- Bugzilla ticket 824312 has been resolved. (rmillner@redhat.com)

* Fri May 25 2012 Dan McPherson <dmcphers@redhat.com> 0.11.17-1
- Merge pull request #66 from abhgupta/agupta-dev (dmcphers@redhat.com)
- haproxy should not be allowed to be removed from a scalable app
  (rchopra@redhat.com)
- Fix for Bugz 825366, 825340. SELinux changes to allow access to
  user_action.log file. Logging authentication failures and user creation for
  OpenShift Origin (abhgupta@redhat.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.11.16-1
- fix for bug#822080 and jboss cartridge now has a scaling minimum of 1
  (rchopra@redhat.com)
- Merge pull request #46 from rajatchopra/master (kraman@gmail.com)
- max limit check should guard against -1 as a valid limit (rchopra@redhat.com)
- logic to check on scaling limits copied to haproxy_ctld (rchopra@redhat.com)
- code for min_gear setting (rchopra@redhat.com)

* Fri May 25 2012 Dan McPherson <dmcphers@redhat.com> 0.11.15-1
- fix build (dmcphers@redhat.com)

* Thu May 24 2012 Dan McPherson <dmcphers@redhat.com> 0.11.14-1
- Merge pull request #58 from pravisankar/master (dmcphers@redhat.com)
- Incorrect rollback in my previous checkin (rpenta@redhat.com)
- fix typo (dmcphers@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.13-1
- Merge pull request #57 from pravisankar/master (admiller@redhat.com)
- Disable mongodb put_domain change (rpenta@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.12-1
- Merge pull request #56 from pravisankar/master (admiller@redhat.com)
- Rollback change: update consumed_gears during delete app We are not updating
  consumed_gears during delete_app, need to check if transactional integrity is
  maintaned or not (rpenta@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.11-1
- Merge pull request #55 from pravisankar/master (dmcphers@redhat.com)
- -Fixes:  save domain: Changes to domain must update both user.domains and
  user.apps.domain in the mongo database.  delete app: Must decrement
  consumed_gears for the user in mongo db. (rpenta@redhat.com)
- US2307 - disabled eap cucumber tests (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- Merge pull request #47 from abhgupta/agupta-dev (kraman@gmail.com)
- Merge branch 'master' of https://github.com/openshift/origin-server
  (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- changes for logging user actions to a separate log file (abhgupta@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- US2307 (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
- throw a failure when creation isn't functioning (mmcgrath@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.10-1
- Revert "Broke the build, the tests have not been update to reflect this
  changeset." (ramr@redhat.com)
- Broke the build, the tests have not been update to reflect this changeset.
  (admiller@redhat.com)

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.11.9-1
- 

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.11.8-1
- 

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.11.7-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Waiting on bugzilla ticket 824312 (rmillner@redhat.com)
- [mpatel+ramr] Fix issues where app_name is not the same as gear_name - fixup
  for typeless gears. (ramr@redhat.com)
- enable gear usage syncing (dmcphers@redhat.com)
- stop setting global temp dir (dmcphers@redhat.com)
- The test was fixed in commit a7afa77. (rmillner@redhat.com)
- Any test which waits for a DNS name to be created or deleted must take
  caching into account.  While checking for a record to disappear; you may have
  to wait up till the TTL of the record for caches to expire.
  (rmillner@redhat.com)
- App creation time has been steadily increasing so that we are sometimes
  hitting the old limit. (rmillner@redhat.com)
- This test relies on DNS but ignores record TTL causing false failures.
  (rmillner@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Revert "The grep should return not found since the namespace was deleted."
  (rmillner@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.11.6-1
- The grep should return not found since the namespace was deleted.
  (rmillner@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.11.5-1
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Automatic commit of package [rubygem-openshift-origin-controller] release
  [0.11.2-1]. (admiller@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- more shuffling of tests (dmcphers@redhat.com)
- increase a couple of timeouts (dmcphers@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- The rhc tools still require ~/.openshift/express.conf.  Create the file as a
  precursor to using them. (rmillner@redhat.com)
- Updated jenkins_steps to reflect new testing methods (jhonce@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- adding test cases for gear_groups rest api and changing tag from cartridge to
  cartridges as it is a list (abhgupta@redhat.com)
- fixing file permissions - controller should not have execute permission
  (abhgupta@redhat.com)
- fix for bug 811221 - when deleting a non-existent domain name, the exit code
  was being returned as 0 (abhgupta@redhat.com)
- adding link to get gear groups in the application object rest response
  (abhgupta@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Bug fixes to get tests running - mysql and python fixes, delete user dirs
  otherwise rhc-accept-node fails and tests fail. (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Report back the allowed sizes for the specific user and mention contacting
  support for access to additional sizes. (rmillner@redhat.com)
- Automatic commit of package [rubygem-openshift-origin-controller] release
  [0.10.5-1]. (admiller@redhat.com)
- Bugz806935. Print application deletion message even if cartridges return
  information. (kraman@gmail.com)
- Fix up cuke tests for first round of typeless gear changes. (ramr@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.11.4-1
- add usage observer (dmcphers@redhat.com)
- Cucumber tests for US2135 - package.json support. (ramr@redhat.com)
- stop setting global temp dir from php test (dmcphers@redhat.com)
- Merge pull request #41 from mrunalp/master (smitram@gmail.com)
- Minor fix. (mpatel@redhat.com)
- remove too verbose debug (dmcphers@redhat.com)
- Changes to make mongodb run in standalone gear. (mpatel@redhat.com)

* Fri May 18 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- test simplification (dmcphers@redhat.com)
- test simplification (dmcphers@redhat.com)
- more timeout tweaking (dmcphers@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Add update namespace support for scalable apps. (ramr@redhat.com)
- more shuffling of tests (dmcphers@redhat.com)
- increase a couple of timeouts (dmcphers@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- better test balancing (dmcphers@redhat.com)
- get tests running faster (dmcphers@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (rpenta@redhat.com)
- Fix for bug# 812060 (rpenta@redhat.com)
- Merge pull request #38 from markllama/ss-dns-provider (kraman@gmail.com)
- App creation: set default node profile to 'small' if not specified
  (rpenta@redhat.com)
- allow syslog output for gear usage (dmcphers@redhat.com)
- proper usage of OpenShift::Model and beginnings of usage tracking
  (dmcphers@redhat.com)
- The rhc tools still require ~/.openshift/express.conf.  Create the file as a
  precursor to using them. (rmillner@redhat.com)
- made dns_service @ss_dns_provider consistent with openshift-origin-dns-bind
  (mlamouri@redhat.com)
- Merge pull request #36 from rmillner/master (kraman@gmail.com)
- Bugz# 804937. REST api was returning exitcode 143 instead of the cartridge
  specific error code. (kraman@gmail.com)
- Add rcov testing to the Stickshift broker, common and controller.
  (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- Merge pull request #28 from abhgupta/abhgupta-dev2 (dmcphers@redhat.com)
- Merge pull request #35 from rmillner/master (dmcphers@redhat.com)
- adding test cases for gear_groups rest api and changing tag from cartridge to
  cartridges as it is a list (abhgupta@redhat.com)
- bumping spec versions (admiller@redhat.com)
- We already validate the gear size elswhere based on the user information.
  Remove the hard-coded list of node types.  As a side effect; we can't check
  invalid gear sizes in unit tests. (rmillner@redhat.com)
- fixing file permissions - controller should not have execute permission
  (abhgupta@redhat.com)
- fix for bug 811221 - when deleting a non-existent domain name, the exit code
  was being returned as 0 (abhgupta@redhat.com)
- adding link to get gear groups in the application object rest response
  (abhgupta@redhat.com)

* Wed May 09 2012 Adam Miller <admiller@redhat.com> 0.10.7-1
- Merge pull request #34 from kraman/dev/kraman/bug/819984 (kraman@gmail.com)
- Bugfix for scaled applications (kraman@gmail.com)
- Merge pull request #30 from kraman/dev/kraman/bug/819984
  (dmcphers@redhat.com)
- Adding logic to handle mysql gear. Executing domain-update hook on every
  gear. (kraman@gmail.com)
- Merge branch 'master' of github.com:openshift/origin-server (rchopra@redhat.com)
- fix for bug#820024 (rchopra@redhat.com)
- Simplifying some reduntant code blocks (kraman@gmail.com)
- Adding back cartridge command processing (kraman@gmail.com)
- Update gear dns entried when app namespace is updated (kraman@gmail.com)

* Wed May 09 2012 Adam Miller <admiller@redhat.com> 0.10.6-1
- Report back the allowed sizes for the specific user and mention contacting
  support for access to additional sizes. (rmillner@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- Merge pull request #27 from kraman/dev/kraman/bug/806935
  (dmcphers@redhat.com)
- Bugz806935. Print application deletion message even if cartridges return
  information. (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.4-1
- Merge pull request #25 from abhgupta/abhgupta-dev (kraman@gmail.com)
- adding cucumber tests for gear groups rest api (abhgupta@redhat.com)
- additional changes for showing gear states in gear_groups rest api
  (abhgupta@redhat.com)
- Merge branch 'master' of github.com:openshift/origin-server (lnader@redhat.com)
- minor fix in domain logging (lnader@redhat.com)
- Merge pull request #23 from kraman/dev/kraman/bug/819443
  (dmcphers@redhat.com)
- Bugfix 819443 (kraman@gmail.com)
- Merge branch 'master' of github.com:openshift/origin-server (lnader@redhat.com)
- adding gear state to gear_groups rest api (abhgupta@redhat.com)
- Merge pull request #18 from kraman/dev/kraman/bug/814444
  (dmcphers@redhat.com)
- Updated embedded cart controller to only return a single message.
  (kraman@gmail.com)
- Adding a seperate message for errors returned by cartridge when trying to add
  them. Fixing CLIENT_RESULT error in node Removing tmp editor file
  (kraman@gmail.com)
- Bug 815554 (lnader@redhat.com)
- Bug 815554 (lnader@redhat.com)
- Bug 815554 (lnader@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- Revert "BugZ 818896. Making app name search case in-sensitive"
  (kraman@gmail.com)
- Merge pull request #17 from kraman/Bug818896 (dmcphers@redhat.com)
- Changing cartridge type attribute to name to remain consistent with rest of
  API (kraman@gmail.com)
- BugZ 818896. Making app name search case in-sensitive (kraman@gmail.com)
- Adding a new REST endpoint for gear group information (kraman@gmail.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)
- Validate ssh key type against the whole string rather than a line
  (dmcphers@redhat.com)
- moving broker auth key and iv encoding/decoding both into the plugin
  (abhgupta@redhat.com)
- changes to cucumber tests to make them work for OpenShift Origin
  (abhgupta@redhat.com)
- potential fix for bug#800188 (rchopra@redhat.com)

* Fri Apr 27 2012 Krishna Raman <kraman@gmail.com> 0.10.2-1
- Fix scalable param in response for GET applications rest api
  (rpenta@redhat.com)
- added tomdoc info for remove_dns (mmcgrath@redhat.com)
- abstracting permissions functions (mmcgrath@redhat.com)
- Merge branch 'php-tests' (mmcgrath@redhat.com)
- additional test breakout (mmcgrath@redhat.com)
- adding new php tests (mmcgrath@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Wed Apr 25 2012 Adam Miller <admiller@redhat.com> 0.9.12-1
- set uid in gear.new constructor; fix for bug#813244 (rchopra@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.9.11-1
- Forgot to end my blocks. (rmillner@redhat.com)
- The hooks are now called on each cartridge on each gear for an app but not
  every cartridge has or should have them.  Was causing an error.
  (rmillner@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.10-1
- fix for bug#810276 - an unhandled exception cannot be expected to have a
  'code' field (rchopra@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.9-1
- cleaning up spec files (dmcphers@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.8-1
- Merge branch 'master' of github.com:openshift/origin-server (lnader@redhat.com)
- Bug 814379 - invalid input being sent back to the client (lnader@redhat.com)
- show/conceal/expose port should not act upon app components
  (rchopra@redhat.com)
- support for group overrides (component colocation really). required for
  transition between scalable/non-scalable apps (rchopra@redhat.com)
- Enhanced cucumber jenkins build test  * rewrote tests to fail if git
  push/jenkins cartridge blocks forever  * added tests to broker tags
  (jhonce@redhat.com)
- move origin-server mongo datastore (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.7-1
- forcing builds (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.5-1
- new package built with tito
