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
Version: 1.21.0
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