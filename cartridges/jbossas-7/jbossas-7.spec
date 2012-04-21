%define cartridgedir %{_libexecdir}/stickshift/cartridges/jbossas-7

Summary:   Provides JBossAS7 support
Name:      cartridge-jbossas-7
Version:   0.91.3
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   %{name}-%{version}.tar.gz

Obsoletes: rhc-cartridge-jbossas-7

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildRequires:  git
BuildRequires:  java-devel >= 1:1.6.0
BuildRequires:  jpackage-utils
Requires:  stickshift-abstract
Requires: rubygem(stickshift-node)

# When updating jboss-as7, update the alternatives link below
Requires: jboss-as7 >= 7.1.0.Final
Requires: jboss-as7-modules >= 7.1.0.Final

%if 0%{?rhel}
Requires: maven3
%endif

%if 0%{?fedora}
Requires: maven
%endif

#Requires: apr

Obsoletes: cartridge-jbossas-7.0

BuildArch: noarch

%description
Provides JBossAS7 support to OpenShift

%prep
%setup -q

%build

#mkdir -p template/src/main/webapp/WEB-INF/classes
#pushd template/src/main/java > /dev/null
#/usr/bin/javac *.java -d ../webapp/WEB-INF/classes
#popd

mkdir -p info/data
pushd template/src/main/webapp > /dev/null
/usr/bin/jar -cvf ../../../../info/data/ROOT.war -C . .
popd

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r template %{buildroot}%{cartridgedir}/
cp README %{buildroot}%{cartridgedir}/
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
ln -s %{cartridgedir}/../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

%post
# To modify an alternative you should:
# - remove the previous version if it's no longer valid
# - install the new version with an increased priority
# - set the new version as the default to be safe

%if 0%{?rhel}
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/java/apache-maven-3.0.3 100
alternatives --set maven-3.0 /usr/share/java/apache-maven-3.0.3
%endif

%if 0%{?fedora}
alternatives --remove maven-3.0 /usr/share/java/apache-maven-3.0.3
alternatives --install /etc/alternatives/maven-3.0 maven-3.0 /usr/share/maven 102
alternatives --set maven-3.0 /usr/share/maven
%endif

