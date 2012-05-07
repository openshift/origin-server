%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-controller
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Controller
Name:           rubygem-%{gemname}
Version: 0.10.4
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(activemodel)
Requires:       rubygem(highline)
Requires:       rubygem(cucumber)
Requires:       rubygem(json_pure)
Requires:       rubygem(mocha)
Requires:       rubygem(parseconfig)
Requires:       rubygem(state_machine)
Requires:       rubygem(dnsruby)
Requires:       rubygem(stickshift-common)
Requires:       rubygem(open4)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Controller Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the Cloud Development Controller packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Controller packaged as a ruby site library.

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
* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.4-1
- Merge pull request #25 from abhgupta/abhgupta-dev (kraman@gmail.com)
- adding cucumber tests for gear groups rest api (abhgupta@redhat.com)
- additional changes for showing gear states in gear_groups rest api
  (abhgupta@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
- minor fix in domain logging (lnader@redhat.com)
- Merge pull request #23 from kraman/dev/kraman/bug/819443
  (dmcphers@redhat.com)
- Bugfix 819443 (kraman@gmail.com)
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
- adding gear state to gear_groups rest api (abhgupta@redhat.com)
- Merge pull request #18 from kraman/dev/kraman/bug/814444
  (dmcphers@redhat.com)
- Updated embedded cart controller to only return a single message.
  (kraman@gmail.com)
- Adding a seperate message for errors returned by cartridge when trying to add
  them. Fixing CLIENT_RESULT error in node Removing tmp editor file
  (kraman@gmail.com)
- Bug 815554 (lnader@redhat.com)
- Bug 815554 (lnader@redhat.com)
- Bug 815554 (lnader@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- Revert "BugZ 818896. Making app name search case in-sensitive"
  (kraman@gmail.com)
- Merge pull request #17 from kraman/Bug818896 (dmcphers@redhat.com)
- Changing cartridge type attribute to name to remain consistent with rest of
  API (kraman@gmail.com)
- BugZ 818896. Making app name search case in-sensitive (kraman@gmail.com)
- Adding a new REST endpoint for gear group information (kraman@gmail.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)
- Validate ssh key type against the whole string rather than a line
  (dmcphers@redhat.com)
- moving broker auth key and iv encoding/decoding both into the plugin
  (abhgupta@redhat.com)
- changes to cucumber tests to make them work for OpenShift Origin
  (abhgupta@redhat.com)
- potential fix for bug#800188 (rchopra@redhat.com)

* Fri Apr 27 2012 Krishna Raman <kraman@gmail.com> 0.10.2-1
- Fix scalable param in response for GET applications rest api
  (rpenta@redhat.com)
- added tomdoc info for remove_dns (mmcgrath@redhat.com)
- abstracting permissions functions (mmcgrath@redhat.com)
- Merge branch 'php-tests' (mmcgrath@redhat.com)
- additional test breakout (mmcgrath@redhat.com)
- adding new php tests (mmcgrath@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Wed Apr 25 2012 Adam Miller <admiller@redhat.com> 0.9.12-1
- set uid in gear.new constructor; fix for bug#813244 (rchopra@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.9.11-1
- Forgot to end my blocks. (rmillner@redhat.com)
- The hooks are now called on each cartridge on each gear for an app but not
  every cartridge has or should have them.  Was causing an error.
  (rmillner@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.10-1
- fix for bug#810276 - an unhandled exception cannot be expected to have a
  'code' field (rchopra@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.9-1
- cleaning up spec files (dmcphers@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.8-1
- Merge branch 'master' of github.com:openshift/crankcase (lnader@redhat.com)
- Bug 814379 - invalid input being sent back to the client (lnader@redhat.com)
- show/conceal/expose port should not act upon app components
  (rchopra@redhat.com)
- support for group overrides (component colocation really). required for
  transition between scalable/non-scalable apps (rchopra@redhat.com)
- Enhanced cucumber jenkins build test  * rewrote tests to fail if git
  push/jenkins cartridge blocks forever  * added tests to broker tags
  (jhonce@redhat.com)
- move crankcase mongo datastore (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.7-1
- forcing builds (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.5-1
- new package built with tito

