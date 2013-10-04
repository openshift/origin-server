%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global vendor_ruby /opt/rh/%{scl}/root/usr/share/ruby/vendor_ruby/
    %global mco_agent_root /opt/rh/%{scl}/root/usr/libexec/mcollective/mcollective/agent/
    %global update_yaml_root /opt/rh/ruby193/root/usr/libexec/mcollective/
%else
    %global vendor_ruby /usr/share/ruby/vendor_ruby/
    %global mco_agent_root /usr/libexec/mcollective/mcollective/agent/
    %global update_yaml_root /usr/libexec/mcollective/
%endif

Summary:       M-Collective agent file for openshift-origin-msg-node-mcollective
Name:          openshift-origin-msg-node-mcollective
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      rubygem-openshift-origin-node
Requires:      %{?scl:%scl_prefix}mcollective
Requires:      %{?scl:%scl_prefix}facter
Requires:      openshift-origin-msg-common
BuildArch:     noarch

%description
mcollective communication plugin

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{mco_agent_root}
mkdir -p %{buildroot}%{vendor_ruby}facter
mkdir -p %{buildroot}/etc/cron.minutely
mkdir -p %{buildroot}/usr/libexec/mcollective

cp -p src/openshift.rb %{buildroot}%{mco_agent_root}
cp -p facts/openshift_facts.rb %{buildroot}%{vendor_ruby}facter/
cp -p facts/openshift-facts %{buildroot}/etc/cron.minutely/
cp -p facts/update_yaml.rb %{buildroot}%{update_yaml_root}

%files
%{mco_agent_root}openshift.rb
%{vendor_ruby}facter/openshift_facts.rb
%attr(0700,-,-) %{update_yaml_root}/update_yaml.rb
%attr(0700,-,-) %config(noreplace) /etc/cron.minutely/openshift-facts

