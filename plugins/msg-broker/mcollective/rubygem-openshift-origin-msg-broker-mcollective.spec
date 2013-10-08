%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global scl_root /opt/rh/ruby193/root
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-msg-broker-mcollective
%global rubyabi 1.9.1

Summary:       OpenShift plugin for mcollective service
Name:          rubygem-%{gem_name}
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      rubygem(openshift-origin-common)
Requires:      %{?scl:%scl_prefix}mcollective-client
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
Requires:      openshift-origin-msg-common
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch

%description
OpenShift plugin for mcollective based node/gear manager

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Build and install into the rubygem structure
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}

cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-msg-broker-mcollective.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf.example

%if 0%{?rhel} <= 6
sed -i -e "s|\(/etc/mcollective/client.cfg\)|%{scl_root}/\1|" %{buildroot}/etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf.example
%endif

%files
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
/etc/openshift/plugins.d/openshift-origin-msg-broker-mcollective.conf.example

%defattr(-,root,apache,-)
%attr(0644,-,-) %ghost %{?scl:%scl_root}/etc/mcollective/client.cfg

%changelog
* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Added skip_node_ops flag to app/domain/user/district models.
  (rpenta@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- optimize find all district scenarios (dmcphers@redhat.com)
- Creating the app secret token and sending to gear creation requests
  (abhgupta@redhat.com)
- Fix for bug 1007582 and bug 1008517 (abhgupta@redhat.com)
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)
- mcollective plugin changes for ruby193-mcollective (bleanhar@redhat.com)
- Dependency changes for the SCL mcollective package (bleanhar@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Bug 1007085 (dmcphers@redhat.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Merge pull request #3311 from detiber/runtime_card_213
  (dmcphers+openshiftbot@redhat.com)
- <runtime> Card origin_runtime_213: realtime node_utilization checks
  (jdetiber@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Fix broker extended (dmcphers@redhat.com)
- Node fact calls should timeout much faster than the overall mco timeout
  (jforrest@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Added environment variable name limitations  - Limit length to 128 bytes.  -
  Allow letters, digits and underscore but can't begin with digit
  (rpenta@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3398 from detiber/bz994445
  (dmcphers+openshiftbot@redhat.com)
- Added User environment variables support in broker (rpenta@redhat.com)
- Bug 99445 - Better error message for No nodes available (jdetiber@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Merge pull request #3359 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- migration helpers and rest interface for port information of gears
  (rchopra@redhat.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
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

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Merge pull request #3304 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Adding option to specify server list for find_gear (abhgupta@redhat.com)
- Remove add_authorized_ssh_key and remove_authorized_ssh_key which were likely
  replaced by the job based mechanism. (jpazdziora@redhat.com)
- Fixing has_app method in mcollective (abhgupta@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.6-1
- Bug 988255 (lnader@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Bug 917790 - Do not log user credentials in broker development.log
  (rpenta@redhat.com)
- Merge pull request #3140 from Miciah/move_gear-fix-rollback-drop-remove-
  httpd-proxy (dmcphers+openshiftbot@redhat.com)
- move_gear: drop outdated rollback code (miciah.masters@gmail.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into changes_for_membership
  (ccoleman@redhat.com)
- Simplify capabilities to be more model like, and support clean proxying of
  inherited properties (ccoleman@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Merge pull request #3160 from pravisankar/dev/ravi/card78
  (dmcphers+openshiftbot@redhat.com)
- For consistency, rest api response must display 'delete' instead 'destroy'
  for user/domain/app (rpenta@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- fix issues with move code for multiple haproxy cases (rchopra@redhat.com)
- support for sparse cartridges (multiple haproxy) (rchopra@redhat.com)
- Merge pull request #3069 from sosiouxme/admin-console-mcollective
  (dmcphers+openshiftbot@redhat.com)
- <container proxy> adjust naming for getting facts (lmeyer@redhat.com)
- <mcollective> whitespace + typo fixes (lmeyer@redhat.com)
- <mcollective> adding call to retrieve set of facts for admin-console
  (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- mcoll action for getting env vars for a gear (rchopra@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Remove Online specific references: -Remove hard-coded cart name references.
  -Remove login validations from CloudUser model, login validation must be done
  by authentication plugin. -Remove 'medium' gear size references -All 'small'
  gear size references must be from configuration files. -Remove stale
  application_observer.rb and its references -Remove stale 'abstract' cart
  references -Remove duplicate code from rest controllers -Move all
  get_rest_{user,domain,app,cart} methods in RestModelHelper module. -Cleanup
  unnecessary TODO/FIXME comments in broker. (rpenta@redhat.com)
- Fix for bug 977224 (abhgupta@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Merge pull request #2872 from pravisankar/dev/ravi/bug973918
  (dmcphers+openshiftbot@redhat.com)
- Bug 973918 - Do not allow move gear with oo-admin-move without districts.
  (rpenta@redhat.com)
- Various cleanup (dmcphers@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Bug 971199 - Need to pass application object to CartridgeCache.find_cartridge
  method in mcollective_application_container_proxy.rb (rpenta@redhat.com)
- Bug 974533 - Separate response messages from secondary carts
  (jforrest@redhat.com)
- part two of parallelizing node tasks from broker (rchopra@redhat.com)
- parallelization of app events across gears (rchopra@redhat.com)
- workaround for bz969325 (rchopra@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.8-1
- Merge pull request #2675 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- refix bz967706 - stop call for move (rchopra@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- fix for bz967706 (rchopra@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- vendoring of cartridges (rchopra@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- online_runtime_296 - No longer need to move the throttle tag.
  (rmillner@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- Removing externally_reserved_uids_size attribute from districts
  (abhgupta@redhat.com)
- Fixes to cleanup during app operation failures (abhgupta@redhat.com)
- Merge pull request #2499 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 963828 (lnader@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- Rsync the tc limit settings on gear move. (rmillner@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)
- Merge pull request #2412 from pravisankar/dev/ravi/bug961220-misc
  (dmcphers+openshiftbot@redhat.com)
- Bug 961220 - Modify error message to state that node profile cannot be
  changed for *scalable* app gear with oo-admin-move (rpenta@redhat.com)
- fix bz961216 and others related to url based apps (rchopra@redhat.com)
- Merge pull request #2400 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix bz959221 - embedded cartridge map (rchopra@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Bug 958249 : oo-admin-move will allow different node profile for non-scalable
  apps (rpenta@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- fix version mismatch between broker/node for personal carts; some more safety
  for yaml downloads (rchopra@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- nomenclature cleanup and fix for bz958342 (rchopra@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Broker changes for supporting unsubscribe connection event. Details: When one
  of the component is removed from the app and if it has published some content
  to other components located on different gears, we issue unsubscribe event on
  all the subscribing gears to cleanup the published content.
  (rpenta@redhat.com)
- Merge pull request #2282 from rajatchopra/url_story
  (dmcphers+openshiftbot@redhat.com)
- support for external cartridge through urls (rchopra@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- subscriber connection should know who is the publisher (rchopra@redhat.com)
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- add connection type to connector calls (dmcphers@redhat.com)
- Fix for bug 953673  - Fixing gear move within the same district when target
  server is not specified (abhgupta@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Fix Move gear: Based on district changed or not, we should reverse/unreserve
  uid (rpenta@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.4-1
- Merge pull request #2079 from pravisankar/dev/ravi/fix_move_gear
  (dmcphers@redhat.com)
- Fixing issue where app creation failure did not cleanup gears from node
  (abhgupta@redhat.com)
- Move gear within district should ignore its source server (rpenta@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Change 'allow_change_district' to 'change_district' and remove warnings when
  target server or district is specified. Fix start/stop carts order in move
  gear. (rpenta@redhat.com)
- Gear Move changes: Keep same uid for the gear When changing the gear from one
  district to another. (rpenta@redhat.com)
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)
- Adding checks for ssh key matches (abhgupta@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- broker messaging does not require mcollective server (markllama@gmail.com)
- Bug 928752: Run threaddump/system-messages only on primary cart
  (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Merge pull request #1505 from jreuning/bug-916809
  (dmcphers+openshiftbot@redhat.com)
- Prevent exit() call from mcollective on rpc_client connect error, throw
  appropriate exception (john@ibiblio.org)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Add SNI upload support to API (lnader@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Make packages build/install on F19+ (tdawson@redhat.com)
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- remove old obsoletes (tdawson@redhat.com)
- Adding the ability to fetch all gears with broker auth tokens
  (bleanhar@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- Bug 896391 - Move the gear name symlink, not the app name.
  (rmillner@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- Merge pull request #1555 from danmcp/master (dmcphers@redhat.com)
- Bug 917973 Addind a retry and better messaging when you dont get a response
  from the find one (dmcphers@redhat.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Bug 916918 - Couple of issues with frontend calls. (rmillner@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Removing mcollective qpid plugin and adding some more doc
  (dmcphers@redhat.com)
- Use secondary algorithm for find available node as the default
  (dmcphers@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- reverted US2448 (lnader@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- Merge pull request #1477 from ironcladlou/dev/cartridge_refactor
  (dmcphers@redhat.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- US2448 (lnader@redhat.com)
- Add debug timings for external operations (dmcphers@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- fix typo (dmcphers@redhat.com)
- Bug 915478 (dmcphers@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- fix rubygem sources (tdawson@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- stop passing extra app object (dmcphers@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Fixes for ruby193 (john@ibiblio.org)
- Add request id to mco requests (dmcphers@redhat.com)
- correction in node selection algorithm (dmcphers@redhat.com)
- remove community pod (dmcphers@redhat.com)
- minor cleanup (dmcphers@redhat.com)
- Ignore components for methods destined for carts (ironcladlou@gmail.com)
- Refactor agent and proxy, move all v1 code to v1 model
  (ironcladlou@gmail.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Merge pull request #1324 from tdawson/tdawson/remove_rhel5_spec_stuff
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1328 from rajatchopra/master (dmcphers@redhat.com)
- refix bug907788 - moves across node profiles will not be supported
  (rchopra@redhat.com)
- remove BuildRoot:(tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Fix _id to uuid issue with districts (dmcphers@redhat.com)
- share db connection logic (dmcphers@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- better error message (dmcphers@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Bug 904100:Tolerate missing Endpoint cart manifest entries
  (ironcladlou@gmail.com)
- Switch calling convention to match US3143 (rmillner@redhat.com)
- indexed and Bug 894985 (rchopra@redhat.com)
- Bug 894985 (rchopra@redhat.com)
- Bug 893879 (dmcphers@redhat.com)
- Bug 892112 (rchopra@redhat.com)
- district re-alignment for migration (rchopra@redhat.com)
- use uuid for communication with node (rchopra@redhat.com)
- Bug 892124 (rchopra@redhat.com)
- BZ890104 (rchopra@redhat.com)
- move fixes (rchopra@redhat.com)
- admin-ctl-app remove particular gear (rchopra@redhat.com)
- move unqueued (rchopra@redhat.com)
- corrected ref to app.user to app.domain.owner (lnader@redhat.com)
- refactoring to use getter/setter for user capabilities (abhgupta@redhat.com)
- Removing merge conflicts (kraman@gmail.com)
- porting bug fix for 883607 to model refactor branch (abhgupta@redhat.com)
- Fixing php manifest Adding logging statements for debugging scaled apps
  (kraman@gmail.com)
- Added support for thread dump. Fixed default username in mongoid.yml file
  (kraman@gmail.com)
- Various bugfixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- Bug 902690 Cant use direct addressing mode when facts are required
  (dmcphers@redhat.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- set timeout to disc timeout for direct addressing (dmcphers@redhat.com)
- Fix include? (dmcphers@redhat.com)
- Still need to use broadcast for get all gears methods (dmcphers@redhat.com)
- favor different nodes within a gear group (dmcphers@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- added add/remove ssl cert methods to ease merge (mlamouri@redhat.com)
- adding rdoc to mcollective_application_container (mlamouri@redhat.com)
- SSL support for custom domains. (mpatel@redhat.com)
- Merge pull request #1163 from ironcladlou/endpoint-refactor
  (dmcphers@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Thu Jan 17 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- dont return nil resultIO (dmcphers@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.7-1
- fix for bug 883607 (abhgupta@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1035 from abhgupta/abhgupta-dev
  (openshift+bot@redhat.com)
- fix for bugs 883554 and 883752 (abhgupta@redhat.com)

* Fri Dec 07 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Move last_access file with gear (pmorie@gmail.com)
- Use correct alias method during gear post-move (ironcladlou@gmail.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Fix incorrect filter in finding district (rpenta@redhat.com)
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- more mco 2.2 changes (dmcphers@redhat.com)
- repacking for mco 2.2 (dmcphers@redhat.com)
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)
- mco value passing cleanup (dmcphers@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Various mcollective changes getting ready for 2.2 (dmcphers@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- BZ876465  Embedding scalable app (php) with jenkins fails to create a new
  builder (calfonso@redhat.com)
- use a more reasonable large disctimeout (dmcphers@redhat.com)
- Changing same uid move to rsync (dmcphers@redhat.com)
- Merge pull request #957 from rajatchopra/master (openshift+bot@redhat.com)
- Merge pull request #956 from danmcp/master (openshift+bot@redhat.com)
- fix get_all_gears to provide Integer value of uid (rchopra@redhat.com)
- Merge pull request #953 from rajatchopra/master (dmcphers@redhat.com)
- Add method to get the active gears (dmcphers@redhat.com)
- add obsoletes (dmcphers@redhat.com)
- reform the get_all_gears call and add capability to reserve a specific uid
  from a district (rchopra@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Bug 876459 (dmcphers@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #897 from sosiouxme/BZ876271 (openshift+bot@redhat.com)
- fix for bug#876458 (rchopra@redhat.com)
- comment and set correct defaults in openshift-origin-msg-broker-
  mcollective.conf.example (lmeyer@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- add config to gemspec (dmcphers@redhat.com)
- Moving plugins to Rails 3.2.8 engine (kraman@gmail.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
