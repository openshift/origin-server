%define cartridgedir %{_libexecdir}/stickshift/cartridges/diy-0.1

Summary:   Provides diy support
Name:      cartridge-diy-0.1
Version:   0.25.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-raw-0.1

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires: rubygem(stickshift-node)
Requires:  httpd
BuildArch: noarch

%description
Provides diy support to OpenShift

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
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
ln -s %{cartridgedir}/../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/expose-port %{buildroot}%{cartridgedir}/info/hooks/expose-port
ln -s %{cartridgedir}/../abstract/info/hooks/conceal-port %{buildroot}%{cartridgedir}/info/hooks/conceal-port
ln -s %{cartridgedir}/../abstract/info/hooks/show-port %{buildroot}%{cartridgedir}/info/hooks/show-port
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.25.3-1
- 1) removing cucumber gem dependency from express broker. 2) moved ruby
  related cucumber tests back into express. 3) fixed issue with broker
  Gemfile.lock file where ruby-prof was not specified in the dependency
  section. 4) copying cucumber features into li-test/tests automatically within
  the devenv script. 5) fixing ctl status script that used ps to list running
  processes to specify the user. 6) fixed tidy.sh script to not display error
  on fedora stickshift. (abhgupta@redhat.com)
- bug 811509 (bdecoste@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.25.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.24.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.24.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.23.4-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.23.3-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.23.2-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Rename connector type to gear endpoint info (from ssh). (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.23.1-1
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.22.4-1
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.22.3-1
- Update raw configuration files to have the right styling
  (ccoleman@redhat.com)
- Update cartridge landing page styles (ccoleman@redhat.com)
- Add the set-db-connection-info hook to all the frameworks. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.22.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- removing call to load_node_conf method which is no longer present or required
  (abhgupta@redhat.com)
- Changing how node config is loaded (kraman@gmail.com)
- Updating raw cartridge li/libra => stickshift (kraman@gmail.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Cleaning up diy template. (mpatel@redhat.com)
- Adds disclaimer during configure. (mpatel@redhat.com)
- Rename raw to diy contd. (mpatel@redhat.com)
- Changes to rename raw to diy. (mpatel@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.22.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.21.4-1
- Adds instructions to raw cartridge README. (mpatel@redhat.com)
- fix wrong cased OpenShift (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.21.3-1
- Fixed path to start stop scripts in instructions. (mpatel@redhat.com)
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.21.2-1
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)
- Add proxy hooks from abstract (rmillner@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.21.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.20.3-1
- Bugzilla #790061. (mpatel@redhat.com)
- Add sample/empty directories for minutely,hourly,daily and monthly
  frequencies as well. (ramr@redhat.com)
- Add cron example and directories to all the openshift framework templates.
  (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.20.2-1
- Customizes the 503 page for raw cartridge. (mpatel@redhat.com)
- Adds support for starting raw cartridge applications on creation.
  (mpatel@redhat.com)
- bug 722828 (bdecoste@gmail.com)
- more abstracting out selinux (dmcphers@redhat.com)
- better name consistency (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Adding the 503 page for raw cartridge apps. (mpatel@redhat.com)
- Raw cartridge proxy support. (mpatel@redhat.com)
- Fix wrong link to remove-httpd-proxy (hypens not underscores) and fix
  manifests for Node and Python to allow for nodejs/python app creation.
  (ramr@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- fix build break and cleanup test cases (dmcphers@redhat.com)
- Adding ProxyPass to raw cartridge. (mpatel@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.20.1-1
- bump spec numbers (dmcphers@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.19.2-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- raw-0.1: Modified license to ASL V2 (jhonce@redhat.com)

* Fri Jan 13 2012 Dan McPherson <dmcphers@redhat.com> 0.19.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Jan 11 2012 Dan McPherson <dmcphers@redhat.com> 0.18.5-1
- Gracefully handle threaddump in cartridges that do not support it (BZ772114)
  (aboone@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.18.4-1
- fix build breaks (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.18.3-1
- basic descriptors for all cartridges; added primitive structure for a www-
  dynamic cartridge that will abstract all httpd processes that any cartridges
  need (e.g. php, perl, metrics, rockmongo etc). (rchopra@redhat.com)
