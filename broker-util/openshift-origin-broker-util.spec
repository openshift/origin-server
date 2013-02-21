%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global rubyabi 1.9.1

Summary:       Utility scripts for the OpenShift Origin broker
Name:          openshift-origin-broker-util
Version:       1.5.3
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
Requires:      openshift-origin-broker
# For oo-register-dns
Requires:      bind-utils
# For oo-setup-bind
Requires:      rng-tools
# For oo-setup-broker
Requires:      openssl
%if 0%{?fedora} >= 17
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
%else
BuildRequires: %{?scl:%scl_prefix}rubygems
%endif
BuildArch:     noarch

%description
This package contains a set of utility scripts for the openshift broker.  
They must be run on a openshift broker instance.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_sbindir}
cp oo-* %{buildroot}%{_sbindir}/

mkdir -p %{buildroot}%{_mandir}/man8/
cp man/*.8 %{buildroot}%{_mandir}/man8/
mkdir -p %{buildroot}/usr/share/openshift/kickstarts
cp kickstart/openshift-origin-remix.ks %{buildroot}/usr/share/openshift/kickstarts

%files
%attr(0750,-,-) %{_sbindir}/oo-admin-chk
%attr(0750,-,-) %{_sbindir}/oo-admin-clear-pending-ops
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-app
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-district
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-domain
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-user
%attr(0750,-,-) %{_sbindir}/oo-admin-move
%attr(0750,-,-) %{_sbindir}/oo-admin-usage
%attr(0750,-,-) %{_sbindir}/oo-register-dns
%attr(0750,-,-) %{_sbindir}/oo-setup-bind
%attr(0750,-,-) %{_sbindir}/oo-setup-broker
%attr(0750,-,-) %{_sbindir}/oo-accept-broker
%attr(0750,-,-) %{_sbindir}/oo-accept-systems
%attr(0750,-,-) %{_sbindir}/oo-stats
/usr/share/openshift/kickstarts/openshift-origin-remix.ks

%doc LICENSE
%{_mandir}/man8/oo-admin-chk.8.gz
%{_mandir}/man8/oo-admin-ctl-app.8.gz
%{_mandir}/man8/oo-admin-ctl-district.8.gz
%{_mandir}/man8/oo-admin-ctl-domain.8.gz
%{_mandir}/man8/oo-admin-ctl-user.8.gz
%{_mandir}/man8/oo-admin-move.8.gz
%{_mandir}/man8/oo-admin-usage.8.gz
%{_mandir}/man8/oo-register-dns.8.gz
%{_mandir}/man8/oo-setup-bind.8.gz
%{_mandir}/man8/oo-setup-broker.8.gz
%{_mandir}/man8/oo-accept-broker.8.gz
%{_mandir}/man8/oo-accept-systems.8.gz
%{_mandir}/man8/oo-stats.8.gz

%changelog
* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- showiing usage duration and cost based on timeframe specified
  (abhgupta@redhat.com)
- stop passing extra app object (dmcphers@redhat.com)
- Apply changes from comments. Fix diffs from brenton/origin-server.
  (john@ibiblio.org)
- Broker and broker-util spec files (john@ibiblio.org)
- bz910577 - recheck on race condition, consumed_gear is check is optional
  (rchopra@redhat.com)
- Adding man page for oo-admin-usage (abhgupta@redhat.com)
- read from primary - bz910610 (rchopra@redhat.com)
- making usage filter a generic hash (abhgupta@redhat.com)
- added new admin script to list usage for a user (abhgupta@redhat.com)
- force destroy means use force (rchopra@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Fixing domain update in oo-admin-ctl-domain script (abhgupta@redhat.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.8-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.7-1
- <oo-stats, oo-diagnostics> allow -w .5, improve options errmsg
  (lmeyer@redhat.com)
- <oo-accept-systems> fix bug 893896 - allow -w .5 and improve parameter error
  report (lmeyer@redhat.com)
- <oo-accept-broker> fix bug 905656 - exit message and status
  (lmeyer@redhat.com)
- <oo-stats> add man page; fix profile summation bug 907286.
  (lmeyer@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- Merge pull request #1265 from fotioslindiakos/storage
  (dmcphers+openshiftbot@redhat.com)
- Fix setting max_storage for oo-admin-ctl-user (fotios@redhat.com)
- Added ability to set max storage to oo-admin-ctl-user (fotios@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Bug 901444 Fixing bad merge (dmcphers@redhat.com)
- Better naming (dmcphers@redhat.com)
- share db connection logic (dmcphers@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Merge pull request #1252 from
  smarterclayton/us3350_establish_plan_upgrade_capability
  (dmcphers+openshiftbot@redhat.com)
- US3350 - Expose a plan_upgrade_enabled capability that indicates whether
  users can select a plan (ccoleman@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1258 from sosiouxme/metrics
  (dmcphers+openshiftbot@redhat.com)
- <oo-stats> update for model refactor and add to specfile (lmeyer@redhat.com)
- fix for bz903963 - conditionally reload haproxy after update namespace
  (rchopra@redhat.com)
- oo-stats updated to use new facts available (lmeyer@redhat.com)
- <new> oo-stats gathers systems stats and displays them (lmeyer@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1234 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- refix oo-admin-chk - remove pagination; minor fix with group override
  matching (rchopra@redhat.com)
- rebase on latest version (tdawson@redhat.com)
- Bug 874932 (dmcphers@redhat.com)
- Bug 884456 (dmcphers@redhat.com)
- Bug 873181 (dmcphers@redhat.com)
- Bug 873180 (dmcphers@redhat.com)
- Added CloudUser.force_delete option and fix oo-admin-ctl-user script
  (rpenta@redhat.com)
- Bug 895001 (rchopra@redhat.com)
- missing validations (dmcphers@redhat.com)
- Bug 892100 (dmcphers@redhat.com)
- Bug 892132 (dmcphers@redhat.com)
- Fix for bug 889978 (abhgupta@redhat.com)
- Bug 890010 (lnader@redhat.com)
- adding locks for subaccounts etc. (rchopra@redhat.com)
- fix for bug (abhgupta@redhat.com)
- fixing oo-admin-ctl-user script (abhgupta@redhat.com)
- fix oo-admin-ctl-domain (rchopra@redhat.com)
- secure move (rchopra@redhat.com)
- admin script fixes (rchopra@redhat.com)
- admin-ctl-app remove particular gear (rchopra@redhat.com)
- more admin script fixes (rchopra@redhat.com)
- oo-admin-chk refactored (rchopra@redhat.com)
- refactoring to use getter/setter for user capabilities (abhgupta@redhat.com)
- removing app templates and other changes (dmcphers@redhat.com)
- fix all the cloud_user.find passing login calls (dmcphers@redhat.com)
- district fixes (rchopra@redhat.com)
- fixup cloud user usages (dmcphers@redhat.com)
- Bug 903139 (dmcphers@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Fixing incorrect if check on APP_VALUES[DS_SSL] (calfonso@redhat.com)
- Merge pull request #842 from Miciah/oo-accept-broker-drop-sysctl-check
  (dmcphers+openshiftbot@redhat.com)
- oo-accept-broker: drop sysctl checks (miciah.masters@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.4-1
- Merge pull request #1154 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Adding support for broker to mongodb connections over SSL
  (calfonso@redhat.com)
- Bug 901444 (dmcphers@redhat.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- fedora mock build fix (tdawson@redhat.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1080 from sosiouxme/accept-scripts
  (openshift+bot@redhat.com)
- work around mongo replica sets; changes to man page (lmeyer@redhat.com)
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)
- fix man page titles (lmeyer@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)
- Merge pull request #1066 from sosiouxme/accept-scripts
  (openshift+bot@redhat.com)
- oo-admin-chk and man page tweaks while looking at BZ874799 and BZ875657
  (lmeyer@redhat.com)
- BZ874750 & BZ874751 fix oo-accept-broker man page; remove useless code and
  options also give friendly advice during FAILs - why not? BZ874757 make man
  page and options match (lmeyer@redhat.com)
- save on the number of rails console calls being made (lmeyer@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1057 from brenton/BZ876644-origin (dmcphers@redhat.com)
- BZ876644 - oo-register-dns is hardcoded to add entries to a BIND server at
  127.0.0.1 (bleanhar@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1045 from kraman/f17_fixes (openshift+bot@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Merge pull request #1007 from sosiouxme/US3036-origin
  (openshift+bot@redhat.com)
- Adding oo-accept-systems script for verifying all node hosts from the broker.
  - also verifies cartridge consistency and checks for stale cartridge cache.
  oo-accept-node sanity checks public_ip and public_hostname. Minor edits to
  make node.conf easier to understand. (lmeyer@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Removing references to complete-origin-setup from the man pages
  (bleanhar@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Merge pull request #507 from mscherer/remove_hardcoded_tmp
  (openshift+bot@redhat.com)
- rewording (dmcphers@redhat.com)
- give a different error if a node isn't returned by mcollective
  (dmcphers@redhat.com)
- Bug 880285 (dmcphers@redhat.com)
- fix desc (dmcphers@redhat.com)
- adding remove cartridge and various cleanup (dmcphers@redhat.com)
- removegear -> remove-gear for consistency (dmcphers@redhat.com)
- avoid timeout on long running query in a safe way (dmcphers@redhat.com)
- use a more reasonable large disctimeout (dmcphers@redhat.com)
- exit code and usage cleanup (dmcphers@redhat.com)
- cleanup (dmcphers@redhat.com)
- Working around scl enable limitations with parameter passing
  (dmcphers@redhat.com)
- increase disc timeout on admin chk (dmcphers@redhat.com)
- Merge pull request #962 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #905 from kraman/ruby19 (openshift+bot@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- reform the get_all_gears call and add capability to reserve a specific uid
  from a district (rchopra@redhat.com)
- fix for bug#877886 (rchopra@redhat.com)
- F18 compatibility fixes   - apache 2.4   - mongo journaling   - JDK 7   -
  parseconfig gem update Bugfix for Bind DNS plugin (kraman@gmail.com)
- remove various hardcoded usage of file in /tmp (mscherer@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.8-1
- Bug 877347 (dmcphers@redhat.com)
- fix for bug#876330 (rchopra@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- fix ref to wrong var (dmcphers@redhat.com)
- fix ref to wrong var (dmcphers@redhat.com)
- handle errors better on invalid data for oo-admin-chk (dmcphers@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- add unresilient option to oo-admin-chk (dmcphers@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Avoid false positives with oo-admin-chk (dmcphers@redhat.com)
- Fix for bug# 874931 (rpenta@redhat.com)
- Bug 873349 (dmcphers@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Bug 876099 (dmcphers@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #809 from Miciah/add-auth-remote-user-to-oo-accept-broker
  (openshift+bot@redhat.com)
- oo-accept-broker: add support for remote-user auth (miciah.masters@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- oo-accept-broker: fix check_datastore_mongo (miciah.masters@gmail.com)
- Fix for Bug 873765 (jhonce@redhat.com)
- oo-accept-broker: RHEL6 compatibility (miciah.masters@gmail.com)
- Merge pull request #698 from mscherer/fix_doc_node_bin
  (openshift+bot@redhat.com)
- do not use old name in the script help message (mscherer@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fixes for LiveCD build (kraman@gmail.com)
- move broker/node utils to /usr/sbin/ everywhere (admiller@redhat.com)
- Bug 871436 - moving the default path for AUTH_PRIVKEYFILE and AUTH_PUBKEYFILE
  under /etc (bleanhar@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- Added man pages for broker-util/node-util, port complete-origin-setup to bash
  (admiller@redhat.com)
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
- fix broker-util version number (admiller@redhat.com)
- Updating broker setup script (kraman@gmail.com)
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)
- sudo is not allowed within a command that is being executed using su
  (abhgupta@redhat.com)
- Merge pull request #741 from pravisankar/dev/ravi/bug/853082
  (openshift+bot@redhat.com)
- Fix for bug# 853082 (rpenta@redhat.com)
- Updating setup-broker, moving broken gem setup to after bind plugn setup is
  completed. Fixing cucumber test helper to use correct selinux policies
  (kraman@gmail.com)
- Merge pull request #737 from sosiouxme/master (dmcphers@redhat.com)
- have openshift-broker report bundler problems rather than silently fail. also
  fix typo in oo-admin-chk usage (lmeyer@redhat.com)
- Bug 868858 (dmcphers@redhat.com)
- Fixing Origin build scripts (kraman@gmail.com)
- removing remaining cases of SS and config.ss (dmcphers@redhat.com)
- Fix for Bugs# 853082, 847572 (rpenta@redhat.com)
- Set a password on the mongo admin db so that application and ssh'd users
  cannot access the DB. Misc other fixes (kraman@gmail.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Merge pull request #681 from pravisankar/dev/ravi/bug/821107
  (openshift+bot@redhat.com)
- Merge pull request #678 from jwhonce/dev/scripts (dmcphers@redhat.com)
- Support more ssh key types (rpenta@redhat.com)
- Automatic commit of package [openshift-origin-broker-util] release
  [0.0.6.2-1]. (admiller@redhat.com)
- Port oo-init-quota command (jhonce@redhat.com)
- Port admin scripts for on-premise (jhonce@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.0.6.2-1
- Port admin scripts for on-premise (jhonce@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Tue Oct 09 2012 Krishna Raman <kraman@gmail.com> 0.0.6.1-1
- Removing old build scripts Moving broker/node setup utilities into util
  packages (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- Bug 864005 (dmcphers@redhat.com)
- Bug: 861346 - fixing ss-admin-ctl-domain script (abhgupta@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.0.5-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Disable analytics for admin scripts (dmcphers@redhat.com)
- Commiting Rajat's fix for bug#827635 (bleanhar@redhat.com)
- Subaccount user deletion changes (rpenta@redhat.com)
- fixing build requires (abhgupta@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Removing the node profile enforcement from the oo-admin-ctl scripts
  (bleanhar@redhat.com)
- Adding LICENSE file to new packages and other misc cleanup
  (bleanhar@redhat.com)

* Thu Sep 20 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.2-1
- new package built with tito

