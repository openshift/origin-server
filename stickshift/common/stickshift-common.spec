%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-common
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Common
Name:           rubygem-%{gemname}
Version:        0.8.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(activemodel)
Requires:       rubygem(json)
Requires:       rubygem(mongo)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Common Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the Cloud Development Common packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Common packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.8.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- re-organize parallel job exec code (rchopra@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.7.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Krishna Raman <kraman@gmail.com> 0.6.1-1
- New package for StickShift (was Cloud-Sdk)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.6.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.3-1
- US1908: Allow only vip users to create gears that are larger than medium
  (std) (kraman@gmail.com)
- Adding missing gemfile.lock in stickshift-common gem (kraman@gmail.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.5.2-1
- BugzId# 795829: find_by_uuid no longer requires login name when looking up
  application (kraman@gmail.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.4-1
- Bugfixes in postgres cartridge descriptor Bugfix in connection resolution
  inside profile Adding REST API to retrieve descriptor (kraman@gmail.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- cleaning up specs to force a build (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- cleanup specs (dmcphers@redhat.com)
- fix for finding out whether a component is auto-generated or not
  (rchopra@redhat.com)
- change component/group paths in descriptor (rchopra@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Added group overrides implementation Added colocation on connections
  implementation (rchopra@redhat.com)
- Use cart.requires_feature as dependencies in each component
  (rchopra@redhat.com)
- Changes to re-enable app to be saved/retrieved to/from mongo Various bug
  fixes (kraman@gmail.com)
- Added basic elaboration of components and connections (rchopra@redhat.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- change state machine dep (dmcphers@redhat.com)
- move the rest of the controller tests into broker (dmcphers@redhat.com)
