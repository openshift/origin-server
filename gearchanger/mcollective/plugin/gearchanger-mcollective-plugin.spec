%global gem_name gearchanger-mcollective-plugin

%if 0%{?rhel} <= 6 && 0%{?fedora} <= 16
%{!?ruby_sitelib: %global ruby_sitelibdir %(ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"] ')}

%global gem_dir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gem_instdir %{gem_dir}/gems/%{gem_name}-%{version}
%global gem_docdir %{gem_dir}/doc/%{gem_name}-%{version}
%global gem_cache %{gem_dir}/cache
%global gem_spec %{gem_dir}/specifications

%endif #end rhel <= 6 && fedora <= 16

Summary:        GearChanger plugin for mcollective service
Name:           rubygem-%{gem_name}
Version: 0.3.2
Release:        2%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%if 0%{?rhel} <= 6 && 0%{?fedora} <= 16
Requires:       ruby(abi) = 1.8
%endif
%if 0%{?fedora} >= 17
Requires:       ruby(abi) = 1.9.1
%endif

Requires:       rubygems
Requires:       mcollective
Requires:       mcollective-client
Requires:       qpid-cpp-server
Requires:       qpid-cpp-client
Requires:       ruby-qpid-qmf
Requires:       rubygem(stickshift-common)
Requires:       rubygem(json)
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python

%if 0%{?fedora} >= 17
BuildRequires:  rubygems-devel
%endif

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch

%description
GearChanger plugin for mcollective based node/gear manager

%prep
%setup -q

%build
# Build and install into the rubygem structure
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force %{gem_name}-%{version}.gem

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gem_dir}

cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{_var}/www/stickshift/broker/config/environments/plugin-config
install -m0644 config/gearchanger-mcollective-plugin.rb %{buildroot}%{_var}/www/stickshift/broker/config/environments/plugin-config/gearchanger-mcollective-plugin.rb

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%{_var}/www/stickshift/broker/config/environments/plugin-config/gearchanger-mcollective-plugin.rb

%defattr(-,root,apache,-)
%attr(0644,-,-) %ghost %{_sysconfdir}/mcollective/client.cfg

%changelog
* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.3.2-1
- optimize nolinks (dmcphers@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.2.7-1
- Merge pull request #417 from danmcp/master (openshift+bot@redhat.com)
- more ctl usage test cases and related fixes (dmcphers@redhat.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.2.6-1
- fix for Bug 849035 - env vars should be removed for app when db cartridge is
  removed (rchopra@redhat.com)
- support for removing app local environment variables (rchopra@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.2.5-1
- Merge pull request #380 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- adding rest api to fetch and update quota on gear group (abhgupta@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.2.4-1
- Merge pull request #374 from rajatchopra/US2568 (openshift+bot@redhat.com)
- Merge pull request #375 from mrunalp/dev/US2696 (openshift+bot@redhat.com)
- US2696: Support for mysql/mongo cartridge level move. (mpatel@redhat.com)
- support for app-local ssh key distribution (rchopra@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #357 from brenton/gemspec_fixes1
  (openshift+bot@redhat.com)
-  move cartridge code (rchopra@redhat.com)
- gemspec refactorings based on Fedora packaging feedback (bleanhar@redhat.com)
- Merge pull request #354 from rajatchopra/master (openshift+bot@redhat.com)
- use configure_order for move (rchopra@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.2.2-1
- call move hook in start_order - fix for bug#833543 (rchopra@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- Merge pull request #319 from rajatchopra/master (smitram@gmail.com)
- fix for bug#844912 (rchopra@redhat.com)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.1.5-1
- send mcollective requests to multiple nodes at the same time
  (dmcphers@redhat.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.1.4-1
- Bug 843757 (dmcphers@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- Mongo deleted_gears fix (rpenta@redhat.com)
- Merge pull request #265 from kraman/dev/kraman/bugs/806824
  (dmcphers@redhat.com)
- Stop calling deconfigure on destroy (dmcphers@redhat.com)
- Bug 806824 - [REST API] clients should be able to get informed about reserved
  application names (kraman@gmail.com)
- US2439: Add support for getting/setting quota. (mpatel@madagascar.(none))

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.1.2-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  stickshift-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.0.9-1
- mcollective-plugin pkg doesn't require qpid-cpp-server or mcollective, only
  -client (admiller@redhat.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.0.8-1
- Merge pull request #211 from kraman/dev/kraman/bugs/835489
  (dmcphers@redhat.com)
- Add modify application dns and use where applicable (dmcphers@redhat.com)
- Bugz 835489. Fixing location for district config file and adding in missing
  node_profile_enabled blocks (kraman@gmail.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Bug 838786 (dmcphers@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- cleanup specs (dmcphers@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.5-1
- fix for bug#837579 - handle better messaging on find_available_node failure
  (rchopra@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Fix for BZ 837522. (mpatel@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- fixed a couple typos (admiller@redhat.com)
- Automatic commit of package [rubygem-gearchanger-mcollective-plugin] release
  [0.0.1-1]. (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com>
- fixed a couple typos (admiller@redhat.com)
- Automatic commit of package [rubygem-gearchanger-mcollective-plugin] release
  [0.0.1-1]. (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

