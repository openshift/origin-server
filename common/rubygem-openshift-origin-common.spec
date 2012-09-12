%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-common
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Common
Name:           rubygem-%{gemname}
Version: 0.16.6
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(activemodel)
Requires:       rubygem(json)
Requires:       rubygem(rcov)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Common Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version
Obsoletes: 	rubygem-stickshift-common

%description
This contains the Cloud Development Common packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Common packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.16.6-1
- Merge pull request #676 from pravisankar/dev/ravi/bug/852324
  (openshift+bot@redhat.com)
- Fix for bug# 852324 (rpenta@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.16.5-1
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.16.4-1
- fix obsoletes (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.16.3-1
- new package built with tito

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- removing Gemfile.locks (dmcphers@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Thu Aug 23 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- 

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 15 2012 Adam Miller <admiller@redhat.com> 0.14.3-1
- Merge pull request #377 from brenton/misc1 (openshift+bot@redhat.com)
- Removing duplicate require (bleanhar@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- Removing unneeded mongo dep (bleanhar@redhat.com)
- gemspec refactorings based on Fedora packaging feedback (bleanhar@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Generate fields in the descriptor only if they are not empty or default value
  (kraman@gmail.com)

* Fri Jul 20 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- Bug 841073 (dmcphers@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.12.4-1
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.12.3-1
- Misc selinux fixes for RHEL6.3 (bleanhar@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Mon Jul 02 2012 Adam Miller <admiller@redhat.com> 0.12.2-1
- BugFixes: 824973, 805983, 796458 (rpenta@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Tue Jun 12 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Strip out the unnecessary gems from rcov reports and focus it on just the
  OpenShift code. (rmillner@redhat.com)

* Fri Jun 08 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Updated gem info for rails 3.0.13 (admiller@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bumping spec versions (admiller@redhat.com)

* Fri May 25 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- code for min_gear setting (rchopra@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- nit (dmcphers@redhat.com)
- proper usage of OpenShift::Model and beginnings of usage tracking
  (dmcphers@redhat.com)
- Add rcov testing to the Stickshift broker, common and controller.
  (rmillner@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump spec version (dmcphers@redhat.com)
- bumping spec versions (admiller@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.8.7-1
- CloudUser.find() not creating scaling object for user.scaling as it expectes
  'Hash' instead of 'BSON::OrderedHash'. Fix is to create scaling object if the
  record has any 'Hash type'. (rpenta@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.8.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.8.5-1
- forcing builds (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.8.3-1
- new package built with tito
