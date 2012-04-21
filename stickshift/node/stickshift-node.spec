%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-node
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Node
Name:           rubygem-%{gemname}
Version:        0.9.2
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(json)
Requires:       rubygem(parseconfig)
Requires:       rubygem(stickshift-common)
Requires:       rubygem(mocha)
Requires:       rubygem(rspec)
Requires:       python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Node Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the Cloud Development Node packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Node packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}/ss
mkdir -p %{buildroot}%{_sysconfdir}/stickshift
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{_bindir}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Move the gem binaries to the standard filesystem location
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rm -rf %{buildroot}%{gemdir}/bin

# Move the gem configs to the standard filesystem location
mv %{buildroot}%{geminstdir}/conf/* %{buildroot}%{_sysconfdir}/stickshift

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

#move the shell binaries into proper location
mv %{buildroot}%{geminstdir}/misc/bin/* %{buildroot}%{_bindir}/
rm -rf %{buildroot}%{geminstdir}/misc

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
%{_sysconfdir}/stickshift
%{_bindir}/*

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%post
echo "/usr/bin/ss-trap-user" >> /etc/shells

# copying this file in the post hook so that this file can be replaced by rhc-node
# copy this file only if it doesn't already exist
if ! [ -f /etc/stickshift/resource_limits.conf ]; then
  cp -f /etc/stickshift/resource_limits.template /etc/stickshift/resource_limits.conf
fi

%changelog
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.9.2-1
- Updating gem versions (mmcgrath@redhat.com)
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 09 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.2-1
- Updating gem versions (mmcgrath@redhat.com)
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- 1) changes to fix remote job creation to work for express as well as
  stickshift.  2) adding resource_limits.conf file to stickshift node.  3)
  adding implementations of generating remote job objects in mcollective
  application container proxy (abhgupta@redhat.com)
- fixing ss-trap-user to run in correct selinux context (kraman@gmail.com)
- Fixing cartridge-info executable used by OSS code (kraman@gmail.com)
- Adding m-collective and oddjob gearchanger plugins (kraman@gmail.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.8.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Wed Mar 28 2012 Dan McPherson <dmcphers@redhat.com> 0.7.4-1
- Updating gem versions (dmcphers@redhat.com)
- merge with master (lnader@redhat.com)

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.7.3-1
- Updating gem versions (dmcphers@redhat.com)
- Fix for bugz 807376 - haproxy shows up twice in embedded cartridge list.
  (ramr@redhat.com)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- Updating gem versions (dmcphers@redhat.com)
- fixup help message (dmcphers@redhat.com)
- keep around OPENSHIFT_APP_DNS (dmcphers@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.7.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- USER_APP_NAME -> APP_NAME (dmcphers@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.10-1
- Updating gem versions (dmcphers@redhat.com)
- Minor rename for BZ 802605 (rmillner@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.9-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- minor fix in ss-authorized-ssh-key-remove (rpenta@redhat.com)
- Merge branch 'master' of git1.ops.rhcloud.com:/srv/git/li (rpenta@redhat.com)
- Fix for bug# 800095 (rpenta@redhat.com)

* Tue Mar 13 2012 Dan McPherson <dmcphers@redhat.com> 0.6.8-1
- Updating gem versions (dmcphers@redhat.com)
- Since libra.rb sources the configuration, PUBLIC_IP and PUBLIC_HOSTNAME are
  no longer optional.  But in order for the dev/build/test environment to work
  we still need a way to override them.  Separate out the usage of
  PUBLIC_IP_OVERRIDE and PUBLIC_HOSTNAME_OVERRIDE from PUBLIC_IP and
  PUBLIC_HOSTNAME so that OVERRIDE is optional and can be used from devenv.
  (rmillner@redhat.com)
- moving li/stickshift/node/lib/stickshift-node/express to li/node/lib
  (abhgupta@redhat.com)
- Change remaining references from /usr/libexec/li to /usr/libexec/stickshift
  (rmillner@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.6.7-1
- Updating gem versions (dmcphers@redhat.com)
- fixing bug 802425 and bug 802473 (abhgupta@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.6.6-1
- Updating gem versions (dmcphers@redhat.com)
- Fixes to get ss-connector-execute working after 'ss' merge. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.5-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)
- Updating gem versions (dmcphers@redhat.com)

* Fri Mar 09 2012 Krishna Raman <kraman@gmail.com> 0.6.1-1
- New package for StickShift (was Cloud-Sdk)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.6.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.6-1
- Updating gem versions (dmcphers@redhat.com)
- bumping spec version (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.5.4-1
- Updating gem versions (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.5.3-1
- Updating gem versions (dmcphers@redhat.com)
- Adds code to remove last access file when an app is destroyed.
  (mpatel@redhat.com)
- shellescape on ss side too (rchopra@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)
- run connectors as non-root (rchopra@redhat.com)
- include open4 for ss-connector-execute, fix in php publish_http_url
  connector.. we dont need the external port for proxying web interfaces
  (rchopra@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- REST call to create a scalable app; fix in ss-connector-execute; fix in
  app.scaleup function (rchopra@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.5.2-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- checkpoint 4 - horizontal scaling bug fixes, multiple gears ok, scaling to be
  tested (rchopra@redhat.com)
- Merge branch 'TA1550' (jhonce@redhat.com)
- initial load of ss-populate-repo (jhonce@redhat.com)
- merging changes (abhgupta@redhat.com)
- initial checkin for US1900 (abhgupta@redhat.com)
- checkpoint 2 - option to create scalable type of app, scaleup/scaledown apis
  added, group minimum requirements get fulfilled (rchopra@redhat.com)
- checkpoint 1 - horizontal scaling broker support (rchopra@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- Updating gem versions (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.4.5-1
- Updating gem versions (dmcphers@redhat.com)
- cleaning up version reqs (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.4-1
- Updating gem versions (dmcphers@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Port proxy API
  calls." (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Make proxy remove
  clean up a port regardless of whether it was defined." (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Only remove ports
  which the user is allowed to use." (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Add proxy
  reconfiguration calls" (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Add ss commands
  for proxy ports." (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Fix minor syntax
  errors." (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Wrong kind of
  quotes" (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Needed end of
  line" (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "Needed to convert
  port number to integer" (rmillner@redhat.com)
- Rolling back my changes to expose targetted proxy. Revert "For compat with
  abstract cartridge, prefix variables with OPENSHIFT" (rmillner@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- Updating gem versions (dmcphers@redhat.com)
- cleaning up specs to force a build (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- Updating gem versions (dmcphers@redhat.com)
- cleanup specs (dmcphers@redhat.com)
- get move working again and add quota support (dmcphers@redhat.com)
- For compat with abstract cartridge, prefix variables with OPENSHIFT
  (rmillner@redhat.com)
- Needed to convert port number to integer (rmillner@redhat.com)
- Needed end of line (rmillner@redhat.com)
- Wrong kind of quotes (rmillner@redhat.com)
- Fix minor syntax errors. (rmillner@redhat.com)
- Add ss commands for proxy ports. Use exceptions rather than bad exit codes.
  (rmillner@redhat.com)
- Add proxy reconfiguration calls (rmillner@redhat.com)
- Only remove ports which the user is allowed to use. (rmillner@redhat.com)
- Make proxy remove clean up a port regardless of whether it was defined.
  (rmillner@redhat.com)
- Port proxy API calls. (rmillner@redhat.com)
- Fixed env var delete on node Added logic to save app after critical steps on
  node suring create/destroy/configure/deconfigure Handle failures on
  start/stop of application or cartridge (kraman@gmail.com)
- fix node test cases (dmcphers@redhat.com)
- Fixes for re-enabling cli tools. git url is not yet working.
  (kraman@gmail.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- change state machine dep (dmcphers@redhat.com)
- move the rest of the controller tests into broker (dmcphers@redhat.com)
