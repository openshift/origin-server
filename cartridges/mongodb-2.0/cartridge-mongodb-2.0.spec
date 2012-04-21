%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/mongodb-2.0

Name: cartridge-mongodb-2.0
Version: 0.18.2
Release: 1%{?dist}
Summary: Embedded mongodb support for OpenShift

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-mongodb-2.0

Requires: stickshift-abstract
Requires: mongodb-server
Requires: mongodb-devel
Requires: libmongodb
Requires: mongodb

%description
Provides rhc mongodb cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.18.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.17.9-1
- This was done to allow a cucumber test to continue to work.  The test will be
  fixed in a subsequent commit. Revert "no ports defined now exits 1"
  (rmillner@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.17.8-1
- no ports defined now exits 1 (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.17.7-1
- Relying on being able to send back appropriate output to the broker on a
  failure and we are using return codes inside the script.
  (rmillner@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.17.6-1
- removed test commits (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.17.5-1
- Test commit (mmcgrath@redhat.com)

* Tue Apr 10 2012 Mike McGrath <mmcgrath@redhat.com> 0.17.4-1
- test commits (mmcgrath@redhat.com)
- Return in a way that broker can manage. (rmillner@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.17.3-1
- 

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.17.2-1
- Renaming for open-source release

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.17.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.16.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- removing call to load_node_conf method which is no longer present or required
  (abhgupta@redhat.com)
- changing libra to stickshift for mongodb (abhgupta@redhat.com)
- take back username and pw (dmcphers@redhat.com)
- Removed new instances of GNU license headers (jhonce@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.16.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 29 2012 Dan McPherson <dmcphers@redhat.com> 0.15.4-1
- do even less when ip doesnt change on move (dmcphers@redhat.com)

* Tue Feb 28 2012 Dan McPherson <dmcphers@redhat.com> 0.15.3-1
- Missed that we'd transitioned from OPENSHIFT_*_IP to OPENSHIFT_*_HOST.
  (rmillner@redhat.com)

* Sat Feb 25 2012 Dan McPherson <dmcphers@redhat.com> 0.15.2-1
- Update show-port hook and re-add function. (rmillner@redhat.com)
- Embedded cartridges that expose ports should reap their proxy in removal if
  it hasn't been done already. (rmillner@redhat.com)
- Forgot to include uuid in calls (rmillner@redhat.com)
- Use the libra-proxy configuration rather than variables to spot conflict and
  allocation. Switch to machine readable output. Simplify the proxy calls to
  take one target at a time (what most cartridges do anyway). Use cartridge
  specific variables. (rmillner@redhat.com)
- Add mongodb proxy port hooks. (rmillner@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.15.1-1
- bump spec numbers (dmcphers@redhat.com)

* Tue Feb 14 2012 Dan McPherson <dmcphers@redhat.com> 0.14.3-1
- Handle normal/running case exit code and cleanup status to be in
  restart/start since it needs to be run with runuser. (ramr@redhat.com)
- More resilient fix for bugz 790183 + some cleanup. (ramr@redhat.com)
- Fix for bugz 790183 - repair mongodb and restart if mongod was not shutdown
  cleanly. (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.14.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)
- Cleanup usage message to include status. (ramr@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.14.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 01 2012 Dan McPherson <dmcphers@redhat.com> 0.13.4-1
- fix postgres move and other selinux move fixes (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 0.13.3-1
- deploy httpd proxy from migration (dmcphers@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.13.2-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- mongodb-2.0: Modified license to ASL V2 (jhonce@redhat.com)

* Fri Jan 13 2012 Dan McPherson <dmcphers@redhat.com> 0.13.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.12.7-1
- fix build breaks (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.12.6-1
- basic descriptors for all cartridges; added primitive structure for a www-
  dynamic cartridge that will abstract all httpd processes that any cartridges
  need (e.g. php, perl, metrics, rockmongo etc). (rchopra@redhat.com)
