%define cartridgedir %{_libexecdir}/stickshift/cartridges/nodejs-0.6

Summary:   Provides Node-0.6 support
Name:      cartridge-nodejs-0.6
Version:   0.6.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-nodejs-0.6

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires:  rubygem(stickshift-node)
Requires:  nodejs >= 0.6
Requires:  nodejs-async
Requires:  nodejs-connect
Requires:  nodejs-express
Requires:  nodejs-mongodb
Requires:  nodejs-mysql
Requires:  nodejs-node-static
Requires:  nodejs-pg

BuildArch: noarch

%description
Provides Node.js support to OpenShift

%prep
%setup -q

%build
rm -rf git_template
cp -r template/ git_template/
cp info/configuration/npm_global_module_list git_template
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
ln -s %{cartridgedir}/../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
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
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.6.3-1
- bug 811509 (bdecoste@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.6.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.5.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-nodejs-0.6] release [0.5.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.5.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.4.4-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.4.2-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Rename connector type to gear endpoint info (from ssh). (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.4.1-1
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.3.5-1
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.3.4-1
- Update cartridge landing page styles (ccoleman@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add the set-db-connection-info hook to all the frameworks. (ramr@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.3.3-1
- Fix for bugz 801989 nodejs scaled app. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.3.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- NodeJS update li/libra => stickshift (kraman@gmail.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Add publication of git url and http proxy info to nodejs. Rename the
  connection hook name in the abstract cartridge. (ramr@redhat.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.3.1-1
- bump spec numbers (dmcphers@redhat.com)
- connectors for scaling perl/nodejs/rack/wsgi (rchopra@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.2.5-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.2.4-1
- nodjs/build.sh: fixed the is_node_module_installed function.  Before it was
  claiming that a module was installed if it was only installed as a
  dependancy, which npm does not claim is fully installed. (tdawson@redhat.com)
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.2.3-1
- Add show-proxy call. (rmillner@redhat.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.2.2-1
- Fixup spec file to use newly built rpms. (ramr@redhat.com)
- Temporary bandaid -- gave up on getting build + sync working ... commenting
  Require lines in the spec file so that build can work. (ramr@redhat.com)
- Fix nodejs installation to use rpms for common node modules. As a result of
  rpms, also changed to link global modules in the home directory so that the
  app is now able to override the common modules with a locally installed
  versions. nodejs-mysql module is pending "enablement" ... due to a nodejs-
  hashish rpm dependency issue (nodejs-mysql depends on nodejs-hashish).
  (ramr@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.2.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.1.8-1
- Adding expose/conceal port to more cartridges. (rmillner@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.1.7-1
- Fix template to keep symlinks as is and ignore set times error.
  (ramr@redhat.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.1.6-1
- Add missing jenkins job and ssl templates. (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.1.5-1
- Add sample/empty directories for minutely,hourly,daily and monthly
  frequencies as well. (ramr@redhat.com)
- Add cron example and directories to all the openshift framework templates.
  (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.1.4-1
- cleaning up specs to force a build (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- Use links in sample server.js rather than a redirect. (ramr@redhat.com)
- Update build script for handling (ignoring) global npm modules and fix bug to
  update the modules from deplist.txt in the correct directory.
  (ramr@redhat.com)
- Better method of installing global npm modules (more generic).
  (ramr@redhat.com)
- Handle signals gracefully in sample app + print log messages w/ timestamps.
  (ramr@redhat.com)
- bug 722828 (bdecoste@gmail.com)
- more abstracting out selinux (dmcphers@redhat.com)
- better name consistency (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Fix wrong link to remove-httpd-proxy (hypens not underscores) and fix
  manifests for Node and Python to allow for nodejs/python app creation.
  (ramr@redhat.com)
