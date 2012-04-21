%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/jenkins-client-1.4

Name: cartridge-jenkins-client-1.4
Version: 0.25.2
Release: 1%{?dist}
Summary: Embedded jenkins client support for express 
Group: Network/Daemons
License: ASL 2.0
URL: https://engineering.redhat.com/trac/Libra
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-jenkins-client-1.4

Requires:  stickshift-abstract
Requires:  rubygem(stickshift-node)
Requires: mysql-devel
Requires: wget
Requires: java-1.6.0-openjdk
Requires:  rubygems
Requires:  rubygem-json

%description
Provides embedded jenkins client support

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
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.25.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.24.3-1
- bug 811509 (bdecoste@gmail.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.24.2-1
- Merge remote-tracking branch 'origin/dev/kraman/US2048' (kraman@gmail.com)
- Automatic commit of package [rhc-cartridge-jenkins-client-1.4] release
  [0.24.1-1]. (dmcphers@redhat.com)
- bump spec numbers (dmcphers@redhat.com)

* Sat Mar 31 2012 Dan McPherson <dmcphers@redhat.com> 0.24.1-1
- bump spec numbers (dmcphers@redhat.com)
* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.23.4-1
- Renaming for open-source release

* Tue Mar 27 2012 Dan McPherson <dmcphers@redhat.com> 0.23.3-1
- bug 807260 (wdecoste@localhost.localdomain)

* Mon Mar 26 2012 Dan McPherson <dmcphers@redhat.com> 0.23.2-1
- Colocation hack for jenkins client -- need a better method to do this in the
  descriptor. (ramr@redhat.com)

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.23.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.22.2-1
- force jenkins to https (dmcphers@redhat.com)
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- Update jenkins li/libra => stickshift (kraman@gmail.com)
- Jenkens templates switch to proper gear size names (rmillner@redhat.com)
- Changes to rename raw to diy. (mpatel@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 0.22.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 0.21.3-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Wed Feb 22 2012 Dan McPherson <dmcphers@redhat.com> 0.21.2-1
- Bug 795654 (dmcphers@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.21.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.20.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- Bug 789232 (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.20.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 01 2012 Dan McPherson <dmcphers@redhat.com> 0.19.4-1
- fix postgres move and other selinux move fixes (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 0.19.3-1
- deploy httpd proxy from migration (dmcphers@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.19.2-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- jenkins-client-1.4: Modified license to ASL V2 (jhonce@redhat.com)

* Fri Jan 13 2012 Dan McPherson <dmcphers@redhat.com> 0.19.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.18.4-1
- fix build breaks (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 0.18.3-1
- basic descriptors for all cartridges; added primitive structure for a www-
  dynamic cartridge that will abstract all httpd processes that any cartridges
  need (e.g. php, perl, metrics, rockmongo etc). (rchopra@redhat.com)
