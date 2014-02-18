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
Version: 1.20.0
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
Requires:      %{?scl:%scl_prefix}rubygem(safe_yaml)
Requires:      %{?scl:%scl_prefix}rubygem(bundler)
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
# For the prereq_domain_resolves check in oo-diagnostics:
Requires:      bind-utils
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

%if 0%{?scl:1}
mkdir -p %{buildroot}%{_root_sbindir}
cp -p bin/oo-* %{buildroot}%{_root_sbindir}/
mkdir -p %{buildroot}%{_root_mandir}/man8/
cp bin/man/*.8 %{buildroot}%{_root_mandir}/man8/
%else
mkdir -p %{buildroot}%{_sbindir}
cp -p bin/oo-* %{buildroot}%{_sbindir}/
mkdir -p %{buildroot}%{_mandir}/man8/
cp bin/man/*.8 %{buildroot}%{_mandir}/man8/
%endif


%files
%dir %{gem_instdir}
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/COPYRIGHT
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/%{gem_name}.gemspec
%{gem_instdir}
%{gem_spec}
%{gem_libdir}

%if 0%{?scl:1}
%attr(0750,-,-) %{_root_sbindir}/oo-diagnostics
%{_root_mandir}/man8/oo-diagnostics.8.gz
%else
%attr(0750,-,-) %{_sbindir}/oo-diagnostics
%{_mandir}/man8/oo-diagnostics.8.gz
%endif

%exclude %{gem_cache}
%exclude %{gem_instdir}/rubygem-%{gem_name}.spec

%files doc 
%doc %{gem_docdir}

%changelog
* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4770 from lsm5/revert-iptables-dir
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064219 - revert iptables location change (lsm5@redhat.com)
- cleanup (dmcphers@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Bug 1064157 - new filepaths in oo-diagnostics (lsm5@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Merge pull request #4688 from
  smarterclayton/bug_1059858_expose_requires_to_clients
  (dmcphers+openshiftbot@redhat.com)
- Support changing categorizations (ccoleman@redhat.com)
- Bug 1062539 - UseMissingElementError as intended (dmcphers@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Merge pull request #4599 from Miciah/bug-1058527-oo-diagnostics-is-missing-a
  -dependency-on-bind-utils (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Add depends on bind-utils for oo-diagnostics (miciah.masters@gmail.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- Fixing typo (bleanhar@redhat.com)
- Various iptables integration fixes (bleanhar@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Make it possible to run oo-admin-* scripts from source (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.18.9-1
- Bug 1034110 (dmcphers@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.18.8-1
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Revert "Bug 995807 - Jenkins builds fail on downloadable cartridges"
  (bparees@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.18.7-1
- Merge pull request #4436 from bparees/jenkins_dl_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- Bug 1051833 - PathUtils.flock() not removing lock file (jhonce@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.18.5-1
- <oo-diagnostics> bug 1046202 test_broker_httpd_error_log (lmeyer@redhat.com)