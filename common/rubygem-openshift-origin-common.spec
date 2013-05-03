%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-common
%global rubyabi 1.9.1

Summary:       Cloud Development Common
Name:          rubygem-%{gem_name}
Version: 1.7.3
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(activemodel)
Requires:      %{?scl:%scl_prefix}rubygem(json)
%if 0%{?rhel}
Requires:      openshift-origin-util-scl
%endif
%if 0%{?fedora}
Requires:      openshift-origin-util
%endif
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildRequires: %{?scl:%scl_prefix}rubygem-yard
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%package doc
Summary:        Cloud Development Common Library Documentation

%description
This contains the Cloud Development Common packaged as a rubygem.

%description doc
This contains the Cloud Development Common packaged as a ruby site library
documentation files.

%prep
%setup -q

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

%files
%dir %{gem_instdir}
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/COPYRIGHT
%doc %{gem_instdir}/.yardoc
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/%{gem_name}.gemspec
%{gem_instdir}
%{gem_spec}
%{gem_libdir}

%exclude %{gem_cache}
%exclude %{gem_instdir}/rubygem-%{gem_name}.spec

%files doc 
%doc %{gem_docdir}

%changelog
* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Special file processing (fotios@redhat.com)
- Validate cartridge and vendor names under certain conditions
  (asari.ruby@gmail.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Card 551 (lnader@redhat.com)
- Move Runtime::Cartridge to openshift-origin-common (ironcladlou@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Keep a separate cache for each config file. (rmillner@redhat.com)
- Cache the node conf into a singleton instance so we do not constantly reload
  and re-parse it. (rmillner@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Card 534 (lnader@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Fix bug 927893 - calculate is_premium? by checking for usage rates
  (jliggitt@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Add SNI upload support to API (lnader@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Merge pull request #1643 from kraman/update_parseconfig (dmcphers@redhat.com)
- Replacing get_value() with config['param'] style calls for new version of
  parseconfig gem. (kraman@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.4.6-1
- reverted US2448 (lnader@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- Added validation for SSL certificate and private key (lnader@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- fix rubygem sources (tdawson@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Fixes for ruby193 (john@ibiblio.org)
- providing stub for usage_rates and changing rest response field to
  usage_rates from usage_rate_usd (abhgupta@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- US2626 changes based on feedback - Add application name in Usage and
  UsageRecord models - Change 'price' to 'usage_rate_usd' in rest cartridge
  model - Change 'charges' to 'usage_rates' in rails configuration - Rails
  configuration stores usage_rates for different currencies (currently only
  have usd) (rpenta@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Collect/Sync Usage data for EAP cart (rpenta@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- fix for bug 896333 (abhgupta@redhat.com)
- fixed runtime tests and Lock exception handling (lnader@redhat.com)
- fix for bug 895730 and 895733 (abhgupta@redhat.com)
- 892068 (dmcphers@redhat.com)
- Bug 893879 (dmcphers@redhat.com)
- Bug 889958 (dmcphers@redhat.com)
- fix for bug 893365 (abhgupta@redhat.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- fix require for fedora (dmcphers@redhat.com)
- add util package for oo-ruby (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- Fix for bug# 876516 (rpenta@redhat.com)
- Fix bug# 876124: caused due to ruby 1.8 to 1.9 upgrade (rpenta@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- remove %%prep steps that add gem pre-processing since we're using a .tar.gz
  (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- getting specs up to 1.9 sclized (dmcphers@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
