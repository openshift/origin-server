%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name stickshift-common
%global rubyabi 1.9.1

Summary:        Cloud Development Common
Name:           %{?scl:%scl_prefix}rubygem-%{gem_name}
Version:        0.15.2
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/crankcase/source/rubygem-%{gem_name}/%{gem_name}-%{version}.gem
Source1:        stickshift.fc
Source2:        stickshift.if
Source3:        stickshift.te
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(activemodel)
Requires:       %{?scl:%scl_prefix}rubygem(json)
Requires:       %{?scl:%scl_prefix}rubygem(rcov)
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python
BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildRequires:  selinux-policy-targeted
BuildRequires:  policycoreutils-python
BuildArch:      noarch
Provides:       %{?scl:%scl_prefix}rubygem(%{gem_name}) = %version

%package -n ruby-%{gem_name}
Summary:        Cloud Development Common Library
Requires:       rubygem(%{gem_name}) = %version
Provides:       ruby(%{gem_name}) = %version

%description
This contains the Cloud Development Common packaged as a rubygem.

%description -n ruby-%{gem_name}
This contains the Cloud Development Common packaged as a ruby site library.

%prep
%{?scl:scl enable %scl "}
gem unpack %{SOURCE0}
%setup -q -D -T -n  %{gem_name}-%{version}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec
%{?scl:"}

%build
mkdir -p ./%{gem_dir}

%{?scl:scl enable %scl - << \EOF}
gem build %{gem_name}.gemspec
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

# Setup Selinux
rm -rf selinux
mkdir selinux
mkdir -p %{buildroot}/usr/share/selinux/packages/%{name}
cd selinux
cp %{SOURCE1} .
cp %{SOURCE2} .
cp %{SOURCE3} .
make -f /usr/share/selinux/devel/Makefile
install -p -m 644 -D stickshift.fc %{buildroot}%{_datadir}/selinux/packages/%{name}/stickshift.fc
install -p -m 644 -D stickshift.if %{buildroot}%{_datadir}/selinux/packages/%{name}/stickshift.if
install -p -m 644 -D stickshift.te %{buildroot}%{_datadir}/selinux/packages/%{name}/stickshift.te
install -p -m 644 -D stickshift.pp %{buildroot}%{_datadir}/selinux/packages/%{name}/stickshift.pp
cd -

%clean
rm -rf %{buildroot}                                

%files
%dir %{gem_instdir}
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/COPYRIGHT
%doc %{gem_docdir}
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/%{gem_name}.gemspec
%{gem_spec}
%{_datadir}/selinux/packages/%{name}/
%exclude %{gem_cache}
%exclude %{gem_libdir}
%exclude %{gem_instdir}/rubygem-%{gem_name}.spec

%post
if [ "$1" -le "1" ] ; then # First install
semodule -i %{_datadir}/selinux/packages/%{name}/stickshift.pp 2>/dev/null || :
fixfiles -R rubygem-stickshift-common restore
fi

%preun
if [ "$1" -lt "1" ] ; then # Final removal
semodule -r stickshift 2>/dev/null || :
fi

%postun
if [ "$1" -ge "1" ] ; then # Upgrade
semodule -i %{_datadir}/selinux/packages/%{name}/stickshift.pp 2>/dev/null || :
# TODO
# What other packages should be added here?  Probably anything that could be
# affected by stickshift.fc, right?
fixfiles -R rubygem-stickshift-common restore
fi

%changelog
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
  gearchanger plugin - Added mcollective agent and facter plugins - Added
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
- proper usage of StickShift::Model and beginnings of usage tracking
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
