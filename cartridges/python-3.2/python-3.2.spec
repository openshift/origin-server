%define cartridgedir %{_libexecdir}/stickshift/cartridges/python-2.6

Summary:   Provides python-wsgi-3.2 support
Name:      cartridge-python-3.2
Version:   0.91.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-wsgi-3.2

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires:  rubygem(stickshift-node)
Requires:  mod_bw
Requires:  python
Requires:  mod_wsgi >= 3.2
Requires:  MySQL-python
Requires:  pymongo
Requires:  pymongo-gridfs
Requires:  python-psycopg2
Requires:  python-virtualenv
Requires:  libjpeg
Requires:  libjpeg-devel
Requires:  libcurl
Requires:  libcurl-devel

BuildArch: noarch

%description
Provides wsgi support to OpenShift

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
%dir %{cartridgedir}
%dir %{cartridgedir}/info/
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

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.90.3-1
- Fix for bugz 810366 - custom env var for python cartridge. (ramr@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.90.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.90.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.89.5-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.89.4-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.89.3-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Rename connector type to gear endpoint info (from ssh). (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.89.2-1
- 

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.89.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.88.3-1
- Update cartridge landing page styles (ccoleman@redhat.com)
- Add the set-db-connection-info hook to all the frameworks. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.88.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- loading resource limits config when needed (kraman@gmail.com)
- Changing how node config is loaded (kraman@gmail.com)
- Update WSGI li/libra => stickshift (kraman@gmail.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.88.1-1
- bump spec numbers (dmcphers@redhat.com)
- connectors for scaling perl/nodejs/rack/wsgi (rchopra@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.87.4-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.87.3-1
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.87.2-1
- Add show-proxy call. (rmillner@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.87.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.86.4-1
- Adding expose/conceal port to more cartridges. (rmillner@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.86.3-1
- Add sample/empty directories for minutely,hourly,daily and monthly
  frequencies as well. (ramr@redhat.com)
- Add cron example and directories to all the openshift framework templates.
  (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.86.2-1
- bug 722828 (bdecoste@gmail.com)
- more abstracting out selinux (dmcphers@redhat.com)
- better name consistency (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Fix wrong link to remove-httpd-proxy (hypens not underscores) and fix
  manifests for Node and Python to allow for nodejs/python app creation.
  (ramr@redhat.com)
- removed dependency on www-dynamic (rchopra@redhat.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.86.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 0.85.8-1
- remove old obsoletes (dmcphers@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.85.7-1
- Renaming tests to 2.6 (mmcgrath@redhat.com)
- python2.6 is being used, not 2.4 (mmcgrath@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.85.6-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- wsgi-3.2: Modified license to ASL V2 (jhonce@redhat.com)

* Fri Jan 20 2012 Mike McGrath <mmcgrath@redhat.com> 0.85.5-1
- merge and fix from wsgi (mmcgrath@redhat.com)
- Automatic commit of package [rhc-cartridge-wsgi-3.2] release [0.85.3-1].
  (mmcgrath@redhat.com)

* Fri Jan 20 2012 Mike McGrath <mmcgrath@redhat.com> 0.85.3-1
- Renamed wsgi to python (mmcgrath@redhat.com)

* Wed Jan 18 2012 Dan McPherson <dmcphers@redhat.com> 0.85.2-1
- Fixup minor issue reported on forums - create python eggs cache directory
  with write permissions for the user. (ramr@redhat.com)

* Fri Jan 13 2012 Dan McPherson <dmcphers@redhat.com> 0.85.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Jan 11 2012 Dan McPherson <dmcphers@redhat.com> 0.84.7-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Bugzilla 772753: Add libcurl dependencies to the wsgi cartridge to support
  pycurl. (rmillner@redhat.com)

* Wed Jan 11 2012 Dan McPherson <dmcphers@redhat.com> 0.84.6-1
- Bugzilla 772753: Add libcurl dependencies to the wsgi cartridge to support
  pycurl. (rmillner@redhat.com)
- Gracefully handle threaddump in cartridges that do not support it (BZ772114)
  (aboone@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.84.5-1
- fix build break (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.84.4-1
- basic descriptors for all cartridges; added primitive structure for a www-
  dynamic cartridge that will abstract all httpd processes that any cartridges
  need (e.g. php, perl, metrics, rockmongo etc). (rchopra@redhat.com)
