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
Version: 1.29.4
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
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
%if %{?scl_ror:1}%{!?scl_ror:0} || 0%{?fedora} >= 20
Requires:      %{?scl:%scl_prefix}rubygem(rails-observers)
%endif
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
BuildRequires: %{?scl:%scl_prefix}rubygem-rails
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

rm -rf %{buildroot}%{gem_instdir}/.yardoc*

%files
%dir %{gem_instdir}
%doc %{gem_instdir}/LICENSE
%doc %{gem_instdir}/COPYRIGHT
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/%{gem_name}.gemspec
%{gem_instdir}/test
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
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.29.4-1
- Merge pull request #6283 from dinhxuanvu/oo-diagnostics-sync
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064039: Add oo-diagnostic report 401 Unauthorized error
  (vdinh@redhat.com)

* Tue Oct 20 2015 Stefanie Forrester <sedgar@redhat.com> 1.29.3-1
- Merge pull request #6275 from dinhxuanvu/master
  (dmcphers+openshiftbot@redhat.com)
- oo-diagnostics: SSL cert matching for broker & BROKER_HOST (vdinh@redhat.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.29.2-1
- oo-diagnostics: Handle empty gemdirs (miciah.masters@gmail.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- Bug 1160752 - Make apache-vhost more atomic (jhonce@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- oo-diagnostics: test_mcollective_direct_addressing (miciah.masters@gmail.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- oo-diagnostics: add test_sshd_permit_root_login (miciah.masters@gmail.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Bug 1122515 (lnader@redhat.com)

* Wed Jul 23 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Fix syntax error in oo-diagnostics (decarr@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Merge pull request #5630 from Miciah/bug-1121267-oo-diagnostics-add-
  test_node_clock_in_synch_with_broker (dmcphers+openshiftbot@redhat.com)
- oo-diagnostics: Add test_node_clock_in_synch_with_broker
  (miciah.masters@gmail.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- oo-diagnostics: Read /proc instead of using ps (miciah.masters@gmail.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- add rails as a BuildRequires for the rpm build, the gemspec now requires it
  (admiller@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 12 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- add conditional inclusion of rails-observers which is it's own gem in rails4
  (admiller@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Merge pull request #5449 from jwhonce/bug/1100743
  (dmcphers+openshiftbot@redhat.com)
- Bug 1100743 - Validate manifest endpoint element (jhonce@redhat.com)
- Bug 1100743 - Validate manifest endpoint element (jhonce@redhat.com)

* Fri May 23 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- diagnostics: fix errant warning on httpd conf (lmeyer@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- Merge pull request #5324 from Miciah/oo-diagnostics-test_broker_certificate-
  fixes (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4983 from Miciah/bug-1077664-oo-diagnostics-
  test_node_mco_log-fixes (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)
- oo-diagnostics: Fix comments for test_node_mco_log (miciah.masters@gmail.com)
- oo-diagnostics: Better handle curl error (miciah.masters@gmail.com)
- oo-diagnostics: Drop unneeded require 'socket' (miciah.masters@gmail.com)
- oo-diagnostics: Fix test_node_mco_log when no log (miciah.masters@gmail.com)

* Mon May 05 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Merge pull request #5138 from Miciah/rubygem-openshift-origin-common-require-
  parseconfig (dmcphers+openshiftbot@redhat.com)
- rubygem-openshift-origin-common: Req. parseconfig (miciah.masters@gmail.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.23.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.5-1
- cleanup yardoc (tdawson@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.22.4-1
- Bug 1086094: Multiple changes for cartridge colocation We are:  - taking into
  account the app's complete group overrides  - allowing only plugin carts to
  colocate with web/service carts  - blocking plugin (except sparse) carts from
  responding to scaling min/max changes (abhgupta@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #5222 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Add platform attribute to cartridge serialization and fixed tests
  (abhgupta@redhat.com)
- Removing Start-Order and Stop-Order from the manifest (abhgupta@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Merge pull request #5200 from ncdc/metrics (dmcphers+openshiftbot@redhat.com)
- Metrics work (teddythetwig@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.21.6-1
- Merge pull request #5087 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 989941: preventing colocation of cartridges that independently scale
  (abhgupta@redhat.com)
- Bug 1075437 - Return exit code 1 instead of nil when no exit code is NOT
  provided (lnader@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 1078814: Adding more validations for cartridge manifests
  (abhgupta@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- oo-diagnostics: add sclized /etc to selinux check (lmeyer@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- oo-diagnostics: fail more accurately w/ districts required
  (lmeyer@redhat.com)
- Bug 1077031 - Warn if Watchman is not running (jhonce@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.21.2-1
- oo-diagnostics: detect unreadable apache conf files (lmeyer@redhat.com)
- oo-diagnostics: refactor test for executable commands (lmeyer@redhat.com)
- oo-diagnostics: remove enterprise RPM test from origin (lmeyer@redhat.com)
- oo-diagnostics: warn on node.conf/envvars mismatch (lmeyer@redhat.com)
- oo-diagnostics: handle missing host command (lmeyer@redhat.com)
- oo-diagnostics: warn re vmware-tools on mco unsynced warning
  (lmeyer@redhat.com)
- oo-diagnostics: detect more common selinux problems (lmeyer@redhat.com)
- oo-diagnostics: improve suggestion for mco-client.log (lmeyer@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 916758 - Give better message on config failure (dmcphers@redhat.com)
- Bug 1076032 - Attempting to unlock closed file descriptor (jhonce@redhat.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Enable docker builds of openshift-origin-broker (jforrest@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

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
