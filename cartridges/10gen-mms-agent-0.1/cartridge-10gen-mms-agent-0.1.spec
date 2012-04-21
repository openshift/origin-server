%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/10gen-mms-agent-0.1

Name: cartridge-10gen-mms-agent-0.1
Version: 1.8.2
Release: 1%{?dist}
Summary: Embedded 10gen MMS agent for performance monitoring of MondoDB

Group: Applications/Internet
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-10gen-mms-agent-0.1

Requires: stickshift-abstract
Requires: cartridge-mongodb-2.0
Requires: pymongo
Requires: mms-agent

%description
Provides 10gen MMS agent cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 1.8.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 1.7.3-1
- 

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 1.7.2-1
- Renaming for open-source release

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 1.7.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 1.6.3-1
- replacing just the mms credentials in the settings.py file instead of
  replacing the entire place. also got rid of unneccesary git clone step.
  (abhgupta@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 1.6.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- replacing references to libra with stickshift in rockmongo cartridge
  (abhgupta@redhat.com)
- removing call to load_node_conf method which is no longer present or required
  (abhgupta@redhat.com)
- replacing libra with stickshift for 10gen mms cartridge (abhgupta@redhat.com)

* Fri Mar 02 2012 Dan McPherson <dmcphers@redhat.com> 1.6.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 27 2012 Dan McPherson <dmcphers@redhat.com> 1.5.2-1
- cleanup all the old command usage in help and messages (dmcphers@redhat.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 1.5.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 1.4.3-1
- Fix for bugz# 789814. Fixed 10gen-mms-agent and rockmongo descriptors. Fixed
  info sent back by legacy broker when cartridge doesnt not have info for
  embedded cart. (kraman@gmail.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 1.4.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 1.4.1-1
- bump spec numbers (dmcphers@redhat.com)

* Wed Feb 01 2012 Dan McPherson <dmcphers@redhat.com> 1.3.4-1
- fix postgres move and other selinux move fixes (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- deploy httpd proxy from migration (dmcphers@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 1.3.2-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- Modified license to ASL V2, Added COPYRIGHT and LICENSE files
  (jhonce@redhat.com)

* Fri Jan 13 2012 Dan McPherson <dmcphers@redhat.com> 1.3.1-1
- bump spec numbers (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 1.2.5-1
- fix build breaks (dmcphers@redhat.com)

* Fri Jan 06 2012 Dan McPherson <dmcphers@redhat.com> 1.2.4-1
- basic descriptors for all cartridges; added primitive structure for a www-
  dynamic cartridge that will abstract all httpd processes that any cartridges
  need (e.g. php, perl, metrics, rockmongo etc). (rchopra@redhat.com)
