%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-controller
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Controller
Name:           rubygem-%{gemname}
Version: 0.13.5
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
Requires:       rubygem(parseconfig)
Requires:       rubygem(state_machine)
Requires:       rubygem(dnsruby)
Requires:       rubygem(stickshift-common)
Requires:       rubygem(open4)
Requires:       rubygem(rcov)
Requires:       rubygem(dnsruby)

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
  gearchanger plugin - Added mcollective agent and facter plugins - Added
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
- Merge branch 'master' of https://github.com/openshift/crankcase
  (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- Merge pull request #47 from abhgupta/agupta-dev (kraman@gmail.com)
- Merge branch 'master' of https://github.com/openshift/crankcase
  (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- changes for logging user actions to a separate log file (abhgupta@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (mmcgrath@redhat.com)
- US2307 (bdecoste@gmail.com)
- US2307 (bdecoste@gmail.com)
- Merge branch 'master' of github.com:openshift/crankcase (mmcgrath@redhat.com)
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
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
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
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
- Revert "The grep should return not found since the namespace was deleted."
  (rmillner@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.11.6-1
- The grep should return not found since the namespace was deleted.
  (rmillner@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.11.5-1
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- Automatic commit of package [rubygem-stickshift-controller] release
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
- Automatic commit of package [rubygem-stickshift-controller] release
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
- Merge branch 'master' of github.com:openshift/crankcase (rpenta@redhat.com)
- Fix for bug# 812060 (rpenta@redhat.com)
- Merge pull request #38 from markllama/ss-dns-provider (kraman@gmail.com)
- App creation: set default node profile to 'small' if not specified
  (rpenta@redhat.com)
- allow syslog output for gear usage (dmcphers@redhat.com)
- proper usage of StickShift::Model and beginnings of usage tracking
  (dmcphers@redhat.com)
- The rhc tools still require ~/.openshift/express.conf.  Create the file as a
  precursor to using them. (rmillner@redhat.com)
- made dns_service @ss_dns_provider consistent with uplift-bind-plugin
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
- Merge branch 'master' of github.com:openshift/crankcase (rchopra@redhat.com)
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
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
- minor fix in domain logging (lnader@redhat.com)
- Merge pull request #23 from kraman/dev/kraman/bug/819443
  (dmcphers@redhat.com)
- Bugfix 819443 (kraman@gmail.com)
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
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
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
- Bug 814379 - invalid input being sent back to the client (lnader@redhat.com)
- show/conceal/expose port should not act upon app components
  (rchopra@redhat.com)
- support for group overrides (component colocation really). required for
  transition between scalable/non-scalable apps (rchopra@redhat.com)
- Enhanced cucumber jenkins build test  * rewrote tests to fail if git
  push/jenkins cartridge blocks forever  * added tests to broker tags
  (jhonce@redhat.com)
- move crankcase mongo datastore (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.7-1
- forcing builds (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.5-1
- new package built with tito

