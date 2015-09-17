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
Version: 1.36.1
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
* Thu Sep 17 2015 Unknown name 1.36.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.35.4-1
- Fix typos (dmcphers@redhat.com)
- Bug 1234603: spreading gears for an app evenly across zones
  (abhgupta@redhat.com)

* Mon Aug 17 2015 Wesley Hearn <whearn@redhat.com> 1.35.3-1
- Merge pull request #6172 from tiwillia/bz1229300
  (dmcphers+openshiftbot@redhat.com)
- Ensure proper quota is used when moving gears across node profiles
  (tiwillia@redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 1.35.2-1
- Bug 1241660 Ensure ignored servers does not include all servers only after
  filtering (tiwillia@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.35.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)
- Ignore least preferred servers if all servers are least preferred
  (tiwillia@redhat.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 1.34.2-1
- Merge pull request #6116 from mmahut/oo-admin-move
  (dmcphers+openshiftbot@redhat.com)
- broker-util: allow oo-admin-move to eat a list of gears and add an final
  output in json (mmahut@redhat.com)

* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.34.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Tue Apr 07 2015 Wesley Hearn <whearn@redhat.com> 1.33.3-1
- Bug 1174824 - Allow gear moves to rsync by node attributes other than IP
  (agrimm@redhat.com)

* Thu Mar 26 2015 Wesley Hearn <whearn@redhat.com> 1.33.2-1
- Add more comments (dmcphers@redhat.com)
- Be more precise than +1 to avoid edge cases and use a weighted selection
  favoring most available nodes (dmcphers@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump spec to fix tags (admiller@redhat.com)
- Take district less into account when filtering available servers
  (dmcphers@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com>
- Take district less into account when filtering available servers
  (dmcphers@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.32.1-1
- Merge pull request #6050 from codificat/bz1147116-move-fails-if-eth0-has-no-
  ip (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)
- Use EXTERNAL_ETH_DEV to determine the node IP (pep@redhat.com)

* Fri Jan 16 2015 Adam Miller <admiller@redhat.com> 1.31.2-1
- typo: missing white space in mcollective_application_container_proxy.rb
  (mmahut@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Wed Oct 22 2014 Adam Miller <admiller@redhat.com> 1.30.6-1
- Bug 1155478: Failed to add uid back to available_uids after gear move across
  district (abhgupta@redhat.com)

* Wed Oct 22 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- Bug 1150140: Region was not being correctly handled during gear moves
  (abhgupta@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- app container proxy: Add user login to ssh authorized_keys file
  (thunt@redhat.com)
- Fixed bz1111562 (lxia@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- node archive: improve doc, config logic (jolamb@redhat.com)
- broker/node: Add parameter for gear destroy to signal part of gear creation
  (jolamb@redhat.com)

* Wed Sep 24 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Better error messages around no nodes available (dmcphers@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- Multiple bug fixes: Bug 1086061 - Should update the description of clean
  command for oo-admin-ctl-cartridge tool Bug 1109647 - Loss of alias on
  SYNOPSIS part for oo-admin-ctl-app Bug 1065853 - Should prompt warning when
  leaving source code url blank but add branch/tag during app creation Bug
  1143024 - A setting of ZONES_MIN_PER_GEAR_GROUP=2 with two available zones
  will always error as though only one zone is available Bug 1099796 - Should
  refine the error message when removing a nonexistent global team from file
  (abhgupta@redhat.com)

* Wed Sep 10 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Add a hidden, unsupported change_region option to oo-admin-move for non-
  scaled apps (agrimm@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump spec for tag fix (admiller@redhat.com)
- Fixing has_app_cartridge method (abhgupta@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com>
- Fixing has_app_cartridge method (abhgupta@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- Logging error if region is specified but no districted nodes available
  (abhgupta@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Enables user to specify a region when creating an application
  (lnader@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Wed May 21 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Fix typos in rsync commands (daniel.carabas@uhurusoftware.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- Bug 1095351: Selected/Requested district uuid now correctly compared
  (abhgupta@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Bug 1095351: Ensuring that gear moves respect the destination district
  argument  - This bug was a regression caused by a typo in a recent change
  (abhgupta@redhat.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Add support for multiple platforms to districts
  (daniel.carabas@uhurusoftware.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Merge pull request #5289 from pravisankar/dev/ravi/bug1086566
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086566 - Fix move gear: run_in_app_lock() will reload the app object and
  any references to its fields (in this case 'gear') need to be recomputed
  (rpenta@redhat.com)
- Bug 1065047 - changed exception raised to NodeUnavailableException to
  indicate retry advisable (503) (lnader@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Moved pruning of non-districted/non-zone nodes(when districted/zone nodes are
  available) from rpc_find_all_available to select_best_fit_node. Rationale:
  Node selection plugin should have flexibility to choose any candidate node
  from non-districted/districted/non-zone/zone nodes. (rpenta@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.7-1
- Merge pull request #5088 from pravisankar/dev/ravi/bug1070884
  (dmcphers+openshiftbot@redhat.com)
- Bug 1070884 - When web-framework gear is moved, run force-stop in the end
  after all carts are stopped (rpenta@redhat.com)
- Merge pull request #5068 from abhgupta/bug_1073576
  (dmcphers+openshiftbot@redhat.com)
- Bug 1073576: Replacing rpcutil usage with openshift agent  - Also fixing
  indentation with one method (abhgupta@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.6-1
- Bug 1075673: Sending the ref and artifact_url args only when specified
  (abhgupta@redhat.com)
- Merge pull request #5047 from abhgupta/bug_1080022
  (dmcphers+openshiftbot@redhat.com)
- Bug 1080022: calling the interface method to select the destination node
  (abhgupta@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Bug 1070533 - Fix gear's server_identity during move (rpenta@redhat.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bug 1079226 - missing open-sshclients and bad IP from facter make oo-admin-
  move fail (jforrest@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- auto expose ports upon configure, but only for scalable apps
  (rchopra@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Added User pending-op-group/pending-op functionality Added pending op groups
  for user add_ssh_keys/remove_ssh_keys (rpenta@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Stop using direct addressing (dmcphers@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Bug 1070713: Checking to see if dns is initialized before closing
  (abhgupta@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- fix typo (vvitek@redhat.com)
- Better comments (dmcphers@redhat.com)
- Cleaning up comments (dmcphers@redhat.com)
- Fixing up comments (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4767 from pravisankar/dev/ravi/bug1055475
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055475 - Mark require_district = true when zones are required in
  rpc_find_all_available (rpenta@redhat.com)
- cleanup (dmcphers@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Bug 1028919 - Avoid spurious calls to mcollective rpc interface in case of
  parallel op execution (rpenta@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4700 from pravisankar/dev/ravi/bug1060339
  (dmcphers+openshiftbot@redhat.com)
- Bug 1060339 - Move blacklisted check for domain/application to the controller
  layer. oo-admin-ctl-domain/oo-admin-ctl-app will use domain/application model
  and will be able to create/update blacklisted name. (rpenta@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Rename config param REGIONS_REQUIRE_FOR_APP_CREATE to
  ZONES_REQUIRE_FOR_APP_CREATE (rpenta@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4616 from brenton/deployment_dir1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4454 from pravisankar/dev/ravi/card178
  (dmcphers+openshiftbot@redhat.com)
- Use NodeProperties model for server_infos in find_all_available_impl and
  related methods (rpenta@redhat.com)
- Use flexible array of optional parameters for find_available and underlying
  methods (rpenta@redhat.com)
- Get zones count for the current region from cached districts instead of
  querying Region collection (rpenta@redhat.com)
- Removed REGIONS_ENABLED config param and preferred zones fixes
  (rpenta@redhat.com)
- When region/zones present, allocate gears evenly among the available zones.
  (rpenta@redhat.com)
- Distribute gears between the zones evenly (rpenta@redhat.com)
- Add ZONES_MIN_PER_GEAR_GROUP config param and related changes
  (rpenta@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Reuse loaded districts instead of querying mongo again to find Server object
  (rpenta@redhat.com)
- Bug fixes: 1055382, 1055387, 1055433 (rpenta@redhat.com)
- Added oo-admin-ctl-region script to manipulate regions/zones
  (rpenta@redhat.com)
- fix the occluded haproxy gear's frontend upon move when two proxy gears clash
  on a node (rchopra@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Card #185: Adding SSL certs to secondary web_proxy gears
  (abhgupta@redhat.com)
- --with-initial-deployment-dir only applies to gear creation
  (bleanhar@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Preventing multiple web proxies for an app to live on the same node
  (abhgupta@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Bug 1059458 (lnader@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- First pass at avoiding deployment dir create on app moves
  (bleanhar@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Card #185: sending app alias to all web_proxy gears (abhgupta@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Merge pull request #4568 from danmcp/bug1049044
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049044: Creating a single sshkey for each scalable application
  (abhgupta@redhat.com)
- Bug 1055371 (dmcphers@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Merge pull request #4551 from pravisankar/dev/ravi/bug1049626
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049626 - Only allow gear move between districted nodes Rationale:
  districted to non-districted nodes not allowed: gear uids on non-districted
  nodes may not be in the range of uids supported by the district between non-
  districted nodes not allowed:: gear uids are not set in mongo and we can not
  guarantee same uid for both source and destination (rpenta@redhat.com)
- Bug 1055878: calling tidy once per gear instead of per gear per cart
  (abhgupta@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Merge pull request #4531 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1040113: Handling edge cases in cleaning up downloaded cart map Also,
  fixing a couple of minor issues (abhgupta@redhat.com)
- Bug 1049626 - Allow move gear with districts, with-out districts, across
  districted nodes to non-districted nodes and vice versa. (rpenta@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Typo fix: Method name find_available_impl changed to find_all_available_impl
  (rpenta@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4497 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Separating out node selection algorithm (abhgupta@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Bug 1052928 - plugin: make the exception clear in case of a conflicting uuid
  during a move (mmahut@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Use mongoid 'save\!' instead of 'save' to raise an exception in case of
  failures (rpenta@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- Merge pull request #4414 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1046091 (abhgupta@redhat.com)
- Fix for bug 1047957 (abhgupta@redhat.com)
