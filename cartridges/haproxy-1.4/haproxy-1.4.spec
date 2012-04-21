%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/haproxy-1.4
%define frameworkdir %{_libexecdir}/stickshift/cartridges/haproxy-1.4

Summary:   Provides embedded haproxy-1.4 support
Name:      cartridge-haproxy-1.4
Version:   0.8.3
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-haproxy-1.4

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires:  haproxy
Requires:  rubygem-daemons
Requires:  rubygem-rest-client

BuildArch: noarch

%description
Provides haproxy balancer support to OpenShift

%prep
%setup -q

%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git config --global user.email "builder@example.com"
git config --global user.name "Template builder"
git init
git add -f .
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
ln -s %{cartridgedir}/../../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../../abstract-httpd/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.8.3-1
- 1) removing cucumber gem dependency from express broker. 2) moved ruby
  related cucumber tests back into express. 3) fixed issue with broker
  Gemfile.lock file where ruby-prof was not specified in the dependency
  section. 4) copying cucumber features into li-test/tests automatically within
  the devenv script. 5) fixing ctl status script that used ps to list running
  processes to specify the user. 6) fixed tidy.sh script to not display error
  on fedora stickshift. (abhgupta@redhat.com)
- bug 811509 (bdecoste@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.7.8-1
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Fix for bugz 809567 and also for 809554 - snapshot and restore for scalable
  apps. (ramr@redhat.com)
- enable auto scaling by default (mmcgrath@redhat.com)
- Remove link (no longer needed) as stickshift code has changed to use app name
  for the first gear in a scaled app. (ramr@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- re-ordered changelog chronologically (mlamouri@redhat.com)
- Cleanup old deprecated directory. (ramr@redhat.com)
- Merge remote-tracking branch 'origin/master' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-haproxy-1.4] release [0.7.7-1].
  (mmcgrath@redhat.com)
- test commit (mmcgrath@redhat.com)

* Tue Apr 03 2012 Mike McGrath <mmcgrath@redhat.com> 0.7.7-1
- test commit (mmcgrath@redhat.com)
- Update spec to require rest-client (jhonce@redhat.com)

* Tue Apr 03 2012 Mike McGrath <mmcgrath@redhat.com>
- Update spec to require rest-client (jhonce@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.7.7-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Update spec to require rest-client (jhonce@redhat.com)
- Automatic commit of package [rhc-cartridge-haproxy-1.4] release [0.8.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.7.6-1
- Renaming for open-source release

* Thu Mar 29 2012 Dan McPherson <dmcphers@redhat.com> 0.7.5-1
- Adding new 'node' tests (mmcgrath@redhat.com)
- Bug fix (use stats in lieu of express) + add some debug info.
  (ramr@redhat.com)

* Wed Mar 28 2012 Dan McPherson <dmcphers@redhat.com> 0.7.4-1
- Bug fixes to get reload done in the background and retry for 1 minute until
  the gear's DNS entry is available. (ramr@redhat.com)
- Fix restart to do a stop + start and wait on start for haproxy to become
  available. (ramr@redhat.com)
- further hardening of the scaling bits (mmcgrath@redhat.com)
- Merge branch 'master' into scale_testing (mmcgrath@redhat.com)
- fixing geardown event (mmcgrath@redhat.com)

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.7.3-1
- Make ssh less chatty (rmillner@redhat.com)
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- Fix bug -- exit not return. (ramr@redhat.com)
- corrected autoscale parameters (mmcgrath@redhat.com)
- Modified haproxy build.sh to call framework build.sh as well.
  (mpatel@redhat.com)
- Fix bugs to sync newly added gears and reload haproxy. (ramr@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- Adding haproxy check (mmcgrath@redhat.com)
- Adding sync gears to haproxy deploy. (mpatel@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- correcting some configure / deconfigure logic (mmcgrath@redhat.com)
- Fix missing quote. (ramr@redhat.com)
- Colocation hack for jenkins client -- need a better method to do this in the
  descriptor. (ramr@redhat.com)
- Fix bug w/ not removing app's vhost configs. (ramr@redhat.com)
- Cleanup old code for git mirroring. (ramr@redhat.com)
- Create a symlink for now if app named git directory doesn't exist so that git
  clone works. (ramr@redhat.com)
- Bug fix to update haproxy config in the right location. (ramr@redhat.com)
- Fix ssh issue from haproxy to app gears. (ramr@redhat.com)
- Bug fixes - pass parameters to basic book and setup correct perms.
  (ramr@redhat.com)
- Fix bug - exit 0 not return. (ramr@redhat.com)
- Manage vhost entry for scalable applications. (ramr@redhat.com)
- Bug fixes to get start app working + some cleanup in the ctl script.
  (ramr@redhat.com)
- Bug fixes for getting scalable apps running. (ramr@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- checkpoint : re-organize framework for scalable apps. can create scalable
  app, cannot start/stop/scaleup/scaledown it yet. (rchopra@redhat.com)
- Checkpoint work to allow haproxy to run standalone on a gear.
  (ramr@redhat.com)
- Checkpoint haproxy cartridge cleanup to just function as an embedded
  cartridge. (ramr@redhat.com)
- Move info to info.deprecated so as to clear the way for moving the
  info_embedded back in place. haproxy is now switching over to run just
  embedded (rather than as an application framework). (ramr@redhat.com)
- making haproxy work through broker (mmcgrath@redhat.com)
- Added haproxy embedded (mmcgrath@redhat.com)
- Temporary commit to build (mmcgrath@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.7.1-1
- bump spec numbers (dmcphers@redhat.com)
- fix README (dmcphers@redhat.com)
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)
- fix for bz 803677 (mmcgrath@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.7-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- adding http chk (mmcgrath@redhat.com)
- Refactor to use StickShift::Config (jhonce@redhat.com)
- fixing remove count threshold bug (mmcgrath@redhat.com)
- fixing some thrashing bugs and a misleading log line (mmcgrath@redhat.com)

* Tue Mar 13 2012 Dan McPherson <dmcphers@redhat.com> 0.6.6-1
- changing libra to stickshift in logger tag (abhgupta@redhat.com)
- Fix for bugz 802707 - reduce error messages doing git push to a scalable app
  - the "Could not create directory $HOME/.ssh" is unfortunately generated by
  ssh because of the perms -- that one will still exist. (ramr@redhat.com)
- Added timeout of 120secs to add/remove-gear broker call (jhonce@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.6.5-1
- remove login and password requirements (mmcgrath@redhat.com)
- SDK authenticate using token/iv in API (jhonce@redhat.com)
- Fix for bugz 802230 - secure git correctly so user can do pushes. Fallout of
  connection hooks run as root. (ramr@redhat.com)
- Add remote db control script + bug fixes w/ variable name changes.
  (ramr@redhat.com)
- Checkpoint work to call mysql on gear from haproxy + setup haproxy control
  scripts. (ramr@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- Cleanup stickshift merge issues -- fix set-git-url hook failed to set the git
  repo as ssh was not found. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.3-1
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add connector for setting db connection info. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.2-1
- Batch variable name chage (rmillner@redhat.com)
- Fix merge issues (kraman@gmail.com)
- Adding export control files (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- libra to stickshift changes for haproxy - untested (abhgupta@redhat.com)
- partial set of libra-to-stickshift changes for haproxy (abhgupta@redhat.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- added README (mmcgrath@redhat.com)
- removed comments (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- disabling ctld for now (mmcgrath@redhat.com)
- finalizing some haproxy ctld bits (mmcgrath@redhat.com)
- Modify haproxy connection hooks to source env variables correctly.
  (ramr@redhat.com)
- Bug fix - redirect streams only after the fd is opened. (ramr@redhat.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Temporary commit to build (mmcgrath@redhat.com)
- Temporary commit to build (mmcgrath@redhat.com)
- accept any 200 response code (jhonce@redhat.com)
- disabling haproxy_ctld_daemon (mmcgrath@redhat.com)
- Adding cookie management to haproxy and general cleanup (mmcgrath@redhat.com)
- removed a bunch of add/remove gear cruft (mmcgrath@redhat.com)
- renaming haproxy watcher daemons (mmcgrath@redhat.com)
- added a watcher script, fixed up tracker logic (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- WIP removed extraneous debugging code (jhonce@redhat.com)
- renamed haproxy_status (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- adding more gearup/geardown logic (mmcgrath@redhat.com)
- WIP add/remove/create gear (jhonce@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.6.1-1
- bump spec numbers (dmcphers@redhat.com)
- add/remove gear via SDK (jhonce@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.5.7-1
- Cleanup to put the ss-connector-execute workaround in the utility extensions
  for express. (ramr@redhat.com)
- Handle git push errors - better check for gear is up and running.
  (ramr@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.5.6-1
- Need to wait for dns entries to become available -- we do need some other
  mechanism to ensure connection-hooks are invoked after everything works in
  dns. For now fix the bug by waiting in here for the dns entry to become
  available. (ramr@redhat.com)
- Bug fix to get haproxy reload working. (ramr@redhat.com)
- Fixup reload haproxy - temporary bandaid until ss-connector execute is
  fixed. (ramr@redhat.com)
- Manage gear reg/unreg from haproxy on scale up/down + reload haproxy
  gracefully. (ramr@redhat.com)
- ~/.state tracking feature (jhonce@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.5-1
- Fix inter-device move failure to cat + rm. (ramr@redhat.com)
- Remove git entries on gear removal (scale down). (ramr@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.5.4-1
- Fix bugs to get gear sync + registration + scale up working.
  (ramr@redhat.com)
- Update handling k=v pairs the broker sends. Also check dns availability of
  the gear before attempting to use it. (ramr@redhat.com)
- Add a git remote for all-gears (allows: git push all-gears --mirror).
  (ramr@redhat.com)
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- Fix bugs + cleanup for broker integration. (ramr@redhat.com)
- Use connectors to sync gears and add routes. (ramr@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.5.3-1
- spec fix to include connection-hooks (rchopra@redhat.com)
- checkpoint 3 - horizontal scaling, minor fixes, connector hook for haproxy
  not complete (rchopra@redhat.com)
- checkpoint 2 - option to create scalable type of app, scaleup/scaledown apis
  added, group minimum requirements get fulfilled (rchopra@redhat.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.5.2-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- Made scripts more generic, still only works with php (mmcgrath@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- bump spec numbers (dmcphers@redhat.com)
- fixing ssh permissions (mmcgrath@redhat.com)
- Adding git-repo setups (mmcgrath@redhat.com)
- Adding more ssh pre-configuring (mmcgrath@redhat.com)
- removed preconfigure from specfile, it's now provided (mmcgrath@redhat.com)
- Added ssh key and broker key (mmcgrath@redhat.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- removing debug (mmcgrath@redhat.com)
- Adding sourcing for ctl_all to work (mmcgrath@redhat.com)
- Added add/remove gear (mmcgrath@redhat.com)
- added add/remove logic (mmcgrath@redhat.com)
- Adding basic gear_ctl script (mmcgrath@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.1-1
- add a digit to haproxy version (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4-1
- fixing filler 1 (mmcgrath@redhat.com)
- added whitespace for test chante (mmcgrath@redhat.com)
- bug 722828 (bdecoste@gmail.com)
- more abstracting out selinux (dmcphers@redhat.com)
- better name consistency (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- merging (mmcgrath@redhat.com)
- Fix wrong link to remove-httpd-proxy (hypens not underscores) and fix
  manifests for Node and Python to allow for nodejs/python app creation.
  (ramr@redhat.com)
- correcting haproxy name (mmcgrath@redhat.com)
- Fix HAProxy descriptor Add HAProxy to standalone cart list on
  CartridgeCache(temp till descriptor changes are made on stickshift-node)
  (kraman@gmail.com)
- Altered haproxy (mmcgrath@redhat.com)
- removed dependency on www-dynamic (rchopra@redhat.com)

* Mon Feb 06 2012 Mike McGrath <mmcgrath@redhat.com> 0.3-1
- Adding legal bits (mmcgrath@redhat.com)

* Mon Feb 06 2012 Mike McGrath <mmcgrath@redhat.com> 0.2-1
- new package built with tito

* Mon Feb 06 2012 Dan McPherson <mmcgrath@redhat.com> 0.1-1
- Initial packaging
