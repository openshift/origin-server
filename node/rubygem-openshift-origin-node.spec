%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-node
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}
%define appdir %{_localstatedir}/lib/openshift
%define apprundir %{_localstatedir}/run/openshift

Summary:        Cloud Development Node
Name:           rubygem-%{gemname}
Version: 1.1.3
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
Requires:       rubygem(openshift-origin-common)
Requires:       rubygem(mocha)
Requires:       rubygem(rspec)
Requires:       rubygem(rcov)
Requires:       python
Requires:       libselinux-python
Requires:       mercurial

%if 0%{?fedora}%{?rhel} <= 6
Requires:       libcgroup
%else
Requires:       libcgroup-tools
%endif
Requires:       pam_openshift
Requires:       quota
Obsoletes: 	    rubygem-stickshift-node

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
#mkdir -p %{buildroot}%{_bindir}/oo
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{appdir}
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
mkdir -p %{buildroot}%{appdir}/.httpd.d
mkdir -p %{buildroot}%{_initddir}
ln -sf %{appdir}/.httpd.d %{buildroot}%{_sysconfdir}/httpd/conf.d/openshift
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
mkdir -p %{buildroot}%{_libexecdir}/openshift/lib

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Move the gem binaries to the standard filesystem location
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rm -rf %{buildroot}%{gemdir}/bin

