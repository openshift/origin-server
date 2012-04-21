%define cartridgedir %{_libexecdir}/stickshift/cartridges/jenkins-1.4

Summary:   Provides jenkins-1.4 support
Name:      cartridge-jenkins-1.4
Version:   0.91.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-jenkins-1.4

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires: git
Requires:  stickshift-abstract
Requires:  rubygem(stickshift-node)
Requires:  jenkins
Requires:  jenkins-plugin-openshift

BuildArch: noarch

%description
Provides jenkins cartridge to openshift nodes

%prep
%setup -q

%build

%post
service jenkins stop
chkconfig jenkins off

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r template %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0750,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%{cartridgedir}/template/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.91.3-1
- 1) removing cucumber gem dependency from express broker. 2) moved ruby
  related cucumber tests back into express. 3) fixed issue with broker
  Gemfile.lock file where ruby-prof was not specified in the dependency
  section. 4) copying cucumber features into li-test/tests automatically within
  the devenv script. 5) fixing ctl status script that used ps to list running
  processes to specify the user. 6) fixed tidy.sh script to not display error
  on fedora stickshift. (abhgupta@redhat.com)
- The jenkins_reload command had changed.  Update calling parameters.
  (rmillner@redhat.com)
- Changes to get gearchanger-oddjob selinux and misc other changes to configure
  embedded carts succesfully (kraman@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.91.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.90.3-1
- bug 810206 (wdecoste@localhost.localdomain)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.90.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-jenkins-1.4] release [0.90.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.90.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.89.3-1
- Renaming for open-source release

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.89.2-1
- Bug 804892 (dmcphers@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.89.1-1
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.88.6-1
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.88.5-1
- jenkins does-not/need-not contain an expose-port, so dont raise a fatal
  exception if that fails on a scalable app (rchopra@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.88.4-1
- support https only for jenkins use case (dmcphers@redhat.com)
- remove jenkinsUrl from config.xml (dmcphers@redhat.com)
- adding back jenkinsUrl for now (dmcphers@redhat.com)
- Revert "Fixing jenkins deploy proxy" (kraman@gmail.com)
- update jenkins mailer on namespace update (dmcphers@redhat.com)
- Fixing jenkins deploy proxy (kraman@gmail.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.88.3-1
- point to https for changing jenkins password (dmcphers@redhat.com)
- leave http enabled for now (dmcphers@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.88.2-1
- missed a couple of merges (dmcphers@redhat.com)
- force jenkins to https (dmcphers@redhat.com)
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- Fixed jenkins configure script (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- Update jenkins li/libra => stickshift (kraman@gmail.com)
- Renaming Cloud-SDK -> StickShift (kraman@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.88.1-1
- bump spec numbers (dmcphers@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.87.5-1
- ~/.state tracking feature (jhonce@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.87.4-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.87.3-1
- Blanket purge proxy ports on application teardown. (rmillner@redhat.com)
- Bug 796595 (dmcphers@redhat.com)
- Update cartridge configure hooks to load git repo from remote URL Add REST
  API to create application from template Moved application template
  models/controller to stickshift (kraman@gmail.com)

* Mon Feb 20 2012 Dan McPherson <dmcphers@redhat.com> 0.87.2-1
- secure jenkins (dmcphers@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.87.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.86.4-1
- bump the jenkins heap size a little (dmcphers@redhat.com)

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
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
