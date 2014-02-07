%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-controller
%global rubyabi 1.9.1

Summary:       Cloud Development Controller
Name:          rubygem-%{gem_name}
Version: 1.20.1
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
Requires:      %{?scl:%scl_prefix}rubygem(state_machine)
Requires:      %{?scl:%scl_prefix}rubygem(dnsruby)
Requires:      %{?scl:%scl_prefix}rubygem(httpclient)
Requires:      rubygem(openshift-origin-common)
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
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
This contains the Cloud Development Controller packaged as a rubygem.

%package doc
Summary: Cloud Development Controller docs

%description doc
Cloud Development Controller ri documentation 

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

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
mkdir -p %{buildroot}/etc/openshift/


%files
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/LICENSE 
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/COPYRIGHT
%{gem_instdir}
%{gem_cache}
%{gem_spec}

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Merge pull request #4610 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4532 from bparees/jenkins_by_uuid
  (dmcphers+openshiftbot@redhat.com)
- Card #185: sending app alias to all web_proxy gears (abhgupta@redhat.com)
- Bug 1048758 (dmcphers@redhat.com)
- Merge pull request #4608 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4401 from sosiouxme/bug1040257
  (dmcphers+openshiftbot@redhat.com)
- bug 1054654 (lnader@redhat.com)
- <broker> always prevent alias conflicts with app names (lmeyer@redhat.com)
- <broker> conf to allow alias under cloud domain - bug 1040257
  (lmeyer@redhat.com)
- <models/application.rb> standardize whitespace (lmeyer@redhat.com)
- Speeding up merges (dmcphers@redhat.com)
- Pairing down cuc tests (dmcphers@redhat.com)
- Pairing down cuc tests (dmcphers@redhat.com)
- Merge pull request #4596 from smarterclayton/allow_local_spec_dev
  (dmcphers+openshiftbot@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Keeping tests of same type in same group (dmcphers@redhat.com)
- Make it possible to run oo-admin-* scripts from source (ccoleman@redhat.com)
- Fixing common test case timeout (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- Rebalancing tests (dmcphers@redhat.com)
- Speeding up cart test cases (dmcphers@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.16-1
- Merge pull request #4580 from pravisankar/dev/ravi/admin-repair-fixes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair: Print info related to usage errors for paid users in usage-
  refund.log (rpenta@redhat.com)
- Add begin usage ops after update-cluster/execute-connects op
  (rpenta@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.15-1
- Merge pull request #4568 from danmcp/bug1049044
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049044: Creating a single sshkey for each scalable application
  (abhgupta@redhat.com)
- Bug 1055371 (dmcphers@redhat.com)
- fix bz 1049063 - do not throw exception for status call (rchopra@redhat.com)
- Merge pull request #4555 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 1056657: Fixing typo (abhgupta@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.14-1
- Adding gem to ignore list (dmcphers@redhat.com)
- Rebalancing cartridge tests (dmcphers@redhat.com)
- Add API for getting a single cartridge (lnader@redhat.com)
- Merge pull request #4551 from pravisankar/dev/ravi/bug1049626
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4543 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Rebalancing cartridge extended tests (dmcphers@redhat.com)
- Bug 1056178 - Add useful error message during node removal from district
  (rpenta@redhat.com)
- Bug 1055878: calling tidy once per gear instead of per gear per cart
  (abhgupta@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.13-1
- Add more tests around downloadable cartridges (ccoleman@redhat.com)
- Merge pull request #4531 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4536 from danmcp/bug982921
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4529 from pravisankar/dev/ravi/bug1049626
  (dmcphers+openshiftbot@redhat.com)
- Bug 1040113: Handling edge cases in cleaning up downloaded cart map Also,
  fixing a couple of minor issues (abhgupta@redhat.com)
- Bug 982921 (dmcphers@redhat.com)
- Bug 1028919 - Do not make mcollective call for unsubscribe connection op when
  there is nothing to unsubscribe (rpenta@redhat.com)
- Better error message (dmcphers@redhat.com)
- Merge pull request #4506 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1054406 (lnader@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Remove component_(start|stop|configure)_order from Mongo
  (ccoleman@redhat.com)
- Bug 1054610 - Fix total_error_count in oo-admin-chk (rpenta@redhat.com)
- Merge pull request #4504 from bparees/revert_jenkins_dl
  (dmcphers+openshiftbot@redhat.com)
- Revert "Bug 995807 - Jenkins builds fail on downloadable cartridges"
  (bparees@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)
- Merge pull request #4496 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051203 (dmcphers@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Merge pull request #4389 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4477 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4481 from abhgupta/sshkey_removal_fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4480 from abhgupta/bug_1052395
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4478 from pravisankar/dev/ravi/fix-trackusage-order
  (dmcphers+openshiftbot@redhat.com)
- Moving test to functional tests and adding request_time to send to plugin
  (abhgupta@redhat.com)
- Separating out node selection algorithm (abhgupta@redhat.com)
- Merge pull request #4437 from bparees/jenkins_dl_cart_test
  (dmcphers+openshiftbot@redhat.com)
- Bug 1035186 (dmcphers@redhat.com)
- Removing sshkeys and env_vars in pending ops (abhgupta@redhat.com)
- Fix for bug 1052395 (abhgupta@redhat.com)
- Push only begin track usage ops to the end of the op group
  (rpenta@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Merge pull request #4436 from bparees/jenkins_dl_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bug 1040700 (dmcphers@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4435 from bparees/ci_timeouts
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4429 from pravisankar/dev/ravi/usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair refactor Added repair for usage inconsistencies
  (rpenta@redhat.com)
- Use mongoid 'save\!' instead of 'save' to raise an exception in case of
  failures (rpenta@redhat.com)
- Execute track usage ops in the end for any opgroup (rpenta@redhat.com)
- redistribute some group 1 extended cartridge tests into group 4
  (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.6-1
- Mongoid error on app.save results in gear counts being out of sync
  (ccoleman@redhat.com)
- Merge pull request #4430 from worldline/default-allow-ha
  (dmcphers+openshiftbot@redhat.com)
- Add default user capability to create HA apps (filirom1@gmail.com)
- Merge pull request #4428 from mrunalp/test_routing
  (dmcphers+openshiftbot@redhat.com)
- Route changes (ccoleman@redhat.com)
- allow custom ha prefix and suffix (filirom1@gmail.com)
- Merge pull request #4421 from abhgupta/abhgupta-scheduler
  (dmcphers+openshiftbot@redhat.com)
- Fix for bug 1047950 and bug 1047952 (abhgupta@redhat.com)
- Fix for bug 1040673 (abhgupta@redhat.com)
- Add --quiet, --create, and --logins-file to oo-admin-ctl-user
  (jliggitt@redhat.com)
- oo-admin-usage enhancements: Show aggregated usage data for the given
  timeframe. (rpenta@redhat.com)
