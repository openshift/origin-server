%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-node
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%define appdir %{_localstatedir}/lib/stickshift

Summary:        Cloud Development Node
Name:           rubygem-%{gemname}
Version: 0.13.6
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
Requires:       rubygem(rcov)
Requires:       python
Requires:       mercurial

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
#mkdir -p %{buildroot}%{_bindir}/ss
mkdir -p %{buildroot}%{_sysconfdir}/stickshift
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{appdir}
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
mkdir -p %{buildroot}%{appdir}/.httpd.d
ln -sf %{appdir}/.httpd.d %{buildroot}%{_sysconfdir}/httpd/conf.d/stickshift

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
mv httpd/000001_stickshift_node.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

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
%attr(0750,-,-) %{_sysconfdir}/httpd/conf.d/stickshift
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000001_stickshift_node.conf
%attr(0755,-,-) %{_var}/lib/stickshift

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%post
echo "/usr/bin/ss-trap-user" >> /etc/shells
restorecon -r %{_var}/lib/stickshift

# copying this file in the post hook so that this file can be replaced by rhc-node
# copy this file only if it doesn't already exist
if ! [ -f /etc/stickshift/resource_limits.conf ]; then
  cp -f /etc/stickshift/resource_limits.template /etc/stickshift/resource_limits.conf
fi

