%define cartdir %{_libexecdir}/stickshift/cartridges

Summary:   StickShift common cartridge components
Name:      stickshift-abstract
Version:   0.9.3
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   stickshift-abstract-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch: noarch
Requires: git

%description
This contains the common function used while building cartridges.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartdir}
cp -rv abstract %{buildroot}%{cartdir}/
cp -rv abstract-httpd %{buildroot}%{cartdir}/
cp -rv LICENSE %{buildroot}%{cartdir}/abstract
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract
cp -rv LICENSE %{buildroot}%{cartdir}/abstract-httpd
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract-httpd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract-httpd/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/bin/
#%{_libexecdir}/stickshift/cartridges/abstract-httpd/info
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/bin/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/lib/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/connection-hooks/
%{_libexecdir}/stickshift/cartridges/abstract/info
%doc %{_libexecdir}/stickshift/cartridges/abstract/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract/LICENSE
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/LICENSE


%post

%changelog
* Wed Apr 18 2012 Adam Miller <admiller@redhat.com> 0.9.3-1
- 1) removing cucumber gem dependency from express broker. 2) moved ruby
  related cucumber tests back into express. 3) fixed issue with broker
  Gemfile.lock file where ruby-prof was not specified in the dependency
  section. 4) copying cucumber features into li-test/tests automatically within
  the devenv script. 5) fixing ctl status script that used ps to list running
  processes to specify the user. 6) fixed tidy.sh script to not display error
  on fedora stickshift. (abhgupta@redhat.com)
- Fixes to run tests on OSS code (kraman@gmail.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.9.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.11-1
- This was done to allow a cucumber test to continue to work.  The test will be
  fixed in a subsequent commit. Revert "no ports defined now exits 1"
  (rmillner@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.8.10-1
- no ports defined now exits 1 (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.8.9-1
- Fix for #811347. CURL command format error (kraman@gmail.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.8.8-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Relying on being able to send back appropriate output to the broker on a
  failure and we are using return codes inside the script.
  (rmillner@redhat.com)
- Use a return rather than an exit so the calling script can clean up output
  for broker. (rmillner@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Bug fix to expand directory at run-time + add function to save custom
  uservars. (ramr@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.7-1
- removed test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.6-1
- Test commit (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.5-1
- 

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.4-1
- test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Adam Miller <admiller@redhat.com> 0.8.3-1
- Return in a way that broker can manage. (rmillner@redhat.com)

* Mon Apr 09 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.2-1
- Add LICENSE and COPYRIGHT files to stickshift-abstract Add LICENSE and
  COPYRIGHT files to stickshift-broker (jhonce@redhat.com)
- Removing incorrect license info. (kraman@gmail.com)
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Updates to kickstart files and se-linux policies set in the spec files
  (kraman@gmail.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.8.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- Fix path to directory. (mpatel@redhat.com)
- Fix bugs to sync newly added gears and reload haproxy. (ramr@redhat.com)
- Array handling fix for sync gear script. (mpatel@redhat.com)
- No longer needed this variable (rmillner@redhat.com)
- sync gear fixes. (mpatel@redhat.com)
- Add code to read from gear registry. (mpatel@redhat.com)
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rmillner@redhat.com)
- Set +x perms on sync_gears (rmillner@redhat.com)
- Add sync_gears script to abstract and make available in server cartridges
  (rmillner@redhat.com)
- Bug fixes - pass parameters to basic book and setup correct perms.
  (ramr@redhat.com)
- Bug fix - pass parameters to setup basic hook. (ramr@redhat.com)
- Checkpoint work to allow haproxy to run standalone on a gear.
  (ramr@redhat.com)
- Renamed publish-ssh-endpoint to publish-gear-endpoint. (ramr@redhat.com)
- Print gear name in addition to the ssh information - format is the same as a
  scp remote directory path. (ramr@redhat.com)
- Work for publishing ssh endpoint information from all cartridges as well as
  cleanup the multiple copies of publish http and git (now ssh) information.
  (ramr@redhat.com)
- use -h instead of -d (dmcphers@redhat.com)
- fix update_namespace to use CREATE_APP_SYMLINKS (dmcphers@redhat.com)
- keep around OPENSHIFT_APP_DNS (dmcphers@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.7.1-1
- bump spec numbers (dmcphers@redhat.com)
- USER_APP_NAME -> APP_NAME (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.6.9-1
- Character swap in a function name. (rmillner@redhat.com)
- The legacy APP env files were fine for bash but we have a number of parsers
  which could not handle the new format.  Move legacy variables to the app_ctl
  scripts and have migration set the TRANSLATE_GEAR_VARS variable to include
  pairs of variables to migrate. (rmillner@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.6.8-1
- Rename libra-proxy to stickshift-proxy (rmillner@redhat.com)
- dont set status multiple times (dmcphers@redhat.com)

* Tue Mar 13 2012 Dan McPherson <dmcphers@redhat.com> 0.6.7-1
- changing libra to stickshift in logger tag (abhgupta@redhat.com)

* Mon Mar 12 2012 Dan McPherson <dmcphers@redhat.com> 0.6.6-1
- cart_dir is now cartridge_base_path (rchopra@redhat.com)

* Sat Mar 10 2012 Dan McPherson <dmcphers@redhat.com> 0.6.5-1
- Fix issues stickshift merge missed. (ramr@redhat.com)
- Fixes to get ss-connector-execute working after 'ss' merge. (ramr@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.6.4-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Krishna Raman <kraman@gmail.com> 0.6.1-1
- New package for StickShift (was Cloud-Sdk)

* Thu Mar 08 2012 Krishna Raman <kraman@gmail.com> 0.6.1-1
- Creating StickShift abstract package

