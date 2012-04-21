%define cartridgedir %{_libexecdir}/stickshift/cartridges/php-5.3

Summary:   Provides php-5.3 support
Name:      cartridge-php-5.3
Version:   0.91.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-php-5.3

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires:  rubygem(stickshift-node)
Requires:  php >= 5.3.2
Requires:  php < 5.4.0
Requires:  mod_bw
Requires:  rubygem-builder
Requires:  php-pdo
Requires:  php-gd
Requires:  php-xml
Requires:  php-mysql
Requires:  php-pecl-mongo
Requires:  php-pgsql
Requires:  php-mbstring
Requires:  php-pear
Requires:  php-imap
Requires:  php-pecl-apc
Requires:  php-mcrypt

BuildArch: noarch

%description
Provides php support to OpenShift

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
ln -s %{cartridgedir}/../abstract-httpd/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
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
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.91.3-1
- bug 811509 (bdecoste@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.91.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.90.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-php-5.3] release [0.90.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.90.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.89.4-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.89.3-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.89.2-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Rename connector type to gear endpoint info (from ssh). (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.89.1-1
- bump spec numbers (dmcphers@redhat.com)

* Tue Mar 13 2012 Dan McPherson <dmcphers@redhat.com> 0.88.5-1
- Bugzilla ticket 800558, add php-mcrypt and php-pecl-apc (rmillner@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.88.4-1
- Update cartridge landing page styles (ccoleman@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.88.3-1
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add connector for setting db connection info. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.88.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- loading resource limits config when needed (kraman@gmail.com)
- Changing how node config is loaded (kraman@gmail.com)
- changes to paths and variable names for mysql-5.1 cartridge for opensource
  (abhgupta@redhat.com)
- PHP cart updates li => stickshift libra => stickshift (kraman@gmail.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.88.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.87.5-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.87.4-1
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- fix php publish url to send exposed port (rchopra@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)
- Revert "local commits for testing - required for tito build"
  (abhgupta@redhat.com)
- local commits for testing - required for tito build (abhgupta@redhat.com)
- run connectors as non-root (rchopra@redhat.com)
- include open4 for ss-connector-execute, fix in php publish_http_url
  connector.. we dont need the external port for proxying web interfaces
  (rchopra@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.87.3-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- Add show-proxy call. (rmillner@redhat.com)
- checkpoint 2 - option to create scalable type of app, scaleup/scaledown apis
  added, group minimum requirements get fulfilled (rchopra@redhat.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.87.2-1
- adding publish git and http url hooks (mmcgrath@redhat.com)
- Added connection hooks (mmcgrath@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.87.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.86.4-1
- Add sample/empty directories for minutely,hourly,daily and monthly
  frequencies as well. (ramr@redhat.com)
- Add cron example and directories to all the openshift framework templates.
  (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.86.3-1
- cleaning up specs to force a build (dmcphers@redhat.com)

* Sat Feb 11 2012 Dan McPherson <dmcphers@redhat.com> 0.86.2-1
- bug 722828 (bdecoste@gmail.com)
- more abstracting out selinux (dmcphers@redhat.com)
- better name consistency (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Fix wrong link to remove-httpd-proxy (hypens not underscores) and fix
  manifests for Node and Python to allow for nodejs/python app creation.
  (ramr@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (mmcgrath@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- Adding conceal port (mmcgrath@redhat.com)
