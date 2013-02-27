Summary:       Utility scripts for the OpenShift Origin broker
Name:          openshift-origin-node-util
Version:       1.5.3
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      oddjob
Requires:      rng-tools
Requires:      rubygem-openshift-origin-node
Requires:      httpd
Requires:      php >= 5.3.2
BuildArch:     noarch

%description
This package contains a set of utility scripts for a node.  They must be
run on a node instance.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_sbindir}

cp bin/oo-* %{buildroot}%{_sbindir}/
cp bin/rhc-* %{buildroot}%{_sbindir}/

%if 0%{?fedora} >= 18
  mv %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.4 %{buildroot}%{_sbindir}/oo-httpd-singular
  rm %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.3
%else
  mv %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.3 %{buildroot}%{_sbindir}/oo-httpd-singular
  rm %{buildroot}%{_sbindir}/oo-httpd-singular.apache-2.4
%endif

mkdir -p %{buildroot}/%{_sysconfdir}/httpd/conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
mkdir -p %{buildroot}%{_sysconfdir}/dbus-1/system.d/
mkdir -p %{buildroot}/%{_localstatedir}/www/html/
mkdir -p %{buildroot}%{_mandir}/man8/

cp conf/oddjob/openshift-restorer.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp conf/oddjob/oddjobd-restorer.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp www/html/restorer.php %{buildroot}/%{_localstatedir}/www/html/

