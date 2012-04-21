%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-controller
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Controller
Name:           rubygem-%{gemname}
Version:        0.9.3
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
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.9.3-1
- 1) removing cucumber gem dependency from express broker. 2) moved ruby
  related cucumber tests back into express. 3) fixed issue with broker
  Gemfile.lock file where ruby-prof was not specified in the dependency
  section. 4) copying cucumber features into li-test/tests automatically within
  the devenv script. 5) fixing ctl status script that used ps to list running
  processes to specify the user. 6) fixed tidy.sh script to not display error
  on fedora stickshift. (abhgupta@redhat.com)
- Expanded jenkins automated testing (jhonce@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- fixing haproxy gem error (mmcgrath@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Update application ngears before calling gear destroy so that even if destroy
  op fails, we update consumed_gears properly. (rpenta@redhat.com)
- removing some unconfined_t's (mmcgrath@redhat.com)
- Added cucumber as a development dependency Disabled show/concel port tests in
  OSS code (kraman@gmail.com)
- Changes to get gearchanger-oddjob selinux and misc other changes to configure
  embedded carts succesfully (kraman@gmail.com)
- Fixes to run tests on OSS code (kraman@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.9.2-1
- Updating gem versions (mmcgrath@redhat.com)
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.14-1
- Updating gem versions (mmcgrath@redhat.com)
- Check the output of show-port rather than its exit code.
  (rmillner@redhat.com)
- Added timing info to runcon (mmcgrath@redhat.com)
- Temporary commit to build (mmcgrath@redhat.com)
- php testing efficiencies (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.8.13-1
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- added exit code check (mmcgrath@redhat.com)
- fix mongo put_app where ngears < 0; dont save an app after
  deconfigure/destroy if it has not persisted, because the destroy might have
  been called for a failure upon save (rchopra@redhat.com)
- Bug fix: 809467 (rpenta@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.12-1
- Updating gem versions (mmcgrath@redhat.com)
- Fix domain controller errors and related cucumber tests (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 811139 (rpenta@redhat.com)

* Tue Apr 10 2012 Adam Miller <admiller@redhat.com> 0.8.11-1
- Updating gem versions (admiller@redhat.com)
- Adding checks to prevent creation of multiple domains for a user
  (kraman@gmail.com)
- Fix for Bug# 807513 (rpenta@redhat.com)
- Partial fix for 806401 (kraman@gmail.com)

* Tue Apr 10 2012 Adam Miller <admiller@redhat.com> 0.8.10-1
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (admiller@redhat.com)
- Fix for bug# 809467 (rpenta@redhat.com)

* Tue Apr 10 2012 Adam Miller <admiller@redhat.com> 0.8.9-1
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix REST domain cucumber tests (rpenta@redhat.com)
- bug 810475 (bdecoste@gmail.com)
- Bugz 810931. Changing REST API params and Application structure to accept
  gear_profile instead of node_profile (kraman@gmail.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.8-1
- Updating gem versions (mmcgrath@redhat.com)
- BugzID 811141. Fixed spelling (kraman@gmail.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.7-1
- Updating gem versions (mmcgrath@redhat.com)
- This was breaking the build (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.6-1
- Updating gem versions (mmcgrath@redhat.com)
- disabling registration_required. (mmcgrath@redhat.com)

* Mon Apr 09 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.5-1
- Updating gem versions (mmcgrath@redhat.com)
- updated tests changed namespace to id (lnader@redhat.com)
- dont register dns for haproxy gear twice over (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 807513 (rpenta@redhat.com)

* Mon Apr 09 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.4-1
- Updating gem versions (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- gearname is the appname for haproxy gear in scalable apps. NOTE : this
  checkin assumes that haproxy can nicely re-use the framework's httpd
  (rchopra@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- bug fix in absolute URLs (lnader@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- moving ruby, rockmongo, and phpmoadmin cartridge tests back under express as
  these cartridges will not be made available to stickshift
  (abhgupta@redhat.com)
- corrected error code (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- fixed get_execute_connector_job signature (wdecoste@localhost.localdomain)
- REST API absolute URLs (lnader@redhat.com)
- Add miscellaneous options to app creation (used in benchmarking app creation
  to turn off git+dns). (ramr@redhat.com)
- Merge remote-tracking branch 'origin/master' into dev/kraman/US2048
  (kraman@gmail.com)
- Add a new direct route to stickshift to allow domain updates to provide the
  old :id attribute instead of having to send a new attribute Return 'id' as
  the attribute for namespace errors Add stickshift directory to the watch
  synchronization folder (ccoleman@redhat.com)
- fixing command_helper that was causing a couple of verification cucumber
  tests to fail (abhgupta@redhat.com)
- moving bulk of the cucumber tests under stickshift and making changes so that
  tests can be run both on devenv with express  as well as with opensource
  pieces on the fedora image (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Changes: - For domain object, 'namespace' will be referred as 'id' in the
  REST api. - For application object, 'namespace' will be referred as
  'domain_id' in the REST api (rpenta@redhat.com)
- let deconfigure failure not stop the app destroy (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' (kraman@gmail.com)
- Merge remote-tracking branch 'origin/master' (kraman@gmail.com)
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- 1) changes to fix remote job creation to work for express as well as
  stickshift.  2) adding resource_limits.conf file to stickshift node.  3)
  adding implementations of generating remote job objects in mcollective
  application container proxy (abhgupta@redhat.com)
- Moving user creating into authenticate method instead of auth_service
  (kraman@gmail.com)
- Pulling parallel job changes into stickshift (kraman@gmail.com)
- Adding m-collective and oddjob gearchanger plugins (kraman@gmail.com)
- Created Crankcase Mongo plugin (kraman@gmail.com)

* Wed Apr 04 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.3-1
- Updating gem versions (mmcgrath@redhat.com)
- test commit (mmcgrath@redhat.com)

* Tue Apr 03 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.2-1
- Updating gem versions (mmcgrath@redhat.com)
- dont restart jboss on scale-up/down (bdecoste@gmail.com)
- During app creation, if save record to mongo fails cleanup the app properly.
  (rpenta@redhat.com)
- Check for domain existence before adding app info to mongo
  (rpenta@redhat.com)
- Fix for bugz 808671 - altering domain fails after embedding a cartridge.
  Sigh, this renaming has left a lot of loose ends. (ramr@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.8.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 29 2012 Dan McPherson <dmcphers@redhat.com> 0.7.7-1
- Updating gem versions (dmcphers@redhat.com)
- Fix for bug# 806814 (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- One more fix for bug# 807559 (rpenta@redhat.com)
- perf improvement (dmcphers@redhat.com)
- batch adding broker auth key (dmcphers@redhat.com)
- Fix for bug# 807045 (rpenta@redhat.com)
- Fix for bug# 807559 (rpenta@redhat.com)
- Fix internal server errors in applications controller (rpenta@redhat.com)

* Wed Mar 28 2012 Dan McPherson <dmcphers@redhat.com> 0.7.6-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bugs 805960 and 805980 (lnader@redhat.com)

* Wed Mar 28 2012 Dan McPherson <dmcphers@redhat.com> 0.7.5-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Haproxy is no longer a framework, its embedded. (rmillner@redhat.com)
- Bug 807543 - Keys with the same content can be added in website console.
  (lnader@redhat.com)
- cosmetics in debug statement; fix for broken cartridge configure not getting
  a deconfigure but two destroys instead (rchopra@redhat.com)
- undo raising exception if removing feature from requires_feature and it does
  not exist in requires_feature list (rchopra@redhat.com)
- fix for bug#807236 (rchopra@redhat.com)
- better messaging. bug# 807144 (rchopra@redhat.com)

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.7.4-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug 805997 and 806004 (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- bug fixes 807136, 807144. Also stop/start is not called on app create now.
  (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- New unit tests and fixes for mongo datastore (rpenta@redhat.com)
- removed GET link (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Fix for bugz 807171 - cannot remove jenkins-client from scaled app and
  cleanup errors, using incorrect variable names. (ramr@redhat.com)
- BugzID 806298 (kraman@gmail.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- require authentication before being able to access these controllers
  (lnader@redhat.com)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.3-1
- Updating gem versions (dmcphers@redhat.com)
- Fix for bugs# 807045, 807061 (rpenta@redhat.com)
- Fix destroy domain (rpenta@redhat.com)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- Updating gem versions (dmcphers@redhat.com)
- make code a little more readable (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- consumed_gears fix while domain create (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 806814 (rpenta@redhat.com)
- handle empty application case better (dmcphers@redhat.com)
- bugfix (kraman@gmail.com)
- fix for older rhc cli tools (lnader@redhat.com)
- Bug 804872 - [rest-api] node_profile needs to be supported so users can pick
  their gear size during app creation (lnader@redhat.com)
- Bug 804872 - [rest-api] node_profile needs to be supported so users can pick
  their gear size during app creation (lnader@redhat.com)
- Bug 804872 - [rest-api] node_profile needs to be supported so users can pick
  their gear size during app creation (lnader@redhat.com)
- Bug 805963 Bug 798933 (lnader@redhat.com)
- Bug 806045 - [REST API] Domain misses the rhc-domain property
  (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Hack to get jenkins client embed working  - not go to a new gear. Colocation
  doesn't do anything ... workaround it. (ramr@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Connection establishment needs to be done for both the web and proxy tiers.
  Fix connection issue where haproxy doesn't get connections to mysql.
  (ramr@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- add dependency to proxy component for scalable apps (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- removed user delete (lnader@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Set the haproxy's gear for a scalable app to be the uuid of the app. Makes
  stuff a lot more simpler and allows git clone to work for scalable apps.
  (ramr@redhat.com)
- Reverse the order for deconfigure so that the framework ain't called first
  and makes app destroy fail badly. (ramr@redhat.com)
- Merge branch 'compass', removed conflicting JS file (ccoleman@redhat.com)
- fixed bug in legacy broker (lnader@redhat.com)
- Use RakeBaseURI for stickshift broker - ensures that broker is running
  identically as production Remove app_scope from all configuration
  (ccoleman@redhat.com)
- fixed broken build (rchopra@redhat.com)
- merged conflicts with master (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- configure order fix. bar haproxy/jenkins/diy as scalable frameworks. bar all
  carts except mysql for embedding in scalable apps. (rchopra@redhat.com)
- group mcollective calls (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Fix test_user_ssh_keys (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- US1876 (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- fix configure order. code for scaleup/scaledown. (rchopra@redhat.com)
- US1876 (lnader@redhat.com)
- i before an e -- framework before the haproxy -- configure hook of the
  framework should run first. (ramr@redhat.com)
- Allow removal of last ssh key for the domain (rpenta@redhat.com)
- Allow adding same ssh keys with different key-names (rpenta@redhat.com)
- remove leading blank spaces in the key model (rpenta@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- fix connection issue for scalable apps - haproxy of proxy gear is now
  connected to framework of the web gear (rchopra@redhat.com)
- checkpoint : re-organize framework for scalable apps. can create scalable
  app, cannot start/stop/scaleup/scaledown it yet. (rchopra@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Remove haproxy from list of frameworks so that it can work as an embedded
  service. (ramr@redhat.com)
- code cleanup checkpoint 2 - fix gear dns entries being created for non-
  scalable apps (rchopra@redhat.com)
- code cleanup checkpoint for US2091. scalable apps may not work right now.
  (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- new file remote_job capturing parallel node call infra (rchopra@redhat.com)
- making haproxy work through broker (mmcgrath@redhat.com)
- re-organize parallel job exec code (rchopra@redhat.com)
- optimized mcollective calls for connectors is the default code path now
  (rchopra@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.7.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- cleanup error message (rmillner@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.6.10-1
- Updating gem versions (dmcphers@redhat.com)
- when creating cart make sure to pass the server results back to the UI
  (johnp@redhat.com)
- Fix applicaton group overrides (rpenta@redhat.com)
- Estimate application gear usage when scalable:true passed in the descriptor
  (rpenta@redhat.com)
- Fix for bug# 798884 (rpenta@redhat.com)
- fix for bug 803522 - better message on embed cartridge failure
  (rchopra@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.9-1
- Updating gem versions (dmcphers@redhat.com)
- jenkins does-not/need-not contain an expose-port, so dont raise a fatal
  exception if that fails on a scalable app (rchopra@redhat.com)
- bug fixes - 803085, 803190 (rchopra@redhat.com)
- stop order is reverse of start order (rchopra@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.8-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 800095 (rpenta@redhat.com)

* Tue Mar 13 2012 Dan McPherson <dmcphers@redhat.com> 0.6.7-1
- Updating gem versions (dmcphers@redhat.com)
- fix for bu 803085 (rchopra@redhat.com)
- fixing links in REST response for show/expose/conceal port calls
  (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li
  (abhgupta@redhat.com)
- adding links in REST response for add/remove alias (abhgupta@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.6.6-1
- Updating gem versions (dmcphers@redhat.com)
- fix for Bug 802221 (rchopra@redhat.com)
- fix for bug 798469 (rchopra@redhat.com)
- do not user username/password if iv/token method is used for authentication
  (rchopra@redhat.com)
- fixes to estimates controller (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix error codes for estimates controller (rpenta@redhat.com)
- fix for case when server_identity changes; switch to flip mcollective
  optimizations on/off (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- REST api changes to estimate gear usage given a descriptor
  (rpenta@redhat.com)
- Changes for US2033 - adding add/remove alias functionality to REST calls
  (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- add REST estimates model (rpenta@redhat.com)
- add estimates, application_estimate controller (rpenta@redhat.com)
- Add /estimates to base controller (rpenta@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.6.5-1
- Updating gem versions (dmcphers@redhat.com)
- rhc-admin-chk (rchopra@redhat.com)
- us2003 (bdecoste@gmail.com)
- cucumber test fix (rchopra@redhat.com)
- fixed cucumber test (rchopra@redhat.com)
- Fixing a couple of missed Cloud::Sdk references (kraman@gmail.com)
- fix dns issue on scaleup (rchopra@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)
- Build fixes (kraman@gmail.com)
- authenticate iv/key as separate parameters because of truncation issue in
  'username' method (rchopra@redhat.com)

* Fri Mar 09 2012 Krishna Raman <kraman@gmail.com> 0.6.1-1
- New package for StickShift (was Cloud-Sdk)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.6.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 799225 (rpenta@redhat.com)
- for deconfigure, fail if any of the deconfigures fail i.e. node not found or
  deconfigure failed (rchopra@redhat.com)
- [rest api] make sure we return data in the correct format (johnp@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.5.10-1
- Updating gem versions (dmcphers@redhat.com)
- Bugz 798148 (kraman@gmail.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- fix for bug 798643 (abhgupta@redhat.com)
- fix wrong cased OpenShift (dmcphers@redhat.com)
- merged changes (lnader@redhat.com)
- Bug 797136 - [Rest API] no Exit_code for error message for some rest api
  (lnader@redhat.com)
- Bug 797136 - [Rest API] no Exit_code for error message for some rest api
  (lnader@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.5.9-1
- Updating gem versions (dmcphers@redhat.com)
- Fix for Bugz 798256 Consolidating user lookup (kraman@gmail.com)
- Fix StickShift::ApplicationContainerProxy.blacklisted: avoid infinite
  recursion (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- fix for bug#796919 (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- added log message to keys_controller (lnader@redhat.com)
- Bug 797296 (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- merged changes (lnader@redhat.com)
- commented out the validation code (lnader@redhat.com)
- bug 797971 (lnader@redhat.com)
- adding application validator (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug 797296 (lnader@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.8-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- configuration changes to use bind dns service on stickshift FOSS
  (rpenta@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.7-1
- Updating gem versions (dmcphers@redhat.com)
- set errors correctly when updating domain (johnp@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- gear info REST api call fix (rpenta@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.6-1
- Updating gem versions (dmcphers@redhat.com)
- BugzID# 797098, 796088. Application validation (kraman@gmail.com)
- BugzID# 797782. Adding links for application templates (kraman@gmail.com)
- BugzID 797764. Skip deconfigure_dependencies if app descriptor elaboration
  failed. Return error message if invalid cartridge was specified in template
  and revert app creation (kraman@gmail.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.5.5-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix gear controller (rpenta@redhat.com)
- Added rest call to get gear info of all the applications (rpenta@redhat.com)
- add ssh keys to newly scaled up gear (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Bug 797270 - [REST API] Create of key not returning (lnader@redhat.com)
- gears get node profiles. service dependency is taken care of in exec order
  (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- bug fix for bind dns service (rpenta@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- restore ssh key mechanism, and execute connections outside of configure
  dependencies (rchopra@redhat.com)
- Bug 796363 (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- renaming jbossas7 (dmcphers@redhat.com)
- For scalable apps, app-uuid should be haproxy's gear-uuid
  (rchopra@redhat.com)
- node profile added for web cart gears (rchopra@redhat.com)
- fix scaledown (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- re-organize putting of ssh keys in gears (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- This block of code should only be called on a scalable app.
  (rmillner@redhat.com)
- reorder configure and expose port check (rchopra@redhat.com)
- fix php publish url to send exposed port (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- add ssh keys before connectors are called on create. expose port for
  web_carts. (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- StickShift app container proxy changes: Added new methods that matches the
  interface used by express proxy container (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug fix 796287 and US1895 (lnader@redhat.com)
- bug fix 796287 and US1895 (lnader@redhat.com)
- check group instance's reused_by to find if web_cart belongs there
  (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (abhgupta@redhat.com)
- fixing method signature - incorrect number of args (abhgupta@redhat.com)
- create dns entry before calling connectors (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- dns should be deconfigured before app is deleted (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- added exit_codes to messages generated by rest API in addition to ones passed
  from validators and models (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug fixes and update to cucumber tests (lnader@redhat.com)
- register dns name for scalable gears at creation time; rest api to scale
  (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (abhgupta@redhat.com)
- initial implementations for a bunch of methods in application container proxy
  for cloud sdk controller (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Bug 796363 (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- shellescape connector data exchange (rchopra@redhat.com)
- BugzID 795829 (kraman@gmail.com)
- BugzId# 795829: find_by_uuid no longer requires login name when looking up
  application (kraman@gmail.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)
- cloud sdk app destroy (bypass mcollective) (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- bind dns service bug fixes and cleanup (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug fixes (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- fix validate args for mcollective calls as we are sending json strings over
  now (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (abhgupta@redhat.com)
- more method implementations (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- jsonify connector output from multiple gears for consumption by subscriber
  connectors (rchopra@redhat.com)
- minor bug fix (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- minor changes to a few method signatures (abhgupta@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- REST call to create a scalable app; fix in ss-connector-execute; fix in
  app.scaleup function (rchopra@redhat.com)
- changes to enable app creation for opensource cloud sdk (abhgupta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- stickshift application container proxy changes (rpenta@redhat.com)
- User Story US1895: REST API error message updates (lnader@redhat.com)
- validator renamed (lnader@redhat.com)
- renamed namespace_validator to domain_validator (lnader@redhat.com)
- add validators and improvements to REST API validation errors
  (lnader@redhat.com)
- corrected typo :code versus :exit_code (lnader@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.5.4-1
- Updating gem versions (dmcphers@redhat.com)
- dont need targz of ddns test capsule (mlamouri@redhat.com)
- syntax bug fix (rchopra@redhat.com)
- checkpoint 4 - horizontal scaling bug fixes, multiple gears ok, scaling to be
  tested (rchopra@redhat.com)
- typo fix (rchopra@redhat.com)
- add bind_dns_service to stickshift-controller.rb (rpenta@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- checkpoint 3 - horizontal scaling, minor fixes, connector hook for haproxy
  not complete (rchopra@redhat.com)
- merging changes (abhgupta@redhat.com)
- Added application creation from template test case (kraman@gmail.com)
- initial checkin for US1900 (abhgupta@redhat.com)
- Merge remote-tracking branch 'origin/master' (mlamouri@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- typo fixes (rchopra@redhat.com)
- Add show-proxy call. (rmillner@redhat.com)
- added BindDnsService unit test and test service module (mlamouri@redhat.com)
- merged BindDnsService and packaging update (mlamouri@redhat.com)
- Adding admin scripts to manage templates Adding REST API for creatig
  applications given a template GUID (kraman@gmail.com)
- checkpoint 2 - option to create scalable type of app, scaleup/scaledown apis
  added, group minimum requirements get fulfilled (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- checkpoint 1 - horizontal scaling broker support (rchopra@redhat.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.5.3-1
- Updating gem versions (dmcphers@redhat.com)
- secure jenkins (dmcphers@redhat.com)
- Revert "Updating gem versions" (ramr@redhat.com)
- Sigh -- friday night build failures -- switching version by hand to 0.5.1 to
  get build running. Do need something strong now ... (ramr@redhat.com)

* Fri Feb 17 2012 Ram Ranganathan <ramr@redhat.com> 0.5.1-1
- Updating gem versions (ramr@redhat.com)
- bug fixes 789785 and 794917 (lnader@redhat.com)
- BugzID# 794664. Add alias not returns an error if using an alias that already
  used on a different app. (kraman@gmail.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- mongo save should not happen 5 times for an application create - fixed to 2
  times (rchopra@redhat.com)
- Fixing rails route to pick up base path from configuration instead of being
  hardcoded. (kraman@gmail.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.4.8-1
- Updating gem versions (dmcphers@redhat.com)
- BugzID# 790637. (kraman@gmail.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.4.7-1
- Updating gem versions (dmcphers@redhat.com)
- bug 790635 (wdecoste@localhost.localdomain)
- fix for bug#790672 (rchopra@redhat.com)
- BugzId #790637. Fixed broker code. Legacy rhc tools now ask user to add a new
  key. (kraman@gmail.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.4.6-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug 790370 (lnader@redhat.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.4.5-1
- Updating gem versions (dmcphers@redhat.com)
- add find_one capability (dmcphers@redhat.com)
- cleaning up version reqs (dmcphers@redhat.com)
- Bug fixes:   - Fix deconfigure order   - Fix type in exception handler of app
  configure (kraman@gmail.com)
- typo fix (rchopra@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.4-1
- Updating gem versions (dmcphers@redhat.com)
- Bugfix for bugz#789891. Fixed issue where cartridge was left as a dependency
  in the descriptor even if configure failed (kraman@gmail.com)
- Fix for bugz# 789814. Fixed 10gen-mms-agent and rockmongo descriptors. Fixed
  info sent back by legacy broker when cartridge doesnt not have info for
  embedded cart. (kraman@gmail.com)
- Fix for Bugz#790153. Legacy broker was throwing an error when user did not
  have ssh key (Domain created with new REST API without ssh key)
  (kraman@gmail.com)
- Adding REST link for descriptor (kraman@gmail.com)
- Bugfixes in postgres cartridge descriptor Bugfix in connection resolution
  inside profile Adding REST API to retrieve descriptor (kraman@gmail.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- Updating gem versions (dmcphers@redhat.com)
- cleaning up specs to force a build (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- merging kraman (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- Fixing some expose/conceal bits (mmcgrath@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- Updating gem versions (dmcphers@redhat.com)
- cleanup specs (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- fix for finding out whether a component is auto-generated or not
  (rchopra@redhat.com)
- Fixed typo (kraman@gmail.com)
- Provide a way for admin-move script to update embeddec cart information
  (kraman@gmail.com)
- Changing server_id to server_identity to be consistent with rest of code
  (kraman@gmail.com)
- change component/group paths in descriptor (rchopra@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix broker auth service, bug# 787297 (rpenta@redhat.com)
- bug fixes and refactoring (lnader@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- Minor fixes to export/conceal port functions (kraman@gmail.com)
- Bug 789179 (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- bug fixes and improvements in REST API (lnader@redhat.com)
- calling private functions without self qualifier (rchopra@redhat.com)
- fixing merge (mmcgrath@redhat.com)
- Fixes to throw exceptions on failures. Fixes to stop app if start fails and
  other recovery processes. (kraman@gmail.com)
- fixing alias add/remove (rchopra@redhat.com)
- Temporary commit to build (mmcgrath@redhat.com)
- merging (mmcgrath@redhat.com)
- Added expose and conceal port (mmcgrath@redhat.com)
- Fixed env var delete on node Added logic to save app after critical steps on
  node suring create/destroy/configure/deconfigure Handle failures on
  start/stop of application or cartridge (kraman@gmail.com)
- bug 722828 (bdecoste@gmail.com)
- bug 722828 (wdecoste@localhost.localdomain)
- bug 722828 (wdecoste@localhost.localdomain)
- What!!! List of cartridges is hardcoded in code ... try something like:   ls
  /usr/libexec/li/cartridges/ |  grep -Ev 'abstract|abstract-httpd|embedded'
  its a lil' better!! :^) (ramr@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (lnader@redhat.com)
- moved links from app to cartridge (lnader@redhat.com)
- correcting haproxy name (mmcgrath@redhat.com)
- Fix HAProxy descriptor Add HAProxy to standalone cart list on
  CartridgeCache(temp till descriptor changes are made on stickshift-node)
  (kraman@gmail.com)
- Fixing add/remove embedded cartridges Fixing domain info on legacy broker
  controller Fixing start/stop/etc app and cart. control calls for legacy
  broker (kraman@gmail.com)
- cleanup function to be called after elaboration (rchopra@redhat.com)
- get the deleted components out of re-elaboration (rchopra@redhat.com)
- re-elaborate descriptor after remove dependency (rchopra@redhat.com)
- remove self from dependency of component instance (rchopra@redhat.com)
- bug fix in re-entrancy code (rchopra@redhat.com)
- add application to configure/start order (rchopra@redhat.com)
- auto generate configure/start order (rchopra@redhat.com)
- auto-merge top groups; minor improvements to re-entrancy algorithm
  (rchopra@redhat.com)
- Bug fixes for saving connection list Abstracting difference between
  framework/embedded cart in application_container_proxy and application
  (kraman@gmail.com)
- Renamed ApplicationContainer to Gear to avoid confusion Fixed gear
  creation/configuration/deconfiguration for framework cartridge Fixed
  save/load of group insatnce map Removed hacks where app was assuming one gear
  only Started changes to enable rollback if operation fails (kraman@gmail.com)
- bug fixes for app dependency manipulation (rchopra@redhat.com)
- server_identity is container's uuid (rchopra@redhat.com)
- Added backward compat code to force first application containers uuid =
  application uuid (kraman@gmail.com)
- Fixes for re-enabling cli tools. git url is not yet working.
  (kraman@gmail.com)
- code for automerging top groups - not integrated yet, to be tested. also a
  minor bug fix (rchopra@unused-32-159.sjc.redhat.com)
- Updated code to make it re-enterant. Adding/removing dependencies does not
  change location of dependencies that did not change.
  (rchopra@unused-32-159.sjc.redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Added group overrides implementation Added colocation on connections
  implementation (rchopra@redhat.com)
- Use cart.requires_feature as dependencies in each component
  (rchopra@redhat.com)
- Changes to re-enable app to be saved/retrieved to/from mongo Various bug
  fixes (kraman@gmail.com)
- Added basic elaboration of components and connections (rchopra@redhat.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- bug fixes and enhancements in the rest API (lnader@redhat.com)
- simplify a lot of the internals test cases (make them faster)
  (dmcphers@redhat.com)
- Adding expose-port and conceal-port (mmcgrath@redhat.com)
- remove extra broker field (dmcphers@redhat.com)
- change state machine dep (dmcphers@redhat.com)
- move the rest of the controller tests into broker (dmcphers@redhat.com)
- stop using hard coded value (dmcphers@redhat.com)
- print correct image name in streamlined verify process (dmcphers@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.4.1-1
- Updating gem versions (dmcphers@redhat.com)
- add move by uuid (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- mongo wrapper: 'use <user-db>' instead of 'use admin' for authentication
  (rpenta@redhat.com)

