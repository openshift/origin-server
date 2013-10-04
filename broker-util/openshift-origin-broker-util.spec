%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global rubyabi 1.9.1

Summary:       Utility scripts for the OpenShift Origin broker
Name:          openshift-origin-broker-util
Version: 1.16.0
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      openshift-origin-broker
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
Requires:      mongodb
# For oo-register-dns
Requires:      bind-utils
# For oo-admin-broker-auth
Requires:      %{?scl:%scl_prefix}mcollective-client
BuildArch:     noarch

%description
This package contains a set of utility scripts for the openshift broker.  
They must be run on a openshift broker instance.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_sbindir}
cp -p oo-* %{buildroot}%{_sbindir}/

mkdir -p %{buildroot}%{_mandir}/man8/
cp man/*.8 %{buildroot}%{_mandir}/man8/

%files
%doc LICENSE
%attr(0750,-,-) %{_sbindir}/oo-admin-chk
%attr(0750,-,-) %{_sbindir}/oo-admin-repair
%attr(0750,-,-) %{_sbindir}/oo-admin-clear-pending-ops
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-app
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-authorization
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-district
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-domain
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-usage
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-user
%attr(0750,-,-) %{_sbindir}/oo-admin-move
%attr(0750,-,-) %{_sbindir}/oo-admin-upgrade
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-auth
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-cache
%attr(0750,-,-) %{_sbindir}/oo-admin-usage
%attr(0750,-,-) %{_sbindir}/oo-analytics-export
%attr(0750,-,-) %{_sbindir}/oo-analytics-import
%attr(0750,-,-) %{_sbindir}/oo-register-dns
%attr(0750,-,-) %{_sbindir}/oo-accept-broker
%attr(0750,-,-) %{_sbindir}/oo-accept-systems
%attr(0750,-,-) %{_sbindir}/oo-stats
%attr(0750,-,-) %{_sbindir}/oo-quarantine

%{_mandir}/man8/oo-admin-chk.8.gz
%{_mandir}/man8/oo-admin-clear-pending-ops.8.gz
%{_mandir}/man8/oo-admin-repair.8.gz
%{_mandir}/man8/oo-admin-ctl-app.8.gz
%{_mandir}/man8/oo-admin-ctl-district.8.gz
%{_mandir}/man8/oo-admin-ctl-domain.8.gz
%{_mandir}/man8/oo-admin-ctl-usage.8.gz
%{_mandir}/man8/oo-admin-ctl-user.8.gz
%{_mandir}/man8/oo-admin-move.8.gz
%{_mandir}/man8/oo-admin-broker-auth.8.gz
%{_mandir}/man8/oo-admin-broker-cache.8.gz
%{_mandir}/man8/oo-admin-usage.8.gz
%{_mandir}/man8/oo-register-dns.8.gz
%{_mandir}/man8/oo-accept-broker.8.gz
%{_mandir}/man8/oo-accept-systems.8.gz
%{_mandir}/man8/oo-stats.8.gz

%changelog
* Wed Oct 02 2013 Adam Miller <admiller@redhat.com> 1.15.6-1
- Merge pull request #3756 from pravisankar/dev/ravi/rename-node-removed
  (dmcphers+openshiftbot@redhat.com)
- Renamed field 'node_removed' to 'removed' in gear model (rpenta@redhat.com)
- Merge pull request #3742 from pravisankar/dev/ravi/misc-bugfixes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3750 from ironcladlou/bz/1008645
  (dmcphers+openshiftbot@redhat.com)
- Bug 1008645: Fix --ignore-cartridge-version update option
  (ironcladlou@gmail.com)
- fix bz1012709 - remove gear's ssh keys. add debugging to admin-clear-pending-
  ops (rchopra@redhat.com)
- Bug 1012264 : oo-admin-repair --removed-nodes fixes (rpenta@redhat.com)

* Mon Sep 30 2013 Troy Dawson <tdawson@redhat.com> 1.15.5-1
- Merge pull request #3733 from pravisankar/dev/ravi/bug1012782
  (dmcphers+openshiftbot@redhat.com)
- Bug 1012782 - oo-admin-chk fix (rpenta@redhat.com)
- oo-admin-repair changes (rpenta@redhat.com)
- Bug 1012297 - Pass gear_id instead of gear_uuid to application remove_gear()
  (rpenta@redhat.com)
- Bug 1012264 - Remove all unresponsive db features + misc bug fixes
  (rpenta@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- Bug 1012264 - Pretty print usage duration in oo-admin-ctl-usage script
  (rpenta@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Add rake test for extended integration tests (rpenta@redhat.com)
- oo-admin-repair fixes (rpenta@redhat.com)
- Added skip_node_ops flag to app/domain/user/district models.
  (rpenta@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Fix for bug 1010632 (abhgupta@redhat.com)
- Creating the app secret token (abhgupta@redhat.com)
- Merge pull request #3648 from pravisankar/dev/ravi/misc-fixes
  (dmcphers+openshiftbot@redhat.com)
- Allow/Disallow HA capability from oo-admin-ctl-user script Show user plan in
  oo-admin-ctl-user output (rpenta@redhat.com)
- Fix for bug 1007582 and bug 1008517 (abhgupta@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- force destroy should take care of usage too (rchopra@redhat.com)
- Bug 1007711: Fix upgraded gear count reporting (ironcladlou@gmail.com)
- Merge pull request #3632 from pravisankar/dev/ravi/bug-fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 998467 - Add addtional storage mismatch checks in oo-admin-chk
  (rpenta@redhat.com)
- Bug 998810 - Handle symbols during sort (rpenta@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)
- Adding oo-mco and updating oo-diagnostics to support the SCL'd mcollective
  (bleanhar@redhat.com)
- Dependency changes for the SCL mcollective package (bleanhar@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.5-1
- <oo-admin-ctl-usage> Bug 990451, use Mongo config options for Moped session
  https://bugzilla.redhat.com/show_bug.cgi?id=990451 (jolamb@redhat.com)
- Merge pull request #3617 from ironcladlou/dev/upgrade-stability
  (dmcphers+openshiftbot@redhat.com)
- Improve upgrade MCollective response handling (ironcladlou@gmail.com)

* Wed Sep 11 2013 Adam Miller <admiller@redhat.com> 1.14.4-1
- Merge pull request #3613 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3610 from ironcladlou/bz/1001855
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1005007 and bug 1006526 (abhgupta@redhat.com)
- Merge pull request #3604 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Bug 1001855: Process all active gears before inactive (ironcladlou@gmail.com)
- Fix for bug 1006223 (abhgupta@redhat.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Merge pull request #3583 from jwforres/admin_console_capacity_planning-fork
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3588 from abhgupta/abhgupta-scheduler
  (dmcphers@redhat.com)
- The uuid attribute is being removed from the application documents
  (abhgupta@redhat.com)
- <admin stats> refactor and mods for admin console (lmeyer@redhat.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Fix for bug 1005151 (abhgupta@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Upgrade fix for warning handling (ironcladlou@gmail.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Bug 1000193: Use an Hourglass in the gear upgrader (ironcladlou@gmail.com)
- Fix test cases (ccoleman@redhat.com)
- Merge pull request #3459 from pravisankar/dev/ravi/bug999702
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Bug 999702 - oo-admin-chk: Don't sort usage records based on time, instead
  update app_name based on created_at field (rpenta@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.8-1
- Merge pull request #3442 from smarterclayton/oo_admin_user_not_setting_domain
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3326 from kraman/admin_command_connection_hooks
  (dmcphers+openshiftbot@redhat.com)
- fix 998355, last gear of a cart cannot be removed (rchopra@redhat.com)
- oo-admin-ctl-user should update child domains when new gear size added
  (ccoleman@redhat.com)
- New admin command to call connection hooks on an application.
  (kraman@gmail.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.7-1
- Merge pull request #3423 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- bz998355 oo-admint-ctl-app fix for sparse components (rchopra@redhat.com)
- Merge pull request #3421 from pravisankar/dev/ravi/bug997352
  (dmcphers+openshiftbot@redhat.com)
- Bug 997352 - Added usage_record -> usage inconsistency checks
  (rpenta@redhat.com)
- Merge pull request #3417 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 991398 (abhgupta@redhat.com)
- <Admin::Stats> use only strings for hash keys (lmeyer@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Handle lack of JSON reply from gear upgrades (ironcladlou@gmail.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Merge pull request #3371 from
  smarterclayton/bug_997374_fix_man_for_oo_admin_ctl_domain
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3358 from sosiouxme/oo-stats-mods
  (dmcphers+openshiftbot@redhat.com)
- <oo-stats> ability to read results from file; more (lmeyer@redhat.com)
- <Admin::Stats> refactor classes and tests (lmeyer@redhat.com)
- Bug 997374 - Fix man page for oo-admin-ctl-domain (ccoleman@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Upgrade tool enhancements (ironcladlou@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Fix for bug 990927 (abhgupta@redhat.com)
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 989908 (abhgupta@redhat.com)
- Fix for bug 990927 (abhgupta@redhat.com)
- Check denormalization in oo-admin-chk (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_ui_73_membership_model (ccoleman@redhat.com)
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

* Fri Aug 09 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Fix for bug 990956 (abhgupta@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- cleanup (dmcphers@redhat.com)
- Fix for bug 985496 (abhgupta@redhat.com)
- Merge pull request #3260 from pmorie/bugs/988782
  (dmcphers+openshiftbot@redhat.com)
- Bug 990948 (dmcphers@redhat.com)
- Fix bug 988782: add --rerun to oo-admin-upgrade help (pmorie@gmail.com)
- Bug 989642 - Fix generating usage record chunks in oo-admin-ctl-usage script
  (rpenta@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.8-1
- Merge pull request #3248 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Admin script cleanup (dmcphers@redhat.com)
- Remove old logic from oo-admin-upgrade (dmcphers@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.7-1
- Merge pull request #3245 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz990341 (rchopra@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.6-1
- oo-admin-ctl-user shouldn't be setting allowed_gear_sizes on domain yet
  (ccoleman@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Merge pull request #3213 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3219 from tdawson/tdawson/spec-cleanup/2013-07
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3064 from Miciah/oo-accept-broker-check_selinux_booleans-
  check-httpd_execmem (dmcphers+openshiftbot@redhat.com)
- cleanup / fedoraize openshift-origin-node-util.spec (tdawson@redhat.com)
- Fix for bug 989650, bug 988115, and added additional check in oo-admin-chk
  (abhgupta@redhat.com)
- Fix for bug 985496 (abhgupta@redhat.com)
- oo-accept-broker: check httpd_execmem (miciah.masters@gmail.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Simplify capabilities to be more model like, and support clean proxying of
  inherited properties (ccoleman@redhat.com)
- Support running broker tests directly Force scopes to use checked ids and
  avoid symbolizing arbitrary strings Use .present? instead of .count > 0 (for
  performance) Handle ValidationExceptions globally (ccoleman@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Merge pull request #3170 from pmorie/dev/upgrade_analysis
  (dmcphers+openshiftbot@redhat.com)
- Upgrade enhancements (ironcladlou@gmail.com)
- Merge pull request #3160 from pravisankar/dev/ravi/card78
  (dmcphers+openshiftbot@redhat.com)
- For consistency, rest api response must display 'delete' instead 'destroy'
  for user/domain/app (rpenta@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Merge pull request #3151 from pravisankar/dev/ravi/ctl-usage-fixes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-ctl-usage: Process billing and non-billing usage records separately
  (rpenta@redhat.com)
- <oo-admin-clear-pending-ops> man page added (lmeyer@redhat.com)
- <oo-stats> splitting into first admin library class (lmeyer@redhat.com)
- Merge pull request #2759 from Miciah/oo-admin-ctl-domain-use-
  CloudUser.find_or_create_by_id (dmcphers+openshiftbot@redhat.com)
- Remove ecdsa ssh key type from supported list. Rationale: Due to patent
  concerns, ECC support is not bundled in fedora/rhel(needed for ecdsa key
  generation).            So even if someone has a valid ecdsa keys, sshd
  server on our node won't be able to authenticate the user.
  (rpenta@redhat.com)
- Merge pull request #3083 from smarterclayton/strong_consistency_is_default
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3072 from pravisankar/dev/ravi/bug969876
  (dmcphers+openshiftbot@redhat.com)
- Strong consistency is the default for mongoid (ccoleman@redhat.com)
- Bug 982994 - Minor: add version/help options to usage info
  (rpenta@redhat.com)
- oo-admin-ctl-domain: don't use CloudUser.new (miciah.masters@gmail.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Bug 980333 - Add missing 'exit 1' in oo-admin-ctl-domain (rpenta@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Moving scaled deploy into the platform (dmcphers@redhat.com)
- Remove Online specific references: -Remove hard-coded cart name references.
  -Remove login validations from CloudUser model, login validation must be done
  by authentication plugin. -Remove 'medium' gear size references -All 'small'
  gear size references must be from configuration files. -Remove stale
  application_observer.rb and its references -Remove stale 'abstract' cart
  references -Remove duplicate code from rest controllers -Move all
  get_rest_{user,domain,app,cart} methods in RestModelHelper module. -Cleanup
  unnecessary TODO/FIXME comments in broker. (rpenta@redhat.com)
- oo-admin-ctl-usage fixes: Create index on 'gear_id'+'usage_type'+'created_at'
  fields for usage_records mongo collection. (rpenta@redhat.com)
- Rename migrate to upgrade in code (pmorie@gmail.com)
- Move core migration into origin-server (pmorie@gmail.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 1.10.5-1
- Merge pull request #2905 from pravisankar/dev/ravi/bug975713
  (dmcphers+openshiftbot@redhat.com)
- Bug 975713 - oo-admin-chk fix (rpenta@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Bug 975388 - oo-admin-usage fixes (rpenta@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Merge pull request #2872 from pravisankar/dev/ravi/bug973918
  (dmcphers+openshiftbot@redhat.com)
- Bug 973918 - Do not allow move gear with oo-admin-move without districts.
  (rpenta@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- oo-admin-chk fix: Do not generate gear_id_hash for subaccount users
  (rpenta@redhat.com)
- oo-admin-chk fixes (rpenta@redhat.com)
- fix staleness issue with apps (rchopra@redhat.com)
- Added Usage consistency checks as part of oo-admin-chk script
  (rpenta@redhat.com)
- <broker-util> Bug 972308 - Update permissions check for user_action.log
  (jdetiber@redhat.com)
- Merge pull request #2732 from adelton/oo-accept-broker-krb
  (dmcphers+openshiftbot@redhat.com)
- With BIND_KRB_*, nsupdate -g needs to be used. (jpazdziora@redhat.com)
- Account for case when BIND_KRB_* is used in openshift-origin-dns-
  nsupdate.conf. (jpazdziora@redhat.com)
- Add option to use GSS-TSIG Kerberos credentials to bind.
  (jpazdziora@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- Checking consumed gears mismatch only if requested (abhgupta@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- fix clear-pending-ops script to handle created_at.nil? (rchopra@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- Merge pull request #2607 from rajatchopra/master (dmcphers@redhat.com)
- Merge pull request #2602 from tbielawa/grammarfix
  (dmcphers+openshiftbot@redhat.com)
- fix bz965949 - include Mongo as object qualifier (rchopra@redhat.com)
- Rebuild that man page (tbielawa@redhat.com)
- Grammar fix in oo-admin-ctl-user man page (tbielawa@redhat.com)
- Renaming oo-admin-fix to oo-admin-repair (abhgupta@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- clean pending ops script to ensure rollbacks when needed; fix downloaded
  manifest screening (rchopra@redhat.com)
- Merge pull request #2499 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 957164 (lnader@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- Merge pull request #2540 from pravisankar/dev/ravi/bug963981
  (dmcphers+openshiftbot@redhat.com)
- Bug 963981 - Fix app events controller Use canonical_name/canonical_namespace
  for application/domain respectively when using find_by op.
  (rpenta@redhat.com)
- Fixes based on review by Ravi (abhgupta@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Fix for bug 963654 (abhgupta@redhat.com)
- add parent_user_id to user collection for export (rchopra@redhat.com)
- Fixing broken check to confirm gear UID existence in mongo
  (abhgupta@redhat.com)
- Merge pull request #2477 from detiber/bz958573
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2470 from lnader/536 (dmcphers+openshiftbot@redhat.com)
- <oo-admin-chk> Bug 958573 - Fix output when ssh key mismatch found
  (jdetiber@redhat.com)
- online_broker_536 (lnader@redhat.com)
- Initial implementation for fixing district available UID mismatch
  (abhgupta@redhat.com)
- Initial implementation for fixing consumed gears mismatch
  (abhgupta@redhat.com)
- Merge pull request #2444 from detiber/bz961255
  (dmcphers+openshiftbot@redhat.com)
- <controller,broker-util> Bug 961255 - DataStore fixes for mongo ssl
  (jdetiber@redhat.com)
- <oo-accept-broker> Bug 959164 - Fix mongo test with replica sets
  (jdetiber@redhat.com)
- analytics should contain user login too (rchopra@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- improved analytics import script that logs more information about what is
  going on (rchopra@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- <broker><oo-accept-broker> Bug 958674 - Fix Mongo SSL support
  (jdetiber@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Fix for bug 956441  - increasing mcollective timeout for oo-admin-chk
  (abhgupta@redhat.com)
- Merge pull request #2308 from detiber/bz958437
  (dmcphers+openshiftbot@redhat.com)
- reslience to broken apps in analytics import cleanup (rchopra@redhat.com)
- <oo-accept-broker> Bug 958437 - Making CONSOLE_SECRET check dependent on
  existence of CONSOLE_CONF (jdetiber@redhat.com)
- Merge pull request #2288 from detiber/bz955789
  (dmcphers+openshiftbot@redhat.com)
- fix oo-analytics-import to use global authentication for new db
  (rchopra@redhat.com)
- Bug 955789 - Enabling mongo connection check in oo-accept-broker
  (jdetiber@redhat.com)
- Fixing typo (abhgupta@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Merge pull request #2279 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2230 from pravisankar/dev/ravi/card559
  (dmcphers+openshiftbot@redhat.com)
- Displaying the count of applications fixed/failed for ssh key mismatches
  (abhgupta@redhat.com)
- Preventing false positives from being reported for oo-admin-chk and bug fixes
  - Fix for bug 954800  - Fix for bug 955187  - Fix for bug 955359
  (abhgupta@redhat.com)
- Merge pull request #2263 from sosiouxme/bz957818
  (dmcphers+openshiftbot@redhat.com)
- <cache> bug 957818 - clear-cache script, oo-cart-version uses it
  (lmeyer@redhat.com)
- Removed 'setmaxstorage' option for oo-admin-ctl-user script. Added
  'setmaxtrackedstorage' and 'setmaxuntrackedstorage' options for oo-admin-ctl-
  user script. Updated oo-admin-ctl-user man page. Max allowed additional fs
  storage for user will be 'max_untracked_addtl_storage_per_gear' capability +
  'max_tracked_addtl_storage_per_gear' capability. Don't record usage for
  additional fs storage if it is less than
  'max_untracked_addtl_storage_per_gear' limit. Fixed unit tests and models to
  accommodate the above change. (rpenta@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Fixing the rest-client dependency in broker-util (bleanhar@redhat.com)
- Bug 957045 - fixing oo-accept-systems for v2 cartridges (bleanhar@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2240 from detiber/bz956670
  (dmcphers+openshiftbot@redhat.com)
- Bug 956670 - Fix static references to small gear size (jdetiber@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #2222 from detiber/sessionsecret
  (dmcphers+openshiftbot@redhat.com)
- <oo-accept-broker> Fix test for SESSION_SECRET (jdetiber@redhat.com)
- <broker> Updated spec file for correct user_action.log location <oo-accept-
  broker> Added permission check for rest api logs (jdetiber@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- <oo-accept-broker> test for oo-ruby in path (jolamb@redhat.com)
- <oo-accept-broker> replace safe_ruby fxn wrapper with oo-ruby
  (jolamb@redhat.com)
- <oo-accept-broker> more rhel/fedora reconciliation, cleanup
  (jolamb@redhat.com)
- <oo-accept-broker> cleanup, documentation comment (jolamb@redhat.com)
- <oo-accept-broker> Fixes to generalize over RHEL and Fedora
  (jolamb@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Merge pull request #2155 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2152 from pravisankar/dev/ravi/plan_history_cleanup
  (dmcphers+openshiftbot@redhat.com)
- eventual consistency is alright in some cases (rchopra@redhat.com)
- Added pre_sync_usage, post_sync_usage operations in oo-admin-ctl-usage script
  (rpenta@redhat.com)
- refix unreserve_uid when destroying gear (rchopra@redhat.com)
- unreserve should not happen twice over (rchopra@redhat.com)
- Adding support for Bearer auth in the sample remote-user plugin
  (bleanhar@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.7-1
- Fix for bug 952551 Preventing the removal of gears that host singletons
  through admin script (abhgupta@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.6-1
- Merge pull request #2042 from maxamillion/dev/maxamillion/oo-accept-cleanup
  (dmcphers+openshiftbot@redhat.com)
- fix '[: ==: unary operator expected' errors (admiller@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- Merge pull request #2018 from abhgupta/abhgupta-dev (dmcphers@redhat.com)
- Merge pull request #2026 from rajatchopra/master (dmcphers@redhat.com)
- fix analytics to provide more details (rchopra@redhat.com)
- Fix for bug 950974 Handling NodeException in the script (abhgupta@redhat.com)
- Fix for bug 951031 We are now correctly listing the acceptable argument to
  the oo-admin-usage script as gear id instead of gear uuid
  (abhgupta@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Merge pull request #2001 from brenton/misc2 (dmcphers@redhat.com)
- Merge pull request #1998 from pravisankar/dev/ravi/card526
  (dmcphers@redhat.com)
- oo-admin-broker-auth manpage fix (bleanhar@redhat.com)
- Add 'plan_history' to CloudUser model. oo-admin-ctl-usage will also cache
  'plan_history' and will pass to sync_usage(). (rpenta@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Bug 949819 (lnader@redhat.com)
- Change 'allow_change_district' to 'change_district' and remove warnings when
  target server or district is specified. Fix start/stop carts order in move
  gear. (rpenta@redhat.com)
- Adding checks for ssh key matches (abhgupta@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Handling case where the user is not present (abhgupta@redhat.com)
- oo-accept-broker: fix and enable SELinux checks (miciah.masters@gmail.com)
- Merge pull request #1669 from tdawson/tdawson/minor-spec-cleanup/2013-03-15
  (dmcphers+openshiftbot@redhat.com)
- Typo fixes (bleanhar@redhat.com)
- fixing rebase (tdawson@redhat.com)
- Adding ability to add and remove domain wide environment variables from admin
  script (kraman@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- Merge pull request #1789 from brenton/master (dmcphers@redhat.com)
- Merge pull request #1777 from kraman/remove_oo_scripts
  (dmcphers+openshiftbot@redhat.com)
- Removing oo-setup-* scripts as they have been replaced by puppet and ansible
  modules. Updating puppet setup docs (kraman@gmail.com)
- Merge remote-tracking branch 'origin/master' into update_to_new_plan_values
  (ccoleman@redhat.com)
- Remove references to plans from origin-server (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into update_to_new_plan_values
  (ccoleman@redhat.com)
- MegaShift => Silver (ccoleman@redhat.com)
- Adding SESSION_SECRET settings to the broker and console
  (bleanhar@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Fix for bug 927154 Fixing multiple issues in remove-gear command of admin
  script (abhgupta@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Fix for the underlying issue behind bug 924651 (abhgupta@redhat.com)
- Merge pull request #1768 from rajatchopra/master (dmcphers@redhat.com)
- handle broken ops, and reset state of ops that failed to clear
  (rchopra@redhat.com)
- Fix for bug 924651 (abhgupta@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- fix BZ923579 - no uuid for user/domain (rchopra@redhat.com)
- Fix for bug 923176  - Handling missing or empty component_instances  -
  Handling false positives for UID checks for districts (abhgupta@redhat.com)
- Merge pull request #1708 from brenton/BZ923070
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 923070 - Removing duplicate warning from oo-admin-broker-auth
  (bleanhar@redhat.com)
- fix for bug918947, remove gear called on non-existent gear of an app
  (rchopra@redhat.com)
- Bug 923070 - removing duplicate mongo call in oo-admin-broker-auth
  (bleanhar@redhat.com)
- Merge pull request #1692 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- spec file fixed for analytics utilities (rchopra@redhat.com)
- analytics data export/import (rchopra@redhat.com)
- Merge pull request #1679 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Modifying the man page and usage details for oo-admin-chk
  (abhgupta@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Reporting errors for gears that aren't found (bleanhar@redhat.com)
- Bug 922678 - Fixing oo-admin-broker-auth's --rekey option
  (bleanhar@redhat.com)
- Bug 922677 - Warning if --find-gears can't locate all nodes
  (bleanhar@redhat.com)
- Merge pull request #1633 from lnader/revert_pull_request_1486
  (dmcphers+openshiftbot@redhat.com)
- Changed private_certificate to private_ssl_certificate (lnader@redhat.com)
- Add SNI upload support to API (lnader@redhat.com)
- Improving efficiency of checks and fixing empty gear check Additional fixes
  for oo-admin-chk (abhgupta@redhat.com)
- Merge pull request #1660 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- improve clear-pending-ops to handle new failures as shown in prod
  (rchopra@redhat.com)
- Adding additional checks to oo-admin-chk script (abhgupta@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Merge pull request #1637 from brenton/BZ921257 (dmcphers@redhat.com)
- Lots of oo-accept-broker fixes (bleanhar@redhat.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- Bug 921257 - Warn users to change the default AUTH_SALT (bleanhar@redhat.com)
- Merge pull request #1607 from brenton/oo-admin-broker-auth
  (dmcphers+openshiftbot@redhat.com)
- Adding oo-admin-broker-auth (bleanhar@redhat.com)
- fix bug919379 (rchopra@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- Fix for bug 919190 - adding a space in the info text (abhgupta@redhat.com)
- Adding man page for oo-admin-ctl-script (abhgupta@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- BZ917491 - [ORIGIN]oo-register-dns on broker has duplicate options
  (calfonso@redhat.com)
- Merge pull request #1564 from danmcp/master (dmcphers@redhat.com)
- Bug 918480 (dmcphers@redhat.com)
- Sync usage fixes (rpenta@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Skip Usage capture for sub-account users (rpenta@redhat.com)

* Mon Mar 04 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- oo-admin-ctl-usage fixes (rpenta@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Removing mcollective qpid plugin and adding some more doc
  (dmcphers@redhat.com)
- bypass failures; handle nil ops; no_timeout (rchopra@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- Merge pull request #1441 from pravisankar/dev/ravi/us3409
  (dmcphers+openshiftbot@redhat.com)
- fix oo-admin-clear-pending-ops with respect to rollbacks (rchopra@redhat.com)
- Added index on 'login' for usage_record and usage mongoid models Added
  separate usage audit log, /var/log/openshift/broker/usage.log instead of
  syslog. Moved user action log from /var/log/openshift/user_action.log to
  /var/log/openshift/broker/user_action.log Added Distributed lock used in oo-
  admin-ctl-usage script Added Billing Service interface Added oo-admin-ctl-
  usage script to list and sync usage records to billing vendor Added oo-admin-
  ctl-usage to broker-util spec file Fixed distributed lock test Add billing
  service to origin-controller Some more bug fixes (rpenta@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Bug 914639 (dmcphers@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Implement authorization support in the broker (ccoleman@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.4-2
- bump Release for fixed build target rebuild (admiller@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- bug 915228 - <oo-admin-ctl-user> validate gear size before adding
  https://bugzilla.redhat.com/show_bug.cgi?id=915228 Adding an invalid gear
  size shouldn't be successful. Check against configured gear sizes first.
  (lmeyer@redhat.com)
- Bug 914639 (dmcphers@redhat.com)
- admin script to push clogged pending ops (rchopra@redhat.com)

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