%changelog
* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Creating the app secret token (abhgupta@redhat.com)
- Merge pull request #3664 from jwforres/exception_reporting
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_102 - Support OPENSHIFT_SECRET_TOKEN (jhonce@redhat.com)
- Allow for extensions to listen for exceptions that should be reported
  (jforrest@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- Moving update_yaml.rb under the SCL for ruby193-mcollective on RHEL
  (bleanhar@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)
- Node plugin changes for ruby193-mcollective (bleanhar@redhat.com)
- Dependency changes for the SCL mcollective package (bleanhar@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.4-1
- Improve upgrade MCollective response handling (ironcladlou@gmail.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Allow for the mcollective node agent to be extended (jforrest@redhat.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Merge pull request #3311 from detiber/runtime_card_213
  (dmcphers+openshiftbot@redhat.com)
- <runtime> Card origin_runtime_213: realtime node_utilization checks
  (jdetiber@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Merge pull request #3486 from jwhonce/bug/1000580
  (dmcphers+openshiftbot@redhat.com)
- Bug 1000580 - Reduce quota precision (jhonce@redhat.com)
- Bug 1000193: Use an Hourglass in the gear upgrader (ironcladlou@gmail.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Merge pull request #3452 from pravisankar/dev/ravi/bug998905
  (dmcphers+openshiftbot@redhat.com)
- Added environment variable name limitations  - Limit length to 128 bytes.  -
  Allow letters, digits and underscore but can't begin with digit
  (rpenta@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.8-1
- fix bug 999144 - check gear_file against uid map (rchopra@redhat.com)
- Bug 998794 - Allow blank value for a user environment variable
  (rpenta@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.7-1
- Merge pull request #3418 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 994419 (lnader@redhat.com)
- Merge pull request #3410 from pravisankar/dev/ravi/card86
  (dmcphers+openshiftbot@redhat.com)
- User vars node changes:  - Use 'user-var-add' mcollective call for *add*
  and/or *push* user vars. This will reduce unnecessary additional
  code/complexity.  - Add some more reserved var names: PATH, IFS, USER, SHELL,
  HOSTNAME, LOGNAME  - Do not attempt rsync when .env/user_vars dir is empty  -
  Misc bug fixes (rpenta@redhat.com)
- WIP Node Platform - Add support for settable user variables
  (jhonce@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Bug 995599 - Add lock when building cartridge repository (jhonce@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Removing has_app mcollective method since its no longer used
  (abhgupta@redhat.com)
- fix parameter names and validation (rchopra@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3359 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- migration helpers and rest interface for port information of gears
  (rchopra@redhat.com)
- Upgrade tool enhancements (ironcladlou@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- save exposed port interfaces of a gear (rchopra@redhat.com)

* Fri Aug 09 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Bug 995233 - Use oo_spawn in place of systemu (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Card origin_runtime_175 - Report quota on 90%% usage (jhonce@redhat.com)
- Fixing has_app method in mcollective (abhgupta@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Merge pull request #2758 from Miciah/openshift-facts.rb-sort-cart_list
  (dmcphers+openshiftbot@redhat.com)
- openshift_facts.rb: sort cart_list (miciah.masters@gmail.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Upgrade enhancements (ironcladlou@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Add support for upgrade script to be called during cartridge upgrades.
  (pmorie@gmail.com)
- Merge pull request #3069 from sosiouxme/admin-console-mcollective
  (dmcphers+openshiftbot@redhat.com)
- <container proxy> adjust naming for getting facts (lmeyer@redhat.com)
- <mcollective> whitespace + typo fixes (lmeyer@redhat.com)
- <mcollective> adding call to retrieve set of facts for admin-console
  (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.5-1
- Merge pull request #3031 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- mcoll action for getting env vars for a gear (rchopra@redhat.com)
- Fix gear env loading by using ApplicationContainer::from_uuid instead of
  ApplicationContainer::new (kraman@gmail.com)

* Fri Jul 05 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
- Routing plug-in for broker. Code base from github/miciah/broker-plugin-
  routing-activemq (miciah.masters@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Merge pull request #2934 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Fixing class/module namespaces Fixing tests Fixing rebase errors Un-hardcode
  context in step_definitions/cartridge-php_steps.rb Fixing paths that were
  broken when going from File.join -> PathUtils.join (kraman@gmail.com)
- Refactor code to use run_in_container_context/run_in_root_context calls
  instead of generically calling oo_spawn and passing uid. Modify frontend
  httpd/proxy classes to accept a container object instead of indivigual
  properties (kraman@gmail.com)
- Moving Node classes into Runtime namespace Removing UnixUser Moving
  functionality into SELinux plugin class (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Moving scaled deploy into the platform (dmcphers@redhat.com)
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Rename migrate to upgrade in code (pmorie@gmail.com)
- Move core migration into origin-server (pmorie@gmail.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Bug 972757 (asari.ruby@gmail.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- remove threads for now (rchopra@redhat.com)
- parallelization of app events across gears (rchopra@redhat.com)
- Node timeout handling improvements (ironcladlou@gmail.com)
- Change working directory to /tmp for openshift mcol agent (pmorie@gmail.com)
- Make NodeLogger pluggable (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.3-1
- Bug 965317 - Add way to patch File class so all files have sync enabled.
  (rmillner@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- WIP Cartridge Refactor - Install cartridges without mco client
  (jhonce@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Broker changes for supporting unsubscribe connection event. Details: When one
  of the component is removed from the app and if it has published some content
  to other components located on different gears, we issue unsubscribe event on
  all the subscribing gears to cleanup the published content.
  (rpenta@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2255 from brenton/oo-accept-systems
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_239 - Download cartridge from URL (jhonce@redhat.com)
- Bug 957045 - fixing oo-accept-systems for v2 cartridges (bleanhar@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #2227 from ironcladlou/bz/955538
  (dmcphers+openshiftbot@redhat.com)
- Combine stderr/stdout for cartridge actions (ironcladlou@gmail.com)
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.4-1
- Bug 952408 - Node filters threaddump calls (jhonce@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)
- Adding checks for ssh key matches (abhgupta@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- WIP Cartridge Refactor - Support V1 contract for CLIENT_ERROR
  (jhonce@redhat.com)
- fixing rebase (tdawson@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- WIP Cartridge Refactor - more robust oo-admin-cartridge (jhonce@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- WIP Cartridge Refactor - Roll out old threaddump support (jhonce@redhat.com)
- WIP Cartridge Refactor - Add PHP support for threaddump (jhonce@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Add SNI upload support to API (lnader@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Replacing get_value() with config['param'] style calls for new version of
  parseconfig gem. (kraman@gmail.com)
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1629 from jwhonce/wip/cartridge_repository
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1622 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- remove old obsoletes (tdawson@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1604 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- Adding the ability to fetch all gears with broker auth tokens
  (bleanhar@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Bug 918480 (dmcphers@redhat.com)
- Bug 917990 - Multiple fixes. (rmillner@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Bug 916918 - Couple of issues with frontend calls. (rmillner@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Bug 916918 - Add frontend calls to allowed actions. (rmillner@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- reverted US2448 (lnader@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- US2448 (lnader@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Bug 913351 - Cannot create application successfully when district is added
  (jhonce@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Bug 912899 - mcollective changing all numeric mongoid to BigInt
  (jhonce@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Commands and mcollective calls for each FrontendHttpServer API.
  (rmillner@redhat.com)
- Bug 912292: Return namespace update output on reply (ironcladlou@gmail.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 842991 - Do not replace /etc/cron.minutely/openshift-facts when
  installing new rpm. (jhonce@redhat.com)
- Fix mcollective plugin rubygem dependency (john@ibiblio.org)
- Fixes for ruby193 (john@ibiblio.org)
- Audit oo_* return value in agent (pmorie@gmail.com)
- Return output from oo_status in agent (pmorie@gmail.com)
- Return connector execution output on the MCol reply (ironcladlou@gmail.com)
- Refactor agent and proxy, move all v1 code to v1 model
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1255 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> active_capacity/max_active_apps/etc switched to
  gear-based accounting (lmeyer@redhat.com)
- Merge pull request #1238 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> reckon by gears (as opposed to git repos), add gear
  status facts (lmeyer@redhat.com)
- <facter> some code cleanup - no functional change (lmeyer@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Reduce logging noise in MCollective agent (ironcladlou@gmail.com)
- Switch calling convention to match US3143 (rmillner@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- SSL support for custom domains. (mpatel@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- - oo-setup-broker fixes:  - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:  -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1052 from rmillner/BZ877321 (openshift+bot@redhat.com)
- Add username to filter list. (rmillner@redhat.com)
- Hide the password in mcollective logs. (rmillner@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Proper host name validation. (rmillner@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Security - Fix the full path to restorecon it was causing errors in the logs
  (tkramer@redhat.com)
- more mco 2.2 changes (dmcphers@redhat.com)
- repacking for mco 2.2 (dmcphers@redhat.com)
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Merge pull request #1002 from tdawson/tdawson/fed-update/msg-node-
  mcollective-1.1.4 (openshift+bot@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)
- Removed spec clutter for building on rhel5 (tdawson@redhat.com)
- mco value passing cleanup (dmcphers@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- add any validator for mco 2.2 (dmcphers@redhat.com)
- Various mcollective changes getting ready for 2.2 (dmcphers@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- add backtraces to error conditions in agent (dmcphers@redhat.com)
- Changing same uid move to rsync (dmcphers@redhat.com)
- use /bin/env for cron (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- Add method to get the active gears (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ 876942:Disable threading until we can explore proper concurrency
  management (rmillner@redhat.com)
- Only use scl if it's available (ironcladlou@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- add config to gemspec (dmcphers@redhat.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