%changelog
* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.13.6-1
- Updating gem versions (admiller@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.5-1
- Updating gem versions (admiller@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Updating gem versions (admiller@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Updating gem versions (admiller@redhat.com)
- Revert "Updating gem versions" (dmcphers@redhat.com)
- Updating gem versions (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Updating gem versions (admiller@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- Updating gem versions (admiller@redhat.com)
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 19 2012 Adam Miller <admiller@redhat.com> 0.12.7-1
- Updating gem versions (admiller@redhat.com)
- bug 800188 (dmcphers@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.12.6-1
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (mmcgrath@redhat.com)
- pull in mercurial as a dep (mmcgrath@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- Updating gem versions (admiller@redhat.com)
- Strip out the unnecessary gems from rcov reports and focus it on just the
  OpenShift code. (rmillner@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- Updating gem versions (admiller@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- Updating gem versions (admiller@redhat.com)
- Updated gem info for rails 3.0.13 (admiller@redhat.com)

* Mon Jun 04 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- Updating gem versions (admiller@redhat.com)
- fixes to cucumber tests to run under OpenShift Origin (abhgupta@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- Updating gem versions (admiller@redhat.com)
- bumping spec versions (admiller@redhat.com)

* Wed May 30 2012 Adam Miller <admiller@redhat.com> 0.11.11-1
- Updating gem versions (admiller@redhat.com)
- Set debugging output to false (jhonce@redhat.com)
- Rename ~/app to ~/app-root to avoid application name conflicts and additional
  links and fixes around testing US2109. (jhonce@redhat.com)

* Tue May 29 2012 Adam Miller <admiller@redhat.com> 0.11.10-1
- Updating gem versions (admiller@redhat.com)
-     re-introduce ~/data in typeless gears (jhonce@redhat.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.11.9-1
- Updating gem versions (admiller@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.8-1
- Updating gem versions (admiller@redhat.com)
- Bug 824662 (dmcphers@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.11.7-1
- Updating gem versions (admiller@redhat.com)
- Fix up unix_user unit test. (ramr@redhat.com)
- Fixup unit test parameters to match up call sign. (ramr@redhat.com)
- Revert "Broke the build, the tests have not been update to reflect this
  changeset." (ramr@redhat.com)
- Broke the build, the tests have not been update to reflect this changeset.
  (admiller@redhat.com)

* Wed May 23 2012 Adam Miller <admiller@redhat.com> 0.11.6-1
- Updating gem versions (admiller@redhat.com)
- [mpatel+ramr] Fix issues where app_name is not the same as gear_name - fixup
  for typeless gears. (ramr@redhat.com)

* Wed May 23 2012 Dan McPherson <dmcphers@redhat.com> 0.11.5-1
- Updating gem versions (dmcphers@redhat.com)
- .state file in new location (jhonce@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.11.4-1
- Updating gem versions (dmcphers@redhat.com)
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- clean up comments etc (jhonce@redhat.com)
- Automatic commit of package [rubygem-stickshift-node] release [0.11.2-1].
  (admiller@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Updating gem versions (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Bug fixes to get tests running - mysql and python fixes, delete user dirs
  otherwise rhc-accept-node fails and tests fail. (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Don't create gear dir (symlink for short term to the 'framework') and don't
  set the gear ctl script in unix user. (ramr@redhat.com)
- Change to use cartridge instance dir in lieu of app_dir and correct use of
  app and $gear-name directories. (ramr@redhat.com)
- Updated code to meet coding standards (jhonce@redhat.com)
- Updated documentation after refactor. Corrected merge (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Breakout HTTP configuration/proxy (jhonce@redhat.com)
- Refactor unix_user model to create gear TA1975 (jhonce@redhat.com)

* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Updating gem versions (admiller@redhat.com)
- Remove mongodb duplicate entry. (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Updating gem versions (admiller@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- Updating gem versions (admiller@redhat.com)
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.4-1
- Updating gem versions (admiller@redhat.com)
- Merge pull request #24 from rmillner/master (dmcphers@redhat.com)
- Merge pull request #25 from abhgupta/abhgupta-dev (kraman@gmail.com)
- additional changes for showing gear states in gear_groups rest api
  (abhgupta@redhat.com)
- Add rcov testing to stickshift-node via "rake rcov". (rmillner@redhat.com)
- adding gear state to gear_groups rest api (abhgupta@redhat.com)
- Merge pull request #18 from kraman/dev/kraman/bug/814444
  (dmcphers@redhat.com)
- Adding a seperate message for errors returned by cartridge when trying to add
  them. Fixing CLIENT_RESULT error in node Removing tmp editor file
  (kraman@gmail.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- Updating gem versions (admiller@redhat.com)
- Fix to use Open4 -- merge from previous checkin changed it to Open5.
  (ramr@redhat.com)
- fixing merge conflicts wrt code cleanup (mmcgrath@redhat.com)
- Moved logic up from scripts to library. (mpatel@redhat.com)
- Merge pull request #9 from drnic/add_env_var (dan.mcpherson@gmail.com)
- exit status of connectors should be passed along properly
  (rchopra@redhat.com)
- pass the two uuid fields through to StickShift::ApplicationContainer
  (drnicwilliams@gmail.com)
- corrected syntax error (mmcgrath@redhat.com)
- syle changes (mmcgrath@redhat.com)
- better coding syle and comments (mmcgrath@redhat.com)
- removing tabs, they are the devil (mmcgrath@redhat.com)
- more code style cleanup and comments (mmcgrath@redhat.com)
- style cleanup and comments (mmcgrath@redhat.com)
- Added style cleanup, comments (mmcgrath@redhat.com)
- Corrected some ruby style, added comments (mmcgrath@redhat.com)
- Better ruby style and commenting (mmcgrath@redhat.com)
- added better ruby styling (mmcgrath@redhat.com)
- Added better styling and help menu (mmcgrath@redhat.com)
- update gem versions (dmcphers@redhat.com)

* Fri Apr 27 2012 Krishna Raman <kraman@gmail.com> 0.10.2-1
- Updating login prompt script to work with mongo and mysql shell
  (kraman@gmail.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- Updating gem versions (admiller@redhat.com)
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.9.9-1
- Updating gem versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.8-1
- Updating gem versions (admiller@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.7-1
- Updating gem versions (dmcphers@redhat.com)
- cleaning up spec (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.6-1
- Updating gem versions (dmcphers@redhat.com)
- forcing builds (dmcphers@redhat.com)
