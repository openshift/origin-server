%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/mysql-5.1
%define frameworkdir %{_libexecdir}/stickshift/cartridges/mysql-5.1

Name: cartridge-mysql-5.1
Version: 0.25.3
Release: 1%{?dist}
Summary: Provides embedded mysql support

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
BuildArch: noarch

Obsoletes: rhc-cartridge-mysql-5.1

Requires: stickshift-abstract
Requires: mysql-server
Requires: mysql-devel

%description
Provides mysql cartridge support to OpenShift

%prep
%setup -q

%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git config --global user.email "builder@example.com"
git config --global user.name "Template builder"
git init
git add -f .
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.25.3-1
- bug 808544 (dmcphers@redhat.com)
- Changes to get gearchanger-oddjob selinux and misc other changes to configure
  embedded carts succesfully (kraman@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.25.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.24.8-1
- This was done to allow a cucumber test to continue to work.  The test will be
  fixed in a subsequent commit. Revert "no ports defined now exits 1"
  (rmillner@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.24.7-1
- no ports defined now exits 1 (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.24.6-1
- Relying on being able to send back appropriate output to the broker on a
  failure and we are using return codes inside the script.
  (rmillner@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.24.5-1
- removed test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.24.4-1
- Test commit (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.24.3-1
- test commits (mmcgrath@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Return in a way that broker can manage. (rmillner@redhat.com)
- Fix for bugz 809567 - snapshot and restore for scalable apps - use the dns
  name on the control/haproxy gear. (ramr@redhat.com)
- Fix for bugz 809567 and also for 809554 - snapshot and restore for scalable
  apps. (ramr@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.24.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-mysql-5.1] release [0.24.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.24.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.23.3-1
- Renaming for open-source release

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.23.2-1
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Show inter-gear connection url for scaled applications. (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.23.1-1
- bump spec numbers (dmcphers@redhat.com)
- USER_APP_NAME -> APP_NAME (dmcphers@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add deploy httpd proxy file to work with 'standalone' gears.
  (ramr@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.22.7-1
- Forgot to check in descriptive index.html for standalone mysql  - sync
  removed added files. (ramr@redhat.com)
- Fix bug for standalone mysql need to add proxy config - so that embedding
  phpmyadmin works and runs where php is running. Use -d name=phpmyadmin-3.4 -d
  colocate_with=mysql-5.1 when posting to
  /broker/rest/domains/$domain/applications/$app/cartridges via the REST api.
  (ramr@redhat.com)
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.22.6-1
- Fix to get snapshot working. (ramr@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.22.5-1
- Fixup message to promote using the inter-gear mysql URL for scalable apps.
  (ramr@redhat.com)
- Add remote db control script + bug fixes w/ variable name changes.
  (ramr@redhat.com)
- Checkpoint work to call mysql on gear from haproxy + setup haproxy control
  scripts. (ramr@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add the set-db-connection-info hook to all the frameworks. (ramr@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.22.4-1
- Fix issues stickshift merge missed. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.22.3-1
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Fixes to get connections executing. (ramr@redhat.com)
- Add build requires git. (ramr@redhat.com)
- Send both gear user and dns name in separate variable names.
  (ramr@redhat.com)
- Add support to start mysql on remote gear. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.22.2-1
- Batch variable name chage (rmillner@redhat.com)
- Fix merge issues (kraman@gmail.com)
- Fixed a git merge fragment ended up getting checked in. (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- hard-coding the stickshift-node.conf path (abhgupta@redhat.com)
- changes to paths and variable names for mysql-5.1 cartridge for opensource
  (abhgupta@redhat.com)
- Screen-scraping in unit tests fails - so set it back to the old output.
  (ramr@redhat.com)
- Re-enable both flavors of mysql. (ramr@redhat.com)
- Fix missing end brace. (ramr@redhat.com)
- Temporary fix to get build working. (ramr@redhat.com)
- Checkpoint support for mysql running standalone on gears. (ramr@redhat.com)
- take back username and pw (dmcphers@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.22.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.21.5-1
- do even less when ip doesnt change on move (dmcphers@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.21.4-1
- Missed that we'd transitioned from OPENSHIFT_*_IP to OPENSHIFT_*_HOST.
  (rmillner@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.21.3-1
- Update show-port hook and re-add function. (rmillner@redhat.com)
- Embedded cartridges that expose ports should reap their proxy in removal if
  it hasn't been done already. (rmillner@redhat.com)
- Forgot to include uuid in calls (rmillner@redhat.com)
- Use the libra-proxy configuration rather than variables to spot conflict and
  allocation. Switch to machine readable output. Simplify the proxy calls to
  take one target at a time (what most cartridges do anyway). Use cartridge
  specific variables. (rmillner@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.21.2-1
- Proxy port hooks for mysql (rmillner@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.21.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.20.3-1
- cleaning up specs to force a build (dmcphers@redhat.com)
- change default mysql charset to utf-8 (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.20.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- cucumber test fix embedded.feature : mysql cartridge manifest had default
  profile misfiring (rchopra@redhat.com)
- only change admin user on post-move (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)
- Cleanup usage message to include status. (ramr@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.20.1-1
- bump spec numbers (dmcphers@redhat.com)
