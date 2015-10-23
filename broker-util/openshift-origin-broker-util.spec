%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global scl_root /opt/rh/ruby193/root
    %global ruby_libdir /usr/share/ruby
%endif
%global rubyabi 1.9.1

Summary:       Utility scripts for the OpenShift Origin broker
Name:          openshift-origin-broker-util
Version: 1.37.4
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: %{?scl:%scl_prefix}ruby-devel
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
Requires:      which
Requires:      tar
Requires:      openssh-clients
Requires:      %{?scl:%scl_prefix}rubygem-net-ldap
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

mkdir -p %{buildroot}%{?scl:%scl_root}%{ruby_libdir}
cp -p lib/*.rb %{buildroot}%{?scl:%scl_root}%{ruby_libdir}

mkdir -p %{buildroot}%{_mandir}/man8/
cp -p man/*.8 %{buildroot}%{_mandir}/man8/

%files
%doc LICENSE
%attr(0750,-,-) %{_sbindir}/oo-accept-broker
%attr(0750,-,-) %{_sbindir}/oo-accept-systems
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-auth
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-cache
%attr(0750,-,-) %{_sbindir}/oo-admin-chk
%attr(0750,-,-) %{_sbindir}/oo-admin-clear-pending-ops
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-app
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-authorization
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-district
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-region
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-domain
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-usage
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-user
%attr(0750,-,-) %{_sbindir}/oo-admin-move
%attr(0750,-,-) %{_sbindir}/oo-admin-repair
%attr(0750,-,-) %{_sbindir}/oo-admin-upgrade
%attr(0750,-,-) %{_sbindir}/oo-admin-usage
%attr(0750,-,-) %{_sbindir}/oo-analytics-export
%attr(0750,-,-) %{_sbindir}/oo-analytics-import
%attr(0750,-,-) %{_sbindir}/oo-app-info
%attr(0750,-,-) %{_sbindir}/oo-quarantine
%attr(0750,-,-) %{_sbindir}/oo-register-dns
%attr(0750,-,-) %{_sbindir}/oo-stats
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-team
%attr(0750,-,-) %{_sbindir}/oo-plot-broker-stats

%{?scl:%scl_root}%{ruby_libdir}/app_info.rb

%{_mandir}/man8/oo-accept-broker.8.gz
%{_mandir}/man8/oo-accept-systems.8.gz
%{_mandir}/man8/oo-admin-broker-auth.8.gz
%{_mandir}/man8/oo-admin-broker-cache.8.gz
%{_mandir}/man8/oo-admin-chk.8.gz
%{_mandir}/man8/oo-admin-clear-pending-ops.8.gz
%{_mandir}/man8/oo-admin-ctl-app.8.gz
%{_mandir}/man8/oo-admin-ctl-authorization.8.gz
%{_mandir}/man8/oo-admin-ctl-cartridge.8.gz
%{_mandir}/man8/oo-admin-ctl-district.8.gz
%{_mandir}/man8/oo-admin-ctl-region.8.gz
%{_mandir}/man8/oo-admin-ctl-domain.8.gz
%{_mandir}/man8/oo-admin-ctl-usage.8.gz
%{_mandir}/man8/oo-admin-ctl-user.8.gz
%{_mandir}/man8/oo-admin-move.8.gz
%{_mandir}/man8/oo-admin-repair.8.gz
%{_mandir}/man8/oo-admin-upgrade.8.gz
%{_mandir}/man8/oo-admin-usage.8.gz
%{_mandir}/man8/oo-app-info.8.gz
%{_mandir}/man8/oo-register-dns.8.gz
%{_mandir}/man8/oo-stats.8.gz
%{_mandir}/man8/oo-analytics-export.8.gz
%{_mandir}/man8/oo-analytics-import.8.gz
%{_mandir}/man8/oo-quarantine.8.gz
%{_mandir}/man8/oo-admin-ctl-team.8.gz

%changelog
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.37.4-1
- oo-admin-ctl-app: Fix remove-gear ignores min scale setting
  (vdinh@redhat.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.37.3-1
- oo-admin-ctl-district-elaborate-on-node-identity (miciah.masters@gmail.com)
- Fix typo for gear_whitelist (oo-admin-upgrade) (william17.burton@gmail.com)

* Fri Oct 03 2015 William Burton <wburton@redhat.com> 1.37.3-1
- Fix typo for gear_whitelist when calling oo-admin-move upgrade-node

* Wed Sep 23 2015 Stefanie Forrester <sedgar@redhat.com> 1.37.2-1
- oo-admin-broker-cache: Delete --console flag (miciah.masters@gmail.com)

* Thu Sep 17 2015 Unknown name 1.37.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.36.3-1
- Merge pull request #6216 from tiwillia/memberDomainErrors
  (dmcphers+openshiftbot@redhat.com)
- Improve error reporting for member add/remove/update through oo-admin-ctl-
  domain (tiwillia@redhat.com)
- Merge pull request #6187 from tiwillia/bz1152524
  (dmcphers+openshiftbot@redhat.com)
- Check MongoDB hosts connectivty prior to loading broker rails environment
  (tiwillia@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.36.2-1
- Bug 1214087 - return non-zero on all exceptions in oo-admin-move
  (agrimm@redhat.com)
- Merge pull request #6162 from tiwillia/bz1171815
  (dmcphers+openshiftbot@redhat.com)
- Add fixing orphaned domain environment variables (tiwillia@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.36.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.35.3-1
- Bug 1146941 (dmcphers@redhat.com)
- Bug 1163648 (dmcphers@redhat.com)
- Fixes 1140552 and 1140558 (dmcphers@redhat.com)
- oo-admin-ctl-domain uses underscores in command options (tiwillia@redhat.com)
- Merge pull request #6141 from brenton/BZ1221786
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6140 from tiwillia/restartcarts
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6139 from tiwillia/bz1218049
  (dmcphers+openshiftbot@redhat.com)
- Bug 1221786 - Provide a way for users to set a usage_account_id
  (bleanhar@redhat.com)
- Merge pull request #6137 from tiwillia/bz1145344
  (dmcphers+openshiftbot@redhat.com)
- Add membership manipulation to oo-admin-ctl-domain (tiwillia@redhat.com)
- oo-admin-ctl-app: allow start/stop/restart of application cartridges
  (tiwillia@redhat.com)
- oo-admin-repair should properly handle HA apps with deleted head gears
  (tiwillia@redhat.com)

* Wed May 13 2015 Wesley Hearn <whearn@redhat.com> 1.35.2-1
- Bump version for broker-util/openshift-origin-broker-util.spec
  (whearn@redhat.com)
- Merge pull request #6069 from tiwillia/bz1191238
  (dmcphers+openshiftbot@redhat.com)
- Bug 1216191 - oo-admin-ctl-district: look up district by server if not
  specified (agrimm@redhat.com)
- Added the '--all' option to oo-admin-ctl-cartridge, v2 (bedin@redhat.com)
- Bug 1212614 - Various oo-admin-move issues (agrimm@redhat.com)
- broker-util: allow oo-admin-move to eat a list of gears and add an final
  output in json (mmahut@redhat.com)
- Bug 1191238 Bugzilla Link https://bugzilla.redhat.com/show_bug.cgi?id=1191238
  Allow domain to be specified in oo-admin-ctl-app (tiwillia@redhat.com)

* Wed May 13 2015 Wesley Hearn <whearn@redhat.com> 1.35.1-1
- bump minor version for sprint 62

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.34.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Thu Feb 19 2015 Adam Miller <admiller@redhat.com> 1.33.2-1
- Fixing typos (dmcphers@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.33.1-1
- Merge pull request #6052 from kwoodson/regions
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)
- Add region level reporting to oo-stats (cewong@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.32.3-1
- oo-accept-broker: testrecord DNS w/absolute domain (lmeyer@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Update spec file (jhonce@redhat.com)
- Broker - Add script to plot Broker Stats (jhonce@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)
- Support full DNs in LDAP group members (pep@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.31.2-1
- Merge pull request #5950 from sztsian/bz1162474-keep
  (dmcphers+openshiftbot@redhat.com)
- bz1162474 if app_name different with app.name of uuid, throw out an warning
  (zsun@fedoraproject.org)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- oo-accept-systems: fix errors from PR 5851 (lmeyer@redhat.com)
- oo-accept-systems: improve cartridge integrity checks (lmeyer@redhat.com)

* Thu Oct 02 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- Bug 1145132 - Domain validation fails when adding size due to previously
  removed size (abhgupta@redhat.com)

* Tue Sep 30 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Bug 1146681 - oo-admin-ctl-domain cannot change allowed gear sizes for a
  mixed-case domain (abhgupta@redhat.com)
- Adding checks and repair logic for invalid gear sizes in domains
  (abhgupta@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Multiple bug fixes Bug 1109647 - Loss of alias on SYNOPSIS part for oo-admin-
  ctl-app Bug 1144610 - oo-admin-usage is broken Bug 1130435 - Setting a same
  scale info on a cartridge makes connection hooks being run
  (abhgupta@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- <oo-accept-broker> fix up handling of IFS (jdetiber@redhat.com)
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
- o-a-c-team: typo per bug 1141848 (lmeyer@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Add a hidden, unsupported change_region option to oo-admin-move for non-
  scaled apps (agrimm@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- ctl-cartridge manpage: update for import-profile (lmeyer@redhat.com)
- oo-admin-ctl-cartridge: import-profile command (lmeyer@redhat.com)
- <broker-util> Fix oo-accept-broker when admin-console installed
  (jdetiber@redhat.com)
- Merge pull request #5663 from sztsian/master
  (dmcphers+openshiftbot@redhat.com)
- broker utils: complete normalization of input logins (lmeyer@redhat.com)
- fix bug 1122339 https://bugzilla.redhat.com/show_bug.cgi?id=1122339 add
  detection to make sure node_platform is not nil before casecmp
  (sztsian@gmail.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.28.5-1
- Fix formatting (dmcphers@redhat.com)

* Wed Aug 13 2014 Adam Miller <admiller@redhat.com> 1.28.4-1
- broker oo scripts: enable login normalization (lmeyer@redhat.com)

* Tue Aug 12 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Merge pull request #5704 from derekwaynecarr/bug_1126888
  (dmcphers+openshiftbot@redhat.com)
- ruby_lib_dir was not defined (decarr@redhat.com)

* Mon Aug 11 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Updates to man page for oo-admin-ctl-region (decarr@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Merge pull request #5689 from derekwaynecarr/region_description
  (dmcphers+openshiftbot@redhat.com)
- Add support for description on region object (decarr@redhat.com)
- oo-app-info: don't assume rhcloud.com app domain (lmeyer@redhat.com)
- app_info.rb: fix whitespace (lmeyer@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- oo-accept-systems: Warn about obsolete cartridges (miciah.masters@gmail.com)
- oo-accept-systems: Drop obsolete/downloaded carts (miciah.masters@gmail.com)

* Tue Jul 29 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Add log message when deleting app (decarr@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- oo-accept-systems: Better output in carts check (miciah.masters@gmail.com)
- oo-accept-systems: Fix check_nodes_cartridges (miciah.masters@gmail.com)
- Bug 1118417: Using default district platform when missing
  (abhgupta@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Tue Jul 08 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- fix undefined variable reference (bparees@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Tue Jun 17 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Measuring time for each operation inside oo-admin-chk (abhgupta@redhat.com)
- Bug 1109646: dup was being called on nil (abhgupta@redhat.com)

* Mon Jun 16 2014 Troy Dawson <tdawson@redhat.com> 1.25.2-1
- Merge pull request #5507 from miheer/bug-1007454-oo-admin-ctl-app-status-
  shows-app-and-gear-uuid (dmcphers+openshiftbot@redhat.com)
- oo-admin-ctl-app: show app/gear UUID with status (misalunk@redhat.com)
- Bug 1105843 - added add/remove alias functionality to oo-admin-ctl-app
  (lnader@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- corrected section number (lnader@redhat.com)
- Bug 1094141 - update oo-admin-ctl-user man pages (lnader@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Merge pull request #5325 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5368 from Miciah/specify-key-algorithm-in-nsupdate-
  plugin-del_cmd-and-oo-diagnostics (dmcphers+openshiftbot@redhat.com)
- Add support for multiple platforms to districts
  (daniel.carabas@uhurusoftware.com)
- Bug 1088247 (lnader@redhat.com)
- Add support for more secure key algorithms (calfonso@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Moved srec deletetion to billing plugin (lnader@redhat.com)
- added -clearplanexpirationdate (lnader@redhat.com)
- Annual Online SKU Support (lnader@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.7-1
- Merge pull request #5297 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1088405 - no error message was being given for invalid keys and silently
  failing (lnader@redhat.com)

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.6-1
- Bug 1085297 - fixed error message (lnader@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.5-1
- ctl-team: allow anonymous or encrypted LDAP access (lmeyer@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Give better error message in case of connection failures. i.e. authentication
  failure (lnader@redhat.com)
- Bug 1087593 (lnader@redhat.com)
- changed save to save! and fixed typo (lnader@redhat.com)
- Bug 1085669 and 1085685 (lnader@redhat.com)
- added oo-admin-ctl-team (lnader@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Bug 1086263 - oo-analytics-export will include applications 'owner_id' field
  (rpenta@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5195 from brenton/BZ1085339
  (dmcphers+openshiftbot@redhat.com)
- Cleanup (dmcphers@redhat.com)
- Bug 1085339, Bug 1085365 - cleaning up the remote user auth configs
  (bleanhar@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- ctl-district: add --available and list-available (lmeyer@redhat.com)
- ctl-district: act on many nodes with one invocation (lmeyer@redhat.com)
- Bug 1083663 - Provide better message when upgrade-node is used on a rerun
  (dmcphers@redhat.com)
- Bug 1071272 - oo-admin-repair: Only allow node removal from its district when
  no apps are referencing that node (rpenta@redhat.com)
- Fix indent, oo-admin-ctl-user usage (jliggitt@redhat.com)
- Add global_teams capability (jliggitt@redhat.com)
- Merge pull request #5165 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1084090: Using as_document instead of serializable_hash to add/remove
  keys (abhgupta@redhat.com)
- Bug 1071272 - Fix oo-admin-repair Details:  - Delete unresponsive node(s)
  from the district in the end  - Recover app will satisfy group overrides
  (rpenta@redhat.com)
- Merge pull request #5152 from
  pravisankar/dev/ravi/bugs-1081381-1073342-1008654
  (dmcphers+openshiftbot@redhat.com)
- Bug 1081381 - Validate --gear option in oo-admin-usage (rpenta@redhat.com)
- Adding user create tracking event (dmcphers@redhat.com)
- Merge pull request #5142 from pravisankar/dev/ravi/bug1079293
  (dmcphers+openshiftbot@redhat.com)
- Bug 1079293 - Fix oo-admin-ctl-region add-zone/remove-zone incorrect warning
  message (rpenta@redhat.com)
- removed oo-admin-ctl-team to be done in a separate pull request
  (lnader@redhat.com)
- Bug 1081975 (lnader@redhat.com)
- Removed global flag - using owner_id=nil as indicator for global team
  (lnader@redhat.com)
- Bug 1079115 - fixed error message (lnader@redhat.com)
- Bug 1079117 - Require rubygem-net-ldap (lnader@redhat.com)
- removed ownership from global teams (lnader@redhat.com)
- added oo-admin-ctl-team (lnader@redhat.com)
- Merge pull request #5122 from pravisankar/dev/ravi/fix-clear-pending-ops
  (dmcphers+openshiftbot@redhat.com)
- Fix oo-admin-clear-pending-ops : With '--time 0' option, ignore pending_ops
  or pending_op_groups created_at field and process any pending op or op-groups
  if it exists (rpenta@redhat.com)
- Bug 1079293 - Fix warning msg in oo-admin-ctl-region remove-zone
  (rpenta@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Bug 1081869 - Console needs a oo-admin-console-cache command. Remove the
  --console flag from the oo-admin-broker-cache command. (jforrest@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.6-1
- Bug 1081419 - Move oo-upgrade to /var/log (dmcphers@redhat.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Bug 1079226 - missing open-sshclients and bad IP from facter make oo-admin-
  move fail (jforrest@redhat.com)
- Merge pull request #5031 from
  jwforres/bug_1079276_analytics_needs_tar_installed
  (dmcphers+openshiftbot@redhat.com)
- Bug 1079276 - Broker util scripts rely on tar and which (jforrest@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bug 1078120: The value lookup is being done in the wrong hash
  (abhgupta@redhat.com)
- oo-accept-broker: handle broker conf errors better (lmeyer@redhat.com)
- Update tests to not use any installed gems and use source gems only Add
  environment wrapper for running broker util scripts (jforrest@redhat.com)
- Merge pull request #5009 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1075480: proper message is output after deleting cartridge type
  (abhgupta@redhat.com)
- Bug 1078191: Missed calling the get_available_cartridges method
  (abhgupta@redhat.com)
- Checking and fixing stale sshkeys and env_vars  - using oo-admin-chk and oo-
  admin-repair (abhgupta@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Bug 1077496 - Fix add subaccount in oo-admin-ctl-user (rpenta@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- oo-accept-broker: improve err handling & more (lmeyer@redhat.com)
- Added User pending-op-group/pending-op functionality Added pending op groups
  for user add_ssh_keys/remove_ssh_keys (rpenta@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Merge pull request #4944 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Fix broker extended (dmcphers@redhat.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Stop using direct addressing (dmcphers@redhat.com)
- Bug 1073395: Fixing precedence issue in condition (abhgupta@redhat.com)
- Merge pull request #4840 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Added max_teams capability (lnader@redhat.com)
- Use correct map (dmcphers@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Adding inactive vs active failure tracking (dmcphers@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4876 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Handle empty plans (dmcphers@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- o-a-ctl-district: minor improvements (lmeyer@redhat.com)
- o-a-ctl-region: minor improvements (lmeyer@redhat.com)
- List plan ids with failures on upgrade (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Revert "Multiple fixes for stability" (dmcphers@redhat.com)
- Multiple fixes for stability  - Adding option to prevent rollback in case of
  successful execution of a destructive operation that is not reversible
  (deleting gear or deconfiguring cartridge on the node)  - Checking for the
  existence of the application after obtaining the lock  - Reloading the
  application after acquiring the lock to reflect any changes made by the
  previous operation holding the lock  - Using regular run_jobs code in clear-
  pending-ops script  - Handling DocumentNotFound exception in clear-pending-
  ops script if the application is deleted (abhgupta@redhat.com)
- Team object, team membership (jliggitt@redhat.com)
- Exit if error occurs changing untracked storage (jliggitt@redhat.com)
- Recalc tracked storage (jliggitt@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.20.6-1
- Bug 1065243 - Reload district object after mongo update in oo-admin-repair
  (rpenta@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Bug 1055356 - Man page and help fixes (dmcphers@redhat.com)
- Bug 1065243: fixing invalid mongo query attribute (abhgupta@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Bug 1064650 - oo-admin-ctl-cartridge handles bad input (ccoleman@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Bug 997374 - Fix typo (dmcphers@redhat.com)
- Merge pull request #4719 from pravisankar/dev/ravi/bug1063249
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063249 - Fix end_time in oo-admin-usage (rpenta@redhat.com)
- Merge pull request #4700 from pravisankar/dev/ravi/bug1060339
  (dmcphers+openshiftbot@redhat.com)
- Bug 1060339 - Move blacklisted check for domain/application to the controller
  layer. oo-admin-ctl-domain/oo-admin-ctl-app will use domain/application model
  and will be able to create/update blacklisted name. (rpenta@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Bug 1034554 - Add man page for oo-admin-upgrade (dmcphers@redhat.com)
- Merge pull request #4688 from
  smarterclayton/bug_1059858_expose_requires_to_clients
  (dmcphers+openshiftbot@redhat.com)
- Support changing categorizations (ccoleman@redhat.com)
- Merge pull request #4692 from liggitt/usage_sync_multiplier
  (dmcphers+openshiftbot@redhat.com)
- Compute usage multiplier (jliggitt@redhat.com)
- Bug 1062543 - Fix missing command validation in oo-admin-ctl-region/oo-admin-
  ctl-district (rpenta@redhat.com)
- Bug 1062546 - Fix unset-region in oo-admin-ctl-district (rpenta@redhat.com)
- Merge pull request #4681 from pravisankar/dev/ravi/misc-bugfixes
  (dmcphers+openshiftbot@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Fix error message in case of invalid name for region/zone/district
  (rpenta@redhat.com)
- Minor fixes in oo-admin-ctl-district/oo-admin-ctl-region (rpenta@redhat.com)
- Allow alphanumeric, underscore, hyphen, dot chars for district/region/zone
  name (rpenta@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Added test case for set/unset region (rpenta@redhat.com)
- Add set-region/unset-region options to oo-admin-ctl-distict to allow
  set/unset of region/zone after node addition to district (rpenta@redhat.com)
- Added oo-admin-ctl-region script to manipulate regions/zones
  (rpenta@redhat.com)
- Merge pull request #4664 from
  smarterclayton/make_obsolete_activate_by_default
  (dmcphers+openshiftbot@redhat.com)
- Obsolete should activate if --obsolete passed (ccoleman@redhat.com)
- oo-admin-ctl-cartridge dry-run condition reversed for migrate
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Support --node correctly on oo-admin-ctl-cartridge (ccoleman@redhat.com)
- Bug 1060290: Fix variable reference typo causing an exception
  (ironcladlou@gmail.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Bug 1058181 - Fix query filter in oo-admin-usage (rpenta@redhat.com)
- Make it possible to run oo-admin-* scripts from source (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Updating op state using set_state method (abhgupta@redhat.com)
- oo-admin-repair: Print info related to usage errors for paid users in usage-
  refund.log (rpenta@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Bug 1056178 - Add useful error message during node removal from district
  (rpenta@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Bug 1040113: Handling edge cases in cleaning up downloaded cart map Also,
  fixing a couple of minor issues (abhgupta@redhat.com)
- Bug 1054574 - clear cache when removing cartridge (contact@fabianofranz.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Bug 1054574 - Clear cache on (de)activation Bug 1052829 - Fix example text in
  oo-admin-ctl-cartridge man (ccoleman@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Bug 1049064: The helper methods needed to be defined before their use
  (abhgupta@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Fix for bug 1049064 (abhgupta@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- oo-admin-repair typo fix (rpenta@redhat.com)
- Merge pull request #4429 from pravisankar/dev/ravi/usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair refactor Added repair for usage inconsistencies
  (rpenta@redhat.com)
- Use mongoid 'save\!' instead of 'save' to raise an exception in case of
  failures (rpenta@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- Merge pull request #4415 from pravisankar/dev/ravi/admin-usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-usage: Add a note 'Aggregated usage excludes monthly plan discounts'
  in the end when user plan exists (rpenta@redhat.com)
- Add --quiet, --create, and --logins-file to oo-admin-ctl-user
  (jliggitt@redhat.com)
- oo-admin-usage enhancements: Show aggregated usage data for the given
  timeframe. (rpenta@redhat.com)