alternatives --remove jbossas-7.0 /opt/jboss-as-7.0.2.Final
alternatives --install /etc/alternatives/jbossas-7 jbossas-7 /opt/jboss-as-7.1.0.Final 102
alternatives --set jbossas-7 /opt/jboss-as-7.1.0.Final
#
# Temp placeholder to add a postgresql datastore -- keep this until the
# the postgresql module is added to jboss as 7.* upstream.
mkdir -p /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
ln -fs /usr/share/java/postgresql-jdbc3.jar /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main
cp -p %{cartridgedir}/info/configuration/postgresql_module.xml /etc/alternatives/jbossas-7/modules/org/postgresql/jdbc/main/module.xml


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0640,-,-) %{cartridgedir}/info/data/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%{cartridgedir}/template/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%{cartridgedir}/README
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%config(noreplace) %{cartridgedir}/info/configuration/

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.91.3-1
- bug 811509 (bdecoste@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.91.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.90.8-1
- This was done to allow a cucumber test to continue to work.  The test will be
  fixed in a subsequent commit. Revert "no ports defined now exits 1"
  (rmillner@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.90.7-1
- no ports defined now exits 1 (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.90.6-1
- Relying on being able to send back appropriate output to the broker on a
  failure and we are using return codes inside the script.
  (rmillner@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.90.5-1
- removed test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.90.4-1
- Test commit (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.90.3-1
- test commits (mmcgrath@redhat.com)
- Return in a way that broker can manage. (rmillner@redhat.com)
- bug 810349 (wdecoste@localhost.localdomain)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.90.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-jbossas-7] release [0.90.1-1].
  (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.90.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.89.4-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.89.3-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.89.2-1
- US2003 - added external_port (bdecoste@gmail.com)
- US2003 (bdecoste@gmail.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Rename connector type to gear endpoint info (from ssh). (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)
- use resource limits to determine jboss heap size with placeholders for larger
  sizes (dmcphers@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.89.1-1
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.88.6-1
- US2003 (wdecoste@localhost.localdomain)
- Expose the JBOSS cluster port along with the JBOSS port when exposed
  (rmillner@redhat.com)
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)
- US2003 (wdecoste@localhost.localdomain)
- US2003 (bdecoste@gmail.com)
- US2003 (bdecoste@gmail.com)
- US2003 (bdecoste@gmail.com)
- US2003 (bdecoste@gmail.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.88.5-1
- US2003 (wdecoste@localhost.localdomain)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.88.4-1
- Updates to jboss cartridge landing page (ccoleman@redhat.com)
- Update cartridge landing page styles (ccoleman@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Add the set-db-connection-info hook to all the frameworks. (ramr@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.88.3-1
- us2003 (bdecoste@gmail.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.88.2-1
- Batch variable name chage (rmillner@redhat.com)
- Fix merge issues (kraman@gmail.com)
- Adding export control files (kraman@gmail.com)
- Updating tests (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- Fix to jboss spec (kraman@gmail.com)
- Changing how node config is loaded (kraman@gmail.com)
- Update Jboss cartridge libra/li => stickshift (kraman@gmail.com)
- US2003 - JBoss HA (bdecoste@gmail.com)
- US2003 - JBoss HA (bdecoste@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Change memory limits based on new gear size allocation (rmillner@redhat.com)
- fix a couple comments (dmcphers@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)
- US2003 (bdecoste@gmail.com)
- US2003 (bdecoste@gmail.com)
- jboss scaling (rchopra@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.88.1-1
- bump spec numbers (dmcphers@redhat.com)
- fixup jboss index.html (dmcphers@redhat.com)
- changes requested by dblado (mmcgrath@redhat.com)
- combine into 1 sed (dmcphers@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.87.12-1
- remove apr dep from jboss cart (dmcphers@redhat.com)
- Bug 798553 (dmcphers@redhat.com)
- remove old jboss env logic (dmcphers@redhat.com)
- make migrate sed a little more selective (dmcphers@redhat.com)
- add env via sed (bdecoste@gmail.com)
- add env via sed (bdecoste@gmail.com)
- added env (bdecoste@gmail.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.87.11-1
- rework migration of git to not stop/start/redeploy (dmcphers@redhat.com)
- use env.OPENSHIFT (wdecoste@localhost.localdomain)
- updated jboss xslt (wdecoste@localhost.localdomain)
- updated xslt (bdecoste@gmail.com)
- removed jboss remoting, management (bdecoste@gmail.com)
- some cleanup of http -C Include (dmcphers@redhat.com)
- Cleanup the standalone conf/sh to be consistent with 7.1.0.Final version
  (starksm64@gmail.com)
- full jee xslt (bdecoste@gmail.com)
- ~/.state tracking feature (jhonce@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.87.10-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)
- add existence check for standalone.xml before migrating (dmcphers@redhat.com)

* Sun Feb 26 2012 Dan McPherson <dmcphers@redhat.com> 0.87.9-1
- finishing standalone.xml migration (dmcphers@redhat.com)
- remembering old standalone.xml for reference (dmcphers@redhat.com)
- add a force to the client install (dmcphers@redhat.com)
- moved xslt (bdecoste@gmail.com)
- initial jboss migration and sync fixes (dmcphers@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.87.8-1
- 

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.87.7-1
- add back apr (dmcphers@redhat.com)
- remove apr from jboss spec (dmcphers@redhat.com)
- add >= to jboss requires (dmcphers@redhat.com)
- Add jboss modules as a dependency to jboss cartridge. (mpatel@redhat.com)

* Fri Feb 24 2012 Dan McPherson <dmcphers@redhat.com> 0.87.6-1
- add obsoletes of old package (dmcphers@redhat.com)
- Automatic commit of package [rhc-cartridge-jbossas-7] release [0.87.5-1].
  (dmcphers@redhat.com)
- fix spec (dmcphers@redhat.com)
- Automatic commit of package [rhc-cartridge-jbossas-7] release [0.87.4-1].
  (dmcphers@redhat.com)
- renaming jbossas7 (dmcphers@redhat.com)

* Fri Feb 24 2012 Dan McPherson <dmcphers@redhat.com> 0.87.5-1
- fix spec (dmcphers@redhat.com)

* Fri Feb 24 2012 Dan McPherson <dmcphers@redhat.com> 0.87.4-1
- new package built with tito

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.87.2-1
- Add show-proxy call. (rmillner@redhat.com)
- set jboss version back for now (dmcphers@redhat.com)
- update jboss version (dmcphers@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.87.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.86.6-1
- Adding expose/conceal port to more cartridges. (rmillner@redhat.com)

* Wed Feb 15 2012 Dan McPherson <dmcphers@redhat.com> 0.86.5-1
- remove old comment (dmcphers@redhat.com)

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
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- increase std and large gear restrictions (dmcphers@redhat.com)
