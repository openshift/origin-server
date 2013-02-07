%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-msg-broker-mcollective
%global rubyabi 1.9.1

Summary:        OpenShift plugin for mcollective service
Name:           rubygem-%{gem_name}
Version: 1.5.0
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{gem_name}/rubygem-%{gem_name}-%{version}.tar.gz
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(json)
Requires:       rubygem(openshift-origin-common)
Requires:       mcollective
Requires:       mcollective-client
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python
Requires:       openshift-origin-msg-common
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildArch:      noarch
Obsoletes:      rubygem-gearchanger-mcollective-plugin
Obsoletes:      rubygem-gearchanger-m-collective-plugin

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
%attr(0644,-,-) %ghost /etc/mcollective/client.cfg

%changelog
* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Merge pull request #1324 from tdawson/tdawson/remove_rhel5_spec_stuff
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1328 from rajatchopra/master (dmcphers@redhat.com)
- refix bug907788 - moves across node profiles will not be supported
  (rchopra@redhat.com)
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- Fix _id to uuid issue with districts (dmcphers@redhat.com)
- share db connection logic (dmcphers@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- better error message (dmcphers@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Bug 904100: Tolerate missing Endpoint cart manifest entries
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