# Move the gem configs to the standard filesystem location
mv %{buildroot}%{geminstdir}/conf/* %{buildroot}%{_sysconfdir}/openshift

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

#move pam limit binaries to proper location
mv %{buildroot}%{geminstdir}/misc/bin/teardown_pam_fs_limits.sh %{buildroot}%{_libexecdir}/openshift/lib
mv %{buildroot}%{geminstdir}/misc/bin/setup_pam_fs_limits.sh %{buildroot}%{_libexecdir}/openshift/lib

#move the shell binaries into proper location
mv %{buildroot}%{geminstdir}/misc/bin/* %{buildroot}%{_bindir}/

# Create run dir for openshift "services"
%if 0%{?fedora} >= 15
mkdir -p %{buildroot}%{_sysconfdir}/tmpfiles.d
mv %{buildroot}%{geminstdir}/misc/etc/openshift-run.conf %{buildroot}%{_sysconfdir}/tmpfiles.d
%else
mkdir -p %{buildroot}%{apprundir}
%endif

# place an example file
mv %{buildroot}%{geminstdir}/misc/doc/cgconfig.conf %{buildroot}%{_docdir}/%{name}-%{version}/cgconfig.conf

mv httpd/000001_openshift_origin_node.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

#%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}%{_initddir}
cp %{buildroot}%{geminstdir}/misc/init/openshift-cgroups %{buildroot}%{_initddir}/
#%else
#mkdir -p %{buildroot}/etc/systemd/system
#mv %{buildroot}%{geminstdir}/misc/services/openshift-cgroups.service %{buildroot}/etc/systemd/system/openshift-cgroups.service
#%endif

# Don't install or package what's left in the misc directory
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
%{_sysconfdir}/openshift
%{_bindir}/*
%{_libexecdir}/openshift/lib/setup_pam_fs_limits.sh
%{_libexecdir}/openshift/lib/teardown_pam_fs_limits.sh
%config(noreplace) %{_sysconfdir}/openshift/node.conf
%attr(0750,-,-) %{_sysconfdir}/httpd/conf.d/openshift
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000001_openshift_origin_node.conf
%attr(0755,-,-) %{_var}/lib/openshift

#%if 0%{?fedora}%{?rhel} <= 6
%attr(0755,-,0)	%{_initddir}/openshift-cgroups
#%else
#%attr(0750,-,-) /etc/systemd/system
#%endif

%if 0%{?fedora} >= 15
%{_sysconfdir}/tmpfiles.d/openshift-run.conf
%else
# upstart files
%attr(0755,-,-) %{_var}/run/openshift
%endif

# save the example cgconfig.conf
%doc %{_docdir}/%{name}-%{version}

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%post
echo "/usr/bin/oo-trap-user" >> /etc/shells

# copying this file in the post hook so that this file can be replaced by rhc-node
# copy this file only if it doesn't already exist
if ! [ -f /etc/openshift/resource_limits.conf ]; then
  cp -f /etc/openshift/resource_limits.template /etc/openshift/resource_limits.conf
fi

%changelog
* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #857 from jwhonce/dev/bz874712_master
  (openshift+bot@redhat.com)
- Fix for Bug 874712 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #851 from brenton/no_trace (openshift+bot@redhat.com)
- BZ873970, BZ873966 - disabling HTTP TRACE for the Broker, Nodes and Console
  (bleanhar@redhat.com)
- Increase the table sizes to cover 15000 nodes in dev and prod.
  (rmillner@redhat.com)
- BZ872523 - set quota for gear failed if the device name is too long
  (bleanhar@redhat.com)
- Merge pull request #698 from mscherer/fix_doc_node_bin
  (openshift+bot@redhat.com)
- do not use old name in the script help message (mscherer@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)

* Wed Oct 31 2012 Adam Miller <admiller@redhat.com> 1.0.2-1
- Fixes for LiveCD build (kraman@gmail.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.17.14-1
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)

* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.17.13-1
- Add support for ctl_all restart. (ramr@redhat.com)
- fixing file name typo in usage and fixing domain name in test environment
  file (abhgupta@redhat.com)
- changing requires from pam-openshift to pam_openshift (tdawson@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.17.12-1
- Remove sourcing abstract/info/lib/util -- brings in "cruft" and fix up rhcsh.
  (ramr@redhat.com)

* Mon Oct 22 2012 Adam Miller <admiller@redhat.com> 0.17.11-1
- Merge pull request #722 from Miciah/node-require-libselinux-python-2
  (openshift+bot@redhat.com)
- removing remaining cases of SS and config.ss (dmcphers@redhat.com)
- oo-trap-user in node requires libselinux-python (miciah.masters@gmail.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.17.10-1
- Merge pull request #710 from jwhonce/master (dmcphers@redhat.com)
- Fix for Bug 867692 (jhonce@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.17.9-1
- fix typo breaking the build (dmcphers@redhat.com)
- Fixing GECOS in script file (kraman@gmail.com)
- Port auto-Idler to origin-server (jhonce@redhat.com)
- Fixing outstanding cgroups issues Removing hardcoded references to "OpenShift
  guest" and using GEAR_GECOS from node.conf instead (kraman@gmail.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Adding support for quota and pam fs limits (kraman@gmail.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- adding cgroups management to node (mlamouri@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.17.8-1
- Merge pull request #635 from Miciah/etc-plugin-conf12
  (openshift+bot@redhat.com)
- Merge pull request #633 from jwhonce/dev/bz864681 (openshift+bot@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fix for Bug 864681 (jhonce@redhat.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.17.7-1
- fix obsoletes (dmcphers@redhat.com)
- renaming crankcase -> origin-server (dmcphers@redhat.com)
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com>
- fix obsoletes (dmcphers@redhat.com)
- renaming crankcase -> origin-server (dmcphers@redhat.com)
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.17.5-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.17.4-1
- Merge pull request #595 from mrunalp/dev/typeless (dmcphers@redhat.com)
- BZ853582: Prevent user from logging in while deleting gear
  (jhonce@redhat.com)
- Typeless gear changes (mpatel@redhat.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.17.3-1
- fixing test typo and specifying parseconfig gem version to get rid of
  warnings (abhgupta@redhat.com)
- removing Gemfile.locks (dmcphers@redhat.com)

* Thu Sep 20 2012 Adam Miller <admiller@redhat.com> 0.17.2-1
- Updating gem versions (admiller@redhat.com)
- New mongodb-2.2 cartridge (rmillner@redhat.com)
- Merge pull request #479 from rmillner/f17proxy (openshift+bot@redhat.com)
- The chkconfig test no longer works on F17 and was no longer needed once port-
  proxy moved to origin-server (rmillner@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.17.1-1
- Updating gem versions (admiller@redhat.com)
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.16.9-1
- Updating gem versions (admiller@redhat.com)
- Merge pull request #470 from jwhonce/bz855186 (openshift+bot@redhat.com)
- Fix for Bug 855186 (jhonce@redhat.com)

* Tue Sep 11 2012 Troy Dawson <tdawson@redhat.com> 0.16.8-1
- Updating gem versions (tdawson@redhat.com)
- Fix for Bug 853559 (jhonce@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.16.7-1
- Updating gem versions (admiller@redhat.com)
- broker and node Gemfile.lock update (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.16.6-1
- Merge pull request #461 from jwhonce/bz853582 (openshift+bot@redhat.com)
- Merge pull request #460 from ramr/master (openshift+bot@redhat.com)
- Update gem version (dmcphers@redhat.com)
- BZ853852 Adding logging to help determine issue (jhonce@redhat.com)
- One more fix for bugz  852486 - rubygem-openshift-origin-node is running restorecon
  against /var/lib/openshift (ramr@redhat.com)

* Thu Sep 06 2012 Adam Miller <admiller@redhat.com> 0.16.5-1
- Fix for bugz 852216 - zend /sandbox should be root owned if possible.
  (ramr@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.16.4-1
- Updating gem versions (admiller@redhat.com)
- Gemfile.lock updates (admiller@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.16.3-1
- Merge pull request #430 from jwhonce/histfile (openshift+bot@redhat.com)
- Bash environment support (jhonce@redhat.com)

* Thu Aug 23 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- Updating gem versions (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- Updating gem versions (admiller@redhat.com)
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Tue Aug 21 2012 Adam Miller <admiller@redhat.com> 0.15.7-1
- Updating gem versions (admiller@redhat.com)
- Merge pull request #415 from rajatchopra/master (openshift+bot@redhat.com)
- fix for Bug 849035 - env vars should be removed for app when db cartridge is
  removed (rchopra@redhat.com)
- Update comments to match code (jhonce@redhat.com)
- Revert "Attempt to stop processes with TERM then KILL" (jhonce@redhat.com)
- Attempt to stop processes with TERM then KILL (jhonce@redhat.com)

* Mon Aug 20 2012 Adam Miller <admiller@redhat.com> 0.15.6-1
- Updating gem versions (admiller@redhat.com)
- BZ 848639: The force kill was leaving SystemV IPC entities around, eventually
  clogging the exec nodes. (rmillner@redhat.com)
- BZ 849058: Add Postgresql to the list of cartridges which exist in both the
  top level and embedded level. (rmillner@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.15.5-1
- Updating gem versions (admiller@redhat.com)
- Merge pull request #380 from abhgupta/abhgupta-dev (openshift+bot@redhat.com)
- adding rest api to fetch and update quota on gear group (abhgupta@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.15.4-1
- Updating gem versions (admiller@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.15.3-1
- Updating gem versions (admiller@redhat.com)
- Merge pull request #357 from brenton/gemspec_fixes1
  (openshift+bot@redhat.com)
- gemspec refactorings based on Fedora packaging feedback (bleanhar@redhat.com)
- It was observed while creating and deleting a lot of applications at the same
  time that sometimes the httpd process gets started back up.
  (rmillner@redhat.com)

* Thu Aug 09 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- Updating gem versions (admiller@redhat.com)
- chmod and shebang fixes for Fedora packaging (bleanhar@redhat.com)
- Create sandbox directory. (rmillner@redhat.com)
- BZ 845332: Separate out configuration file management from the init script so
  that systemd properly interprets the daemon restart. (rmillner@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- Updating gem versions (admiller@redhat.com)
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.14.6-1
- Updating gem versions (dmcphers@redhat.com)
- Merge pull request #291 from mrunalp/bugs/843759 (rmillner@redhat.com)
- Bug 843757 (dmcphers@redhat.com)
- Fix for BZ843759 (mpatel@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.14.5-1
- Updating gem versions (dmcphers@redhat.com)
- bz841157 (bdecoste@gmail.com)
- The initialize_homedir only deals with the contents of the home directory;
  move the unobfuscated function up to create where it belongs so it can be
  unit tested properly.  Using an iterator across the directory contents rather
  than extracting the whole dir as an array is more efficient on nodes with
  thousands of gears. (rmillner@redhat.com)
- US2439: Add support for getting/setting quota. (mpatel@madagascar.(none))

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- Updating gem versions (admiller@redhat.com)
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift-origin-port-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Fri Jul 20 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Updating gem versions (admiller@redhat.com)
- fix for bug#841407 (rchopra@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- Updating gem versions (admiller@redhat.com)
- bz 831062 (bdecoste@gmail.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- Updating gem versions (admiller@redhat.com)
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.13.6-1
- Updating gem versions (admiller@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.5-1
- Updating gem versions (admiller@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Updating gem versions (admiller@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
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
- Merge branch 'master' of github.com:openshift/origin-server (mmcgrath@redhat.com)
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
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
- Merge branch 'master' into US2109 (rmillner@redhat.com)
- clean up comments etc (jhonce@redhat.com)
- Automatic commit of package [rubygem-openshift-origin-node] release [0.11.2-1].
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
- Add rcov testing to openshift-origin-node via "rake rcov". (rmillner@redhat.com)
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
- pass the two uuid fields through to OpenShift::ApplicationContainer
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