cp man8/*.8 %{buildroot}%{_mandir}/man8/


%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}%{_initddir}
cp init.d/openshift-gears %{buildroot}%{_initddir}/
%else
mkdir -p %{buildroot}/etc/systemd/system
mv services/openshift-gears.service %{buildroot}/etc/systemd/system/openshift-gears.service
%endif

%files
%attr(0750,-,-) %{_sbindir}/oo-accept-node
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-gears
%attr(0750,-,-) %{_sbindir}/oo-app-idle
%attr(0750,-,-) %{_sbindir}/oo-autoidler
%attr(0750,-,-) %{_sbindir}/oo-idler
%attr(0750,-,-) %{_sbindir}/oo-idler-stats
%attr(0750,-,-) %{_sbindir}/oo-init-quota
%attr(0750,-,-) %{_sbindir}/oo-last-access
%attr(0750,-,-) %{_sbindir}/oo-list-stale
%attr(0750,-,-) %{_sbindir}/oo-list-access
%attr(0750,-,-) %{_sbindir}/oo-restorer
%attr(0750,-,apache) %{_sbindir}/oo-restorer-wrapper.sh
%attr(0750,-,-) %{_sbindir}/oo-setup-node
%attr(0755,-,-) %{_sbindir}/rhc-list-ports
%attr(0755,-,-) %{_sbindir}/oo-httpd-singular
%attr(0750,-,-) %{_sbindir}/oo-su
%attr(0750,-,-) %{_sbindir}/oo-cartridge

%doc LICENSE
%doc README-Idler.md
%{_mandir}/man8/oo-accept-node.8.gz
%{_mandir}/man8/oo-admin-ctl-gears.8.gz
%{_mandir}/man8/oo-app-idle.8.gz
%{_mandir}/man8/oo-autoidler.8.gz
%{_mandir}/man8/oo-idler.8.gz
%{_mandir}/man8/oo-idler-stats.8.gz
%{_mandir}/man8/oo-init-quota.8.gz
%{_mandir}/man8/oo-last-access.8.gz
%{_mandir}/man8/oo-list-stale.8.gz
%{_mandir}/man8/oo-list-access.8.gz
%{_mandir}/man8/oo-restorer.8.gz
%{_mandir}/man8/oo-restorer-wrapper.sh.8.gz
%{_mandir}/man8/oo-setup-node.8.gz
%{_mandir}/man8/rhc-list-ports.8.gz
%{_mandir}/man8/oo-httpd-singular.8.gz

%attr(0640,-,-) %config(noreplace) %{_sysconfdir}/oddjobd.conf.d/oddjobd-restorer.conf
%attr(0644,-,-) %config(noreplace) %{_sysconfdir}/dbus-1/system.d/openshift-restorer.conf

%{_localstatedir}/www/html/restorer.php

%if 0%{?fedora}%{?rhel} <= 6
%attr(0750,-,-) %{_initddir}/openshift-gears
%else
%attr(0750,-,-) /etc/systemd/system/openshift-gears.service
%endif

%post
/sbin/restorecon /usr/sbin/oo-restorer* || :

%changelog
* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- remove use of filesystem cgroup countrol (mlamouri@redhat.com)
- Bug 908968 - Use cat to cross security domains. (rmillner@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- remove BuildRoot: (tdawson@redhat.com)
- Merge pull request #1318 from tdawson/tdawson/openshift-common-sources
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1296 from jwhonce/dev/bz895878
  (dmcphers+openshiftbot@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)
- Bug 876247 - Write DB forwarding to stderr (jhonce@redhat.com)
- Bug 895878 - Added support for broker's new 24 character uuid
  (jhonce@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Bug 876247 - Report attached databases in a scaled application via rhc-list-
  ports (jhonce@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- setup the namespace configuration oo-setup-node (misc@zarb.org)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Bug 906034 - chmod on openshift-restorer.conf (jhonce@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #966 from mscherer/fix/node-util/fix_duplicate_functions
  (dmcphers+openshiftbot@redhat.com)
- Bug 890005 (dmcphers@redhat.com)
- fix oo-accept-node (dmcphers@redhat.com)
- remove duplicate definition of function ( since there is the exact same code
  before in the file, with added debug statement ) (misc@zarb.org)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.7-1
- Merge pull request #967 from mscherer/enhancement/node-
  util/cleaner_shell_code (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1178 from ramr/master (dmcphers+openshiftbot@redhat.com)
- Fix bugz 894170 - Server timeout with add/remove of Metrics cartridge.
  (ramr@redhat.com)
- Merge pull request #1171 from jwhonce/dev/bz880699
  (dmcphers+openshiftbot@redhat.com)
- Fix for Bug 880699 (jhonce@redhat.com)
- use awk instead of awk, cat and grep. Just for having more compact code
  (misc@zarb.org)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.6-1
- Merge pull request #1164 from jwhonce/dev/bz895878
  (dmcphers+openshiftbot@redhat.com)
- Partial fix for Bug 895878 (jhonce@redhat.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Merge pull request #1157 from jwhonce/dev/bz895878
  (dmcphers+openshiftbot@redhat.com)
- Fix for Bug 895878 (jhonce@redhat.com)

* Wed Jan 16 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Fix BZ875910: make oo-accept-node extensible (pmorie@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Fix for Bug 893207 (jhonce@redhat.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- BZ 886379: Print out a warning message if no args. (rmillner@redhat.com)
- - oo-setup-broker fixes:   - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:   -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.7-1
- Merge pull request #1045 from kraman/f17_fixes (openshift+bot@redhat.com)
- Merge pull request #1044 from ramr/master (openshift+bot@redhat.com)
- Fix bugz - log to access.log + websockets.log + log file rollover. And update
  idler's last access script to use the new node-web-proxy access.log file.
  (ramr@redhat.com)
- Close the connection on a 302/temporary redirect - bugz where the clients
  loop. (ramr@redhat.com)
- Switched console port from 3128 to 8118 due to selinux changes in F17-18
  Fixed openshift-node-web-proxy systemd script Updates to oo-setup-broker
  script:   - Fixes hardcoded example.com   - Added basic auth based console
  setup   - added openshift-node-web-proxy setup Updated console build and spec
  to work on F17 (kraman@gmail.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Adding oo-accept-systems script for verifying all node hosts from the broker.
  - also verifies cartridge consistency and checks for stale cartridge cache.
  oo-accept-node sanity checks public_ip and public_hostname. Minor edits to
  make node.conf easier to understand. (lmeyer@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Calculate date duration in a 1.9 compatible way (ironcladlou@gmail.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Fix for Bug 880699 (jhonce@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Move add/remove alias to the node API. (rmillner@redhat.com)
- Fix for Bug 881920 (jhonce@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Remove unused phpmoadmin cartridge (jhonce@redhat.com)
- use /bin/env for cron (dmcphers@redhat.com)
- exit code and usage cleanup (dmcphers@redhat.com)
- Merge pull request #962 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #905 from kraman/ruby19 (openshift+bot@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- F18 compatibility fixes   - apache 2.4   - mongo journaling   - JDK 7   -
  parseconfig gem update Bugfix for Bind DNS plugin (kraman@gmail.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Fix for Bug 876874 (jhonce@redhat.com)
- Merge pull request #925 from ironcladlou/scl-refactor (dmcphers@redhat.com)
- Only use scl if it's available (ironcladlou@gmail.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Fix for Bug 876874 (jhonce@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- update verb in JSON payload (jhonce@redhat.com)
- US2603 man page and packaging (jhonce@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Fix for Bug 874445 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Fix for BZ872313 (jhonce@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.0.3-1
- Fix for bug# 869748 (rpenta@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fixes for LiveCD build (kraman@gmail.com)
- move broker/node utils to /usr/sbin/ everywhere (admiller@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- fix man page path names for node-util spec (admiller@redhat.com)
- Added man pages for broker-util/node-util, port complete-origin-setup to bash
  (admiller@redhat.com)
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.0.8-1
- Merge pull request #775 from brenton/rhc-list-ports1
  (openshift+bot@redhat.com)
- Fixing rhc-list-ports permissions issue (bleanhar@redhat.com)
- Updating broker setup script (kraman@gmail.com)
- Merge pull request #777 from rmillner/master (openshift+bot@redhat.com)
- BZ 867242: Add a specific error on bad UUID. (rmillner@redhat.com)
- BZ 869874: Do not attempt status report for non-existant cartridges.
  (rmillner@redhat.com)
- node-util needs apache group created before it is installed
  (jhonce@redhat.com)
- Fix for Bug 867198 (jhonce@redhat.com)
- Bug 835501 - 'rhc-port-foward' returns 'No available ports to forward '
  (bleanhar@redhat.com)

* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Fix lock file (jhonce@redhat.com)
- Refactor oo-admin-ctl-gears to use lib/util functions (jhonce@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.0.6-1
- Update documentation with expected httpd access log format
  (jhonce@redhat.com)
- Idler requires PHP to restore gear (jhonce@redhat.com)
- fixed single quotes to doubble in oo-admin-ctl-gears GEAR_GECOS subst
  (mlamouri@redhat.com)

* Mon Oct 22 2012 Adam Miller <admiller@redhat.com> 0.0.5-1
- Fixing Origin build scripts (kraman@gmail.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Change libra guest to OpenShift guest (dmcphers@redhat.com)
- Update Idler documentation (jhonce@redhat.com)
- Wrong name transition in pam.d/sshd. (rmillner@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Port auto-Idler to origin-server (jhonce@redhat.com)
- Fixing outstanding cgroups issues Removing hardcoded references to "OpenShift
  guest" and using GEAR_GECOS from node.conf instead (kraman@gmail.com)
- Use internal functions for that. (rmillner@redhat.com)
- setup polyinstantiation. (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Set a password on the mongo admin db so that application and ssh'd users
  cannot access the DB. Misc other fixes (kraman@gmail.com)
- Adding support for quota and pam fs limits (kraman@gmail.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Clean up spec file (jhonce@redhat.com)
- Port oo-init-quota command (jhonce@redhat.com)
- Port admin scripts for on-premise (jhonce@redhat.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- Fixed gear admin script and added systemd and init.d startup scripts
  (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.2-1
- new package built with tito

