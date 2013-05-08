%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/haproxy-1.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/haproxy-1.4

Summary:       Provides embedded haproxy-1.4 support
Name:          openshift-origin-cartridge-haproxy-1.4
Version: 1.9.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      haproxy
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
BuildRequires: git
BuildArch:     noarch

%description
Provides haproxy balancer support to OpenShift


%prep
%setup -q


%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git init
git add -f .
git config user.email "builder@example.com"
git config user.name "Template builder"
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/../../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages


%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Add Cartridge-Vendor to manifest.yml in v1. (asari.ruby@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Bug 928675 (asari.ruby@gmail.com)
- fix haproxy cfg to handle empty response on health check (rchopra@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.6-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- <haproxy_ctld> Bug 920990 - fix p_usage showing usage message twice
  (jolamb@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- delete all calls to remove_ssh_key, and remove_domain_env_vars
  (rchopra@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Typo fixes (bleanhar@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Merge pull request #1793 from rmillner/BZ923611 (dmcphers@redhat.com)
- Bug 923611 - wsgiref based python servers react poorly to the session closing
  in the middle of sending headers. (rmillner@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Report if auto_scaling needs to be disabled. (rmillner@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Have haproxy_ctld wait for app_ctl to either kill it or reap the zombie.
  (rmillner@redhat.com)
- Moved the call of exec "app_ctl.sh reload" into a forked child process
  because the call to reload was killing haproxy_ctld and not able to restart
  it. (andy.goldstein@redhat.com)
- remove old obsoletes (tdawson@redhat.com)
- Merge pull request #1620 from bdecoste/master (dmcphers@redhat.com)
- Bug 920745 (bdecoste@gmail.com)
- Speed up haproxy interaction (dmcphers@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- The old maxconn settings were unreasonably high and caused haproxy to
  complain about not having enough file descriptors. (rmillner@redhat.com)

* Mon Mar 04 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Some ruby cleanup (dmcphers@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Bug 910929 - Use a lockfile on sections which may exec in parallel.
  (rmillner@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- The deploy-httpd-proxy hook was not setting up proper paths.
  (rmillner@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- remove extra php files from haproxy (dmcphers@redhat.com)
- fix for bz903963 - conditionally reload haproxy after update namespace
  (rchopra@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1212 from brenton/misc5
  (dmcphers+openshiftbot@redhat.com)
- Bug 903564: Fix inconsistent sed when updating haproxy cfg
  (ironcladlou@gmail.com)
- BZ892909 copying the file to just modify it inplace is a waste of ressource,
  and a security problem, since the file /tmp/haproxy.cfg.$$ has a predictible
  name and there is no check to see if it already exist or if it was changed
  between sed and cat ( or cat and cp ). A attacker with access to /tmp could
  just create directory with the same name to create a DOS and erase haproxy
  configuration. (misc@zarb.org)
- fix for bug 892076 (abhgupta@redhat.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Merge pull request #1183 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- fix typo (dmcphers@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Merge pull request #1169 from smarterclayton/use_nahi_httpclient_instead
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'master' of git://github.com/openshift/origin-server into
  use_nahi_httpclient_instead (ccoleman@redhat.com)
- Update the description and display name for haproxy-1.4 to reflect its true
  purpose (ccoleman@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Process help option. (rmillner@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1023 from ramr/dev/websockets (openshift+bot@redhat.com)
- Set connection limits (no limits) for haproxy/scaled apps. (ramr@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Make tidy hook accessible to gear users (ironcladlou@gmail.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Merge pull request #985 from ironcladlou/US2770 (openshift+bot@redhat.com)
- [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- Merge pull request #976 from jwhonce/dev/rm_post-remove
  (openshift+bot@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)
- Working around scl enable limitations with parameter passing
  (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Only use scl if it's available (ironcladlou@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Don't pass a shell script to Daemons (ironcladlou@gmail.com)
- Restore original PATH logic (ironcladlou@gmail.com)
- WIP fixes for haproxy Ruby 1.9 usage for scalable apps
  (ironcladlou@gmail.com)
- get the broker working again (dmcphers@redhat.com)
- WIP Ruby 1.9 runtime fixes (ironcladlou@gmail.com)
- Remove hard-coded ruby references (ironcladlou@gmail.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix for Bug 874445 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.16.9-1
- improve scaling experience - bug#869226 (rchopra@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.16.8-1
- Merge branch 'master' into dev/slagle-ssl-certificate (jslagle@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.16.7-1
- fix for bugs 868017, 867349 (rchopra@redhat.com)
- BZ 843286: Enable auth files via htaccess (rmillner@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.16.6-1
- Merge pull request #655 from mrunalp/bugs/864519 (openshift+bot@redhat.com)
- BZ 864519: Fix for git push failing for scalable apps w/ dbs.
  (mpatel@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.16.5-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.16.4-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.16.3-1
- Typeless gear changes (mpatel@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- Fix for bugz 851494 - Gears will be down if disable auto scaling and hot
  deploy are both triggered (ramr@redhat.com)
- Fix bug with count - with the local gear serving, we need to adjust the
  counts. (ramr@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.15.3-1
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- Fix a bug where first 3 parameters are not being ignored and set as env vars
  for mysql in a scaled app. (ramr@redhat.com)
- If the haproxy gear is added to the list of serving gears, this creates an
  infinite loop in sync_gears -- remove the haproxy gear from the list in the
  gear-registry.db (ramr@redhat.com)
- Fix for bugz 851315 - user's deploy hook is not called on local gear.
  (ramr@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.14.5-1
- Add check for cartridge type before federating the call. (ramr@redhat.com)
- Bug fix for apps with haproxy - we now need to federate to the app server
  control script as well. (ramr@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- Merge pull request #374 from rajatchopra/US2568 (openshift+bot@redhat.com)
- support for app-local ssh key distribution (rchopra@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Add support to make haproxy embeddable into existing applications, keep
  current app server running and route traffic to local gear and support for
  disabling autoscaling (via marker file). (ramr@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- Fix for bugz 845154 - use conditional reload for config changes.
  (ramr@redhat.com)
- Merge pull request #322 from ramr/master (rchopra@redhat.com)
- Fix for bugz 845164 - don't start haproxy if stopped and its a config change
  via execute connections. (ramr@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Wed Aug 01 2012 Adam Miller <admiller@redhat.com> 0.13.5-1
- Some frameworks (ex: mod_wsgi) need HTTPS set to notify the app that https
  was used. (rmillner@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Set up .ssh directory during gear move (ironcladlou@gmail.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Fix for bugz 839140 - The haproxy-1.4 cartridge's status is always "SUCESS".
  (ramr@redhat.com)
- Cleanup messages. (ramr@redhat.com)
- Log help at notice (not error) level. (ramr@redhat.com)
- Fix bugz 817704 - haproxy reseliency checks. (ramr@redhat.com)
- Fixes for bugz 840030 - Apache blocks access to /icons. Remove these as
  mod_autoindex has now been turned OFF (see bugz 785050 for more details).
  (ramr@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.12.9-1
- BZ 835529: The regexp was capturing gear names that contain the gear name
  being looked for (ex: gear name 012345-foobar also matches if checking for
  gear 012345-foo).  Add a space match at the end of the gear name to terminate
  it. (rmillner@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.12.8-1
- cleanup specs (dmcphers@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.12.7-1
- 

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.12.6-1
- Add visible error message if fail to scale up or down by request.
  (rmillner@redhat.com)
- bug 836973 - increased scaleup timeout (bdecoste@gmail.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- more cartridges have better metadata (rchopra@redhat.com)
- Merge pull request #161 from VojtechVitek/php.ini-max_file_uploads
  (mmcgrath+openshift@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)
- Add max_file_uploads INI setting to php.ini files (vvitek@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- BugFix: 834151 (rpenta@redhat.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- 

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- BZ 835205: Fail gracefully when the gear is in a half-built state instead of
  trying to do the wrong thing. (rmillner@redhat.com)
- BZ 835157: Add exception handling to add/remove-gear and print informative
  messages. (rmillner@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.11.7-1
- Fix for BZ 831097 (mpatel@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.11.6-1
- fix for bug#833039. Fix for scalable app's mysql move across districts.
  (rchopra@redhat.com)

* Fri Jun 15 2012 Adam Miller <admiller@redhat.com> 0.11.5-1
- Security - # BZ785050 Removed the mod_autoindex from the httpd.conf files
  (tkramer@redhat.com)

* Fri Jun 15 2012 Tim Kramer <tkramer@redhat.com>
- # BZ785050 Removed mod_autoindex from two httpd.conf files

* Wed Jun 13 2012 Adam Miller <admiller@redhat.com> 0.11.4-1
- support for group overrides so that we do not rely on filesystem co-location
  - fix for bug#824124 (rchopra@redhat.com)

* Mon Jun 11 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Moving stats socket file to run directory instead of tmp. On OpenShift
  Origin, multiple apps using haproxy caused errors because they compete over
  the /tmp/stats socket file. (kraman@gmail.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- fixing gearup bug (mmcgrath@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.10.8-1
- Bug 825354 (dmcphers@redhat.com)
- Fix for bz 816171 (mpatel@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.10.7-1
- Fix for bugz 824423 - fail to git push after haproxy gear move. Abstract
  expects cartridge_type as a result of typeless gears - set that.
  (ramr@redhat.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.10.6-1
- Merge pull request #60 from ramr/master (mmcgrath+openshift@redhat.com)
- Bug fix so that after a haproxy gear move the permissions are setup
  correctly. (ramr@redhat.com)
- Merge pull request #46 from rajatchopra/master (kraman@gmail.com)
- check for -1 on max value (rchopra@redhat.com)
- logic to check on scaling limits copied to haproxy_ctld (rchopra@redhat.com)
- change scaling policies in manifest.yml so that jboss really takes 2 as
  minimum (rchopra@redhat.com)
- code for min_gear setting (rchopra@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.10.4-1
- Fix for bugz 82087 -- app gear of a scalable app doesn't waken up from idled
  status. (ramr@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.10.3-1
- Automatic commit of package [openshift-origin-cartridge-haproxy-1.4] release [0.10.2-1].
  (admiller@redhat.com)
- Fix for bugz 822476. Make the isrunning check more resilient.
  (ramr@redhat.com)
- Add a haproxy log file, so that there's some additional info.
  (ramr@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Fix for bugz 820051 - Allow scalable gears to be moved. (ramr@redhat.com)
- Bug fix to get scalable apps working. (ramr@redhat.com)
- Revert to cartridge type -- no app types any more. (ramr@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Use a utility function to remove the cartridge instance dir.
  (ramr@redhat.com)
- Cleanup and restore custom env vars support and fixup permissions.
  (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Add and use cartridge instance specific functions. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- Fix for bugz 822476. Make the isrunning check more resilient.
  (ramr@redhat.com)
- Add a haproxy log file, so that there's some additional info.
  (ramr@redhat.com)
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- Merge pull request #36 from rmillner/master (kraman@gmail.com)
- Add sample user pre/post hooks. (rmillner@redhat.com)
- Fix for bugz 820051 - Allow scalable gears to be moved. (ramr@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.9.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)
- changed git config within spec files to operate on local repo instead of
  changing global values (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.9.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.8.6-1
- cleaning up spec files (dmcphers@redhat.com)

