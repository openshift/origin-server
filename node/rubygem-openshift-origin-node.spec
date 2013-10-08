%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-node
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%global apprundir %{_var}/run/openshift
%global openshift_lib %{_usr}/lib/openshift

Summary:       Cloud Development Node
Name:          rubygem-%{gem_name}
Version: 1.16.0
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
Requires:      %{?scl:%scl_prefix}rubygem(commander)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(mocha)
Requires:      %{?scl:%scl_prefix}rubygem(open4)
Requires:      %{?scl:%scl_prefix}rubygem(parallel)
%if 0%{?rhel} <= 6
# non-scl open4 required for ruby 1.8 cartridge
# Also see related bugs 924556 and 912215
Requires:      rubygem(open4)
%endif
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
Requires:      %{?scl:%scl_prefix}rubygem(rspec)
Requires:      %{?scl:%scl_prefix}rubygem(safe_yaml)
Requires:      %{?scl:%scl_prefix}rubygem(rest-client)
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}ruby(selinux)
Requires:      cronie
Requires:      crontabs
Requires:      git
Requires:      libcgroup-pam
Requires:      libselinux-python
Requires:      iproute
Requires:      lsof
Requires:      mercurial
Requires:      mod_ssl
Requires:      openshift-origin-node-proxy
Requires:      pam_openshift
Requires:      python
Requires:      quota
Requires:      rubygem(openshift-origin-common)
Requires:      unixODBC
Requires:      unixODBC-devel
%if 0%{?fedora}%{?rhel} <= 6
Requires:      libcgroup
%else
Requires:      libcgroup-tools
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
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
This contains the Cloud Development Node packaged as a rubygem.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir .%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}%{appdir}/.tc_user_dir

# Move the gem configs to the standard filesystem location
mkdir -p %{buildroot}/etc/openshift
rm -rf %{buildroot}%{gem_instdir}/conf/plugins.d/README
mv %{buildroot}%{gem_instdir}/conf/* %{buildroot}/etc/openshift

#move pam limit binaries to proper location
mkdir -p %{buildroot}/usr/libexec/openshift/lib
mv %{buildroot}%{gem_instdir}/misc/libexec/lib/quota_attrs.sh %{buildroot}/usr/libexec/openshift/lib
mv %{buildroot}%{gem_instdir}/misc/libexec/lib/archive_git_submodules.sh %{buildroot}/usr/libexec/openshift/lib

# Install the cartridge SDK files and environment variables for each
mkdir -p %{buildroot}%{openshift_lib}/cartridge_sdk
mv %{buildroot}%{gem_instdir}/misc/usr/lib/cartridge_sdk/* %{buildroot}%{openshift_lib}/cartridge_sdk
echo '%{openshift_lib}/cartridge_sdk/bash/sdk' > %{buildroot}/etc/openshift/env/OPENSHIFT_CARTRIDGE_SDK_BASH
echo '%{openshift_lib}/cartridge_sdk/ruby/sdk.rb' > %{buildroot}/etc/openshift/env/OPENSHIFT_CARTRIDGE_SDK_RUBY

#move the shell binaries into proper location
mv %{buildroot}%{gem_instdir}/misc/bin/* %{buildroot}/usr/bin/
mv %{buildroot}%{gem_instdir}/misc/sbin/* %{buildroot}/usr/sbin/

# Create run dir for openshift "services"
%if 0%{?fedora} >= 15
mkdir -p %{buildroot}/etc/tmpfiles.d
mv %{buildroot}%{gem_instdir}/misc/etc/openshift-run.conf %{buildroot}/etc/tmpfiles.d
%endif
mkdir -p %{buildroot}%{apprundir}

# place an example file.  It _must_ be placed in the gem_docdir because of how
# the doc directive works and how we're using it in the files section.
mv %{buildroot}%{gem_instdir}/misc/doc/cgconfig.conf %{buildroot}%{gem_docdir}/cgconfig.conf

%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}/etc/rc.d/init.d/
cp %{buildroot}%{gem_instdir}/misc/init/openshift-tc %{buildroot}/etc/rc.d/init.d/
cp %{buildroot}%{gem_instdir}/misc/init/openshift-iptables-port-proxy %{buildroot}/etc/rc.d/init.d/
%else
mkdir -p %{buildroot}/etc/systemd/system
mv %{buildroot}%{gem_instdir}/misc/services/openshift-tc.service %{buildroot}/etc/systemd/system/openshift-tc.service
mv %{buildroot}%{gem_instdir}/misc/services/openshift-iptables-port-proxy.service %{buildroot}/etc/systemd/system/openshift-iptables-port-proxy.service
%endif

# Don't install or package what's left in the misc directory
rm -rf %{buildroot}%{gem_instdir}/misc
rm -rf %{buildroot}%{gem_instdir}/.yardoc
chmod 755 %{buildroot}%{gem_instdir}/test/unit/*.rb

# Cron configuration that enables running each gear's cron jobs
mkdir -p %{buildroot}/etc/cron.d
mkdir -p %{buildroot}/etc/cron.minutely
mkdir -p %{buildroot}/etc/cron.hourly
mkdir -p %{buildroot}/etc/cron.daily
mkdir -p %{buildroot}/etc/cron.weekly
mkdir -p %{buildroot}/etc/cron.monthly
mkdir -p %{buildroot}%{openshift_lib}/node/jobs

mv %{buildroot}%{gem_instdir}/jobs/* %{buildroot}%{openshift_lib}/node/jobs/
ln -s %{openshift_lib}/node/jobs/1minutely %{buildroot}/etc/cron.d/
ln -s %{openshift_lib}/node/jobs/openshift-origin-cron-minutely %{buildroot}/etc/cron.minutely/
ln -s %{openshift_lib}/node/jobs/openshift-origin-cron-hourly %{buildroot}/etc/cron.hourly/
ln -s %{openshift_lib}/node/jobs/openshift-origin-cron-daily %{buildroot}/etc/cron.daily/
ln -s %{openshift_lib}/node/jobs/openshift-origin-cron-weekly %{buildroot}/etc/cron.weekly/
ln -s %{openshift_lib}/node/jobs/openshift-origin-cron-monthly %{buildroot}/etc/cron.monthly/
ln -s %{openshift_lib}/node/jobs/openshift-origin-stale-lockfiles %{buildroot}/etc/cron.daily/

%post
/bin/rm -f /etc/openshift/env/*.rpmnew

if ! grep -q "/usr/bin/oo-trap-user" /etc/shells
then
  echo "/usr/bin/oo-trap-user" >> /etc/shells
fi

# Start the cron service so that each gear gets its cron job run, if they're enabled
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
  systemctl restart  crond.service || :
  systemctl enable openshift-tc.service || :
  systemctl enable openshift-iptables-port-proxy || :
%else
  /sbin/chkconfig --add openshift-tc || :
  /sbin/chkconfig --add openshift-iptables-port-proxy || :
  service crond restart || :
%endif

( oo-admin-ctl-tc status || oo-admin-ctl-tc restart || : ) >/dev/null 2>&1

%preun
if [ $1 -eq 0 ]
then
oo-admin-ctl-tc stop >/dev/null 2>&1 || :

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
  systemctl disable openshift-tc.service || :
%else
  chkconfig --del openshift-tc || :
  chkconfig --del openshift-iptables-port-proxy || :
%endif

fi


%files
%doc LICENSE COPYRIGHT
%doc %{gem_docdir}
%{gem_instdir}
%{gem_cache}
%{gem_spec}
%attr(0750,-,-) /usr/sbin/*
%attr(0755,-,-) /usr/bin/*
/usr/libexec/openshift/lib/quota_attrs.sh
/usr/libexec/openshift/lib/archive_git_submodules.sh
%attr(0755,-,-) %{openshift_lib}/cartridge_sdk
%attr(0755,-,-) %{openshift_lib}/cartridge_sdk/bash
%attr(0744,-,-) %{openshift_lib}/cartridge_sdk/bash/*
%attr(0755,-,-) %{openshift_lib}/cartridge_sdk/ruby
%attr(0744,-,-) %{openshift_lib}/cartridge_sdk/ruby/*
%dir /etc/openshift
%config(noreplace) /etc/openshift/node.conf
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.filter.rules
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.nat.rules
%config(noreplace) /etc/openshift/env/*
%attr(0640,-,-) %config(noreplace) /etc/openshift/resource_limits.conf
%dir %attr(0755,-,-) %{appdir}
%dir %attr(0750,-,-) %{appdir}/.tc_user_dir

%if 0%{?fedora}%{?rhel} <= 6
%attr(0755,-,-) /etc/rc.d/init.d/openshift-tc
%attr(0755,-,-) /etc/rc.d/init.d/openshift-iptables-port-proxy
%else
%attr(0750,-,-) /etc/systemd/system/openshift-tc.service
%attr(0750,-,-) /etc/systemd/system/openshift-iptables-port-proxy.service
%endif

%if 0%{?fedora} >= 15
/etc/tmpfiles.d/openshift-run.conf
%endif
# upstart files
%attr(0755,-,-) %{_var}/run/openshift
%dir %attr(0755,-,-) %{openshift_lib}/node/jobs
%config(noreplace) %attr(0644,-,-) %{openshift_lib}/node/jobs/1minutely
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-cron-minutely
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-cron-hourly
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-cron-daily
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-cron-weekly
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-cron-monthly
%attr(0755,-,-) %{openshift_lib}/node/jobs/openshift-origin-stale-lockfiles
%dir /etc/cron.minutely
%config(noreplace) %attr(0644,-,-) /etc/cron.d/1minutely
%attr(0755,-,-) /etc/cron.minutely/openshift-origin-cron-minutely
%attr(0755,-,-) /etc/cron.hourly/openshift-origin-cron-hourly
%attr(0755,-,-) /etc/cron.daily/openshift-origin-cron-daily
%attr(0755,-,-) /etc/cron.weekly/openshift-origin-cron-weekly
%attr(0755,-,-) /etc/cron.monthly/openshift-origin-cron-monthly
%attr(0755,-,-) /etc/cron.daily/openshift-origin-stale-lockfiles

%changelog
* Fri Oct 04 2013 Adam Miller <admiller@redhat.com> 1.15.9-1
- Bug 1014768 - Performance improvements for node_utilization: Allow self.all
  to pass the pwnam structure rather than having to call getpwnam each time.
  Lazy load the MCS labels and get rid of an extraneous call to Config.
  (rmillner@redhat.com)
- Merge pull request #3766 from mfojtik/bugzilla/1013653
  (dmcphers+openshiftbot@redhat.com)
- Bug 1013653 - Fix oo-su command so it is not duplicating the getpwnam call
  (mfojtik@redhat.com)

* Thu Oct 03 2013 Adam Miller <admiller@redhat.com> 1.15.8-1
- Merge pull request #3763 from rmillner/speed_up_env
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3759 from kraman/test_case_fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 1014768 - Loading the environ dominated the cost to enumerate
  ApplicationContainers.  Narrowing down the list of files to load shaves 50%%.
  (rmillner@redhat.com)
- Fix shell_exec_func_test to set shell when creating test user.
  (kraman@gmail.com)
- Fix for application_repository_func_test.rb   - gear shell needs to be oo-
  trap-user for Origin/OSE pam namespace rules to work (kraman@gmail.com)
- Extract common functionality into admin script and add service file for
  openshift-iptables-port-proxy. Fix location of lock file. (kraman@gmail.com)
- Move addresses_bound/address_bound? into container plugin (kraman@gmail.com)

* Wed Oct 02 2013 Adam Miller <admiller@redhat.com> 1.15.7-1
- Merge pull request #3751 from jwhonce/bug/1012981
  (dmcphers+openshiftbot@redhat.com)
- Bug 1012981 - Parse post-configure output for client messages
  (jhonce@redhat.com)

* Tue Oct 01 2013 Adam Miller <admiller@redhat.com> 1.15.6-1
- Merge pull request #3737 from mfojtik/bugzilla/1013653
  (dmcphers+openshiftbot@redhat.com)
- Bug 1013653 - Remove '.to_i' in oo-su command to avoid wrong user id
  (mfojtik@redhat.com)
- Bug 1012348 - Adding unixODBC dependencies to the node gem for compatibility
  with Online (bleanhar@redhat.com)

* Fri Sep 27 2013 Troy Dawson <tdawson@redhat.com> 1.15.5-1
- Merge pull request #3720 from smarterclayton/origin_ui_72_membership
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3721 from mrunalp/dev/ipt-port-proxy
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into origin_ui_72_membership
  (ccoleman@redhat.com)
- Initial checkin of iptables port proxy script. (mrunalp@gmail.com)
- remove admin_tool as a category (rchopra@redhat.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)

* Thu Sep 26 2013 Troy Dawson <tdawson@redhat.com> 1.15.4-1
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Feature tests for ssl_to_gear, V3 of mock cart serves https at primary
  endpoint on port 8123 (teddythetwig@gmail.com)
- Merge pull request #3703 from mfojtik/bugzilla/1011721
  (dmcphers+openshiftbot@redhat.com)
- Bug 1011721- Fixed wrong namespace for Cartridge Ruby SDK
  (mfojtik@redhat.com)

* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Merge pull request #3702 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3698 from rmillner/vhost_bugs
  (dmcphers+openshiftbot@redhat.com)
- typo fix (rchopra@redhat.com)
- Bug 1008638 - The create step is needed on vhost and other plugins.
  (rmillner@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3659 from mfojtik/bugzilla/1007455
  (dmcphers+openshiftbot@redhat.com)
- Added OpenShift::Cartridge::Sdk namespace and removed TODO
  (mfojtik@redhat.com)
- Bug 1007455 - Added primary_cartridge methods to Ruby SDK
  (mfojtik@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- routing spi changes (rchopra@redhat.com)
- Merge pull request #3662 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Creating the app secret token (abhgupta@redhat.com)
- Bug 1008638 - needed a way to force rebuild the framework cart.
  (rmillner@redhat.com)
- Using the geardb was causing missed gears on delete, use the
  ApplicationContainer object instead. (rmillner@redhat.com)
- Merge pull request #3666 from jwhonce/wip/secret_token
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_102 - Support OPENSHIFT_SECRET_TOKEN (jhonce@redhat.com)
- Add support for cartridge protocol types in manifest (rchopra@redhat.com)
- Merge pull request #3644 from mmahut/mmahut/cron_dupl_msg
  (dmcphers+openshiftbot@redhat.com)
- use proper return codes in has_web_proxu() bash sdk (mmahut@redhat.com)
- Bug 1008639 - the restore operation is required to put aliases and idler
  state back. (rmillner@redhat.com)
- node: adding bash sdk function has_web_proxy to check if the gear contains a
  web_proxy cartridge (mmahut@redhat.com)
- Mapping the plugin set at load time imposes unnecessary load order
  requirements. (rmillner@redhat.com)
- Functional tests for the frontend plugins. (rmillner@redhat.com)
- Prelim documentation. (rmillner@redhat.com)
- Change the plugin change procedure to use Backup->Nuke->Rebuild, more likely
  to end up in the desired state at the end if the frontend configuration is
  completely rebuilt. (rmillner@redhat.com)
- Migration tool and fixes. (rmillner@redhat.com)
- Break out FrontendHttpServer class into plugin modules. (rmillner@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 12 2013 Adam Miller <admiller@redhat.com> 1.14.7-1
- Merge pull request #3552 from VojtechVitek/passenv
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3617 from ironcladlou/dev/upgrade-stability
  (dmcphers+openshiftbot@redhat.com)
- Fix Apache PassEnv config files (vvitek@redhat.com)
- Improve upgrade MCollective response handling (ironcladlou@gmail.com)

* Wed Sep 11 2013 Adam Miller <admiller@redhat.com> 1.14.6-1
- Bug 1000764 - Enforce cartridge start order (jhonce@redhat.com)

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 1.14.5-1
- Bug 1006236 - Update description (jhonce@redhat.com)
- Merge pull request #3596 from mfojtik/bugzilla/1006207
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3594 from mfojtik/bugzilla/1004687
  (dmcphers+openshiftbot@redhat.com)
- Bug 1006207 - Fixed typo in add/remove alias (oo-devel-node)
  (mfojtik@redhat.com)
- Merge pull request #3590 from tdawson/tdawson/node-rpmlint/2013-09
  (dmcphers+openshiftbot@redhat.com)
- Bug 1004687 - Fix 'undefined method json_create' in frontend-restore
  (mfojtik@redhat.com)
- fix rpmlint errors (tdawson@redhat.com)

* Mon Sep 09 2013 Adam Miller <admiller@redhat.com> 1.14.4-1
- Fix bug 1004910: provide warning when processed_templates declares a non-
  existent file (pmorie@gmail.com)
- Merge pull request #3580 from jwhonce/bug/1005364
  (dmcphers+openshiftbot@redhat.com)
- Bug 1005364 - Restore gear user usage of facter (jhonce@redhat.com)
- Bug 1004510 - Remove welcome HEREDOC from rhcsh (jhonce@redhat.com)

* Fri Sep 06 2013 Adam Miller <admiller@redhat.com> 1.14.3-1
- Bug 1005244 - Remove unused INSTANCE_ID setting from node.conf
  (bleanhar@redhat.com)
- Merge pull request #3561 from jwhonce/bug/1004644
  (dmcphers+openshiftbot@redhat.com)
- Bug 1004886 - set memory.move_charge_at_immigrate (rmillner@redhat.com)
- Bug 1004644 - Description of frontend-no-sts is wrong (jhonce@redhat.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- Merge pull request #3548 from jwhonce/wip/oo-devel-node
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - Fix cucumber tests (jhonce@redhat.com)
- Merge pull request #3545 from mfojtik/bugzilla/1004216
  (dmcphers+openshiftbot@redhat.com)
- Bug 1004216 - Fixed typo in frontend-disconnect (oo-devel-node)
  (mfojtik@redhat.com)
- Bug 1004292 - Fix typo in oo-devel-node command (mfojtik@redhat.com)
- Merge pull request #3541 from jwhonce/wip/oo-devel-node
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3528 from rmillner/wrap_port_allocation
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - Remove files deprecated by oo-devel-node (jhonce@redhat.com)
- WIP Node Platform - oo-devel-node: clean up oo-* scripts that emulate mco
  calls (jhonce@redhat.com)
- Wrap the port range indefinitely. (rmillner@redhat.com)
- Merge pull request #3535 from ironcladlou/bz/1003969
  (dmcphers+openshiftbot@redhat.com)
- Bug 1003969: Don't raise if processed ERBs no longer exist to delete
  (ironcladlou@gmail.com)
- Merge pull request #3311 from detiber/runtime_card_213
  (dmcphers+openshiftbot@redhat.com)
- Bug 1002269 - empty client messages are dropped, should be new line
  (jforrest@redhat.com)
- Merge pull request #3521 from kraman/master
  (dmcphers+openshiftbot@redhat.com)
- Fix up unit test to prevent test pollution, fix variable name typo
  (jdetiber@redhat.com)
- <runtime> Card origin_runtime_213: realtime node_utilization checks
  (jdetiber@redhat.com)
- Adding reload as an action to restart openshift-tc (kraman@gmail.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- misc: remove duplicate import in oo-trap-user (mmahut@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Bug 999859 - Check required arguments for oo-app-create command
  (mfojtik@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Merge pull request #3485 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Make dependency on 0.0.1 version of mock explicit for upgrade tests
  (pmorie@gmail.com)
- Bug 988662 - Add --help to list of arguments for oo-env-var-* commands
  (mfojtik@redhat.com)
- nurture -> analytics (dmcphers@redhat.com)
- Handle .resultset.json (dmcphers@redhat.com)
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- Fixing openshift-tc service definition (kraman@gmail.com)
- Merge pull request #3483 from detiber/bz1000174
  (dmcphers+openshiftbot@redhat.com)
- <oo-accept-node> Bug 1000174 - oo-accept-node fixes (jdetiber@redhat.com)
- Merge pull request #3481 from ironcladlou/bz/1000193
  (dmcphers+openshiftbot@redhat.com)
- Bug 1000193: Use an Hourglass in the gear upgrader (ironcladlou@gmail.com)
- Fix test cases (ccoleman@redhat.com)
- Merge pull request #3464 from mfojtik/bugzilla/999883
  (dmcphers+openshiftbot@redhat.com)
- Bug 999883 - Print command name in usage instead of '$0' (mfojtik@redhat.com)
- Merge pull request #3474 from fotioslindiakos/Bug999837
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3470 from fotioslindiakos/Bug998704
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3432 from mfojtik/bugzilla/983605
  (dmcphers+openshiftbot@redhat.com)
- Remove any deleted/missing throttled gears from throttler's memory
  (fotios@redhat.com)
- Rescue usage percentage calculation if it's an unexpected value type
  (fotios@redhat.com)
- Add test for zero-length manifest in cartridge repo (pmorie@gmail.com)
- Bug 983605 - Allow to administrator to change the default 'rhc ssh' motd
  (mfojtik@redhat.com)
- Fix message for bug 999189 (pmorie@gmail.com)
- Merge pull request #3458 from pmorie/bugs/999679
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Merge pull request #3452 from pravisankar/dev/ravi/bug998905
  (dmcphers+openshiftbot@redhat.com)
- Added environment variable name limitations  - Limit length to 128 bytes.  -
  Allow letters, digits and underscore but can't begin with digit
  (rpenta@redhat.com)
- Fix bug 999679: skip corrupted manifests during cartridge installation
  (pmorie@gmail.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)

* Wed Aug 21 2013 Adam Miller <admiller@redhat.com> 1.13.9-1
- Merge pull request #3449 from pmorie/bugs/999189
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3440 from pmorie/bugs/999013
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3427 from ironcladlou/bz/996491
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3441 from jwhonce/wip/user_vars
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3429 from mfojtik/bugzilla/988662
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3426 from mfojtik/bugzilla/998420
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3425 from mfojtik/bugzilla/998363
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 999189: gear upgrade extension is a no-op if release version doesn't
  match supplied version (pmorie@gmail.com)
- Fix bug 999013: always remove unprocessed env/*.erb files from cartridge dir
  during compatible upgrade (pmorie@gmail.com)
- Merge pull request #3439 from pravisankar/dev/ravi/user-env-bugs
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3443 from fotioslindiakos/throttler
  (dmcphers+openshiftbot@redhat.com)
- Bug 998794 - Allow blank value for a user environment variable
  (rpenta@redhat.com)
- Node Platform - Add .env/user_vars during upgrade (jhonce@redhat.com)
- Merge pull request #3436 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Force throttler to only restore applications under a certain threshold
  (fotios@redhat.com)
- Fix creating new endpoints during incompatible upgrades (pmorie@gmail.com)
- Bug 988662 - Add exit(255) to the usage() methods for oo-user-var scripts
  (mfojtik@redhat.com)
- Bug 996491: Show warning when using snapshot and near disk quota
  (ironcladlou@gmail.com)
- Bug 998420 - Fixed typo in the --help option for oo-cgroup-template
  (mfojtik@redhat.com)
- Bug 998363 - Add --help option to GetoptLong list (mfojtik@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.8-1
- BZ#990382: Return error message and code when wrong gear id is given to oo-
  pam-(enable|disable) (mfojtik@redhat.com)
- Merge pull request #3410 from pravisankar/dev/ravi/card86
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3409 from rmillner/trailing_dot
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - make user variable rsync more reliable (jhonce@redhat.com)
- User vars node changes:  - Use 'user-var-add' mcollective call for *add*
  and/or *push* user vars. This will reduce unnecessary additional
  code/complexity.  - Add some more reserved var names: PATH, IFS, USER, SHELL,
  HOSTNAME, LOGNAME  - Do not attempt rsync when .env/user_vars dir is empty  -
  Misc bug fixes (rpenta@redhat.com)
- WIP Node Platform - Add support for settable user variables
  (jhonce@redhat.com)
- Remove trailing dot from the fqdn if there is one. (rmillner@redhat.com)

* Mon Aug 19 2013 Adam Miller <admiller@redhat.com> 1.13.7-1
- Added 'httpd_restart_action' function to Bash SDK (mfojtik@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #3397 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- patch upgrade.rb to use gear_map_ident for upgrade_cartridges ident
  resolution (jolamb@redhat.com)
- Bug 989225 - the logic changed so that @container_dir is always set and
  @container_plugin is nil if the container no longer exists.
  (rmillner@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.6-1
- Merge pull request #3380 from rmillner/BZ996296
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3354 from dobbymoodge/origin_runtime_219
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3373 from pmorie/bugs/997158
  (dmcphers+openshiftbot@redhat.com)
- Bug 996296 - resource_limits.conf should be mode 640. (rmillner@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Fix bug 997158: always sort cartridge versions using Manifest.sort_versions
  (pmorie@gmail.com)
- <cart version> origin_runtime_219, Update carts and manifests with new
  versions, handle version change in upgrade code
  https://trello.com/c/evcTYKdn/219-3-adjust-out-of-date-cartridge-versions
  (jolamb@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.5-1
- Upgrade tool enhancements (ironcladlou@gmail.com)

* Wed Aug 14 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- Merge pull request #3352 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3322 from smarterclayton/origin_ui_73_membership_model
  (dmcphers+openshiftbot@redhat.com)
- remove oo-cart-version Bug 980296 (dmcphers@redhat.com)
- save exposed port interfaces of a gear (rchopra@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_ui_73_membership_model (ccoleman@redhat.com)
- * Implement a membership model for OpenShift that allows an efficient query
  of user access based on each resource. * Implement scope limitations that
  correspond to specific permissions * Expose membership info via the REST API
  (disableable via config) * Allow multiple domains per user, controlled via a
  configuration flag * Support additional information per domain
  (application_count and gear_counts) to improve usability * Let domains
  support the allowed_gear_sizes option, which limits the gear sizes available
  to apps in that domain * Simplify domain update interactions - redundant
  validation removed, and behavior of responses differs slightly. * Implement
  migration script to enable data (ccoleman@redhat.com)

* Tue Aug 13 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Node Platform - Update oo-get-quota for new interface (jhonce@redhat.com)
- Bug 980820 - Ensure bogus PATH doesn't stop cartridge operations
  (jhonce@redhat.com)
- Merge pull request #3328 from fotioslindiakos/Bug995550
  (dmcphers+openshiftbot@redhat.com)
- Ensure boosted gears are not throttled (fotios@redhat.com)

* Fri Aug 09 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- Bug 995233 - Use oo_spawn in place of systemu (jhonce@redhat.com)
- Bug 903106 - Update rhcsh help to reflect gear script (jhonce@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Merge pull request #3318 from jwhonce/bug/980820
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3317 from pmorie/bugs/987155
  (dmcphers+openshiftbot@redhat.com)
- Bug 980820 - Cartridge Overriding PATH (jhonce@redhat.com)
- Bug 987155 (pmorie@gmail.com)
- Fix error message (jhonce@redhat.com)
- Card origin_runtime_175 - Report quota on 90%% usage (jhonce@redhat.com)
- Bug 991824: Make watchman logging configurable via node.conf
  (ironcladlou@gmail.com)
- Merge pull request #3243 from fotioslindiakos/Bug989782
  (dmcphers+openshiftbot@redhat.com)
- Bug 989782: Node platform should not log user sensitive login name and
  password credentials (fotios@redhat.com)
- Merge pull request #3280 from fotioslindiakos/Bug991480
  (dmcphers+openshiftbot@redhat.com)
- Handle race condition when trying to throttle gears that no longer exist
  (fotios@redhat.com)
- Bug 991225: upgrade script should be run before setup during incompatible
  upgrade (pmorie@gmail.com)
- Merge pull request #3268 from jwhonce/bug/986838
  (dmcphers+openshiftbot@redhat.com)
- Bug 986838 - Prevent quotas from being lowered beyond usage
  (jhonce@redhat.com)
- Bug 839581: Reset system_builder credentials on jenkins restore
  (ironcladlou@gmail.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.7-1
- Merge pull request #3191 from jwhonce/bug/986838
  (dmcphers+openshiftbot@redhat.com)
- Bug 986838 - Prevent quotas from being lowered beyond usage
  (jhonce@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 1.12.6-1
- Merge pull request #3242 from fotioslindiakos/Bug989706
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3239 from BanzaiMan/dev/hasari/bz989467
  (dmcphers+openshiftbot@redhat.com)
- Consolidated docs for admin/mgmt consoles, cartridges (hripps@redhat.com)
- Bug 989706: Throttler dies if no cgroups are present (fotios@redhat.com)
- Bug 989467 (asari.ruby@gmail.com)
- Adding missing activemq config templates Fixing console spec to require gems
  Additional fixes to comprehensive deployment guide (kraman@gmail.com)
- Merge pull request #3221 from fotioslindiakos/Bug989706
  (dmcphers+openshiftbot@redhat.com)
- Bug 989706: Quiet extra output from Libcgroup.usage (fotios@redhat.com)
- Merge pull request #3236 from rmillner/cgroups_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reinstate boosting certain gear operations. (rmillner@redhat.com)
- Fix bug 989695: do not reallocate existing IPs during incompatible upgrade
  (pmorie@gmail.com)
- Merge pull request #3226 from rmillner/BZ989831
  (dmcphers+openshiftbot@redhat.com)
- Bug 989831 - Fix incorrect variable. (rmillner@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.5-1
- Fix bug 981584: skip restore for secondary gear group in scalable app if
  there is no appropriate snapshot (pmorie@gmail.com)
- On Fedora, there are cgroups which return EIO instead of ENOENT.
  (rmillner@redhat.com)
- Use the newer cgroup_paths. (rmillner@redhat.com)
- Logging the spawn command was causing too much output and swamping logs.  Use
  direct access instead. (rmillner@redhat.com)
- Bug 896366 (dmcphers@redhat.com)
- Merge pull request #3198 from pmorie/bugs/952460
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 952460: add output during deploy indicating that cartridges are
  started (pmorie@gmail.com)
- Origin was not getting the /openshift cgroup created early, always try when
  enumerating parameters. (rmillner@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 1.12.4-1
- Forgot the "then" for bash. (rmillner@redhat.com)
- Merge pull request #3194 from rajatchopra/ha
  (dmcphers+openshiftbot@redhat.com)
- redo sparse cart addition/deletion as user can override their scaling factors
  (rchopra@redhat.com)
- Did not properly deal with the freeze and thaw templates.
  (rmillner@redhat.com)
- Added helper to find cgroups_paths and throttler fixes. (fotios@redhat.com)
- Add the systemd tc configuration on Origin. (rmillner@redhat.com)
- Use oo_spawn to run grep in throttler (fotios@redhat.com)
- Origin uses single quotes in config files. (rmillner@redhat.com)
- Make throttling values configurable, and fixes. (fotios@redhat.com)
- Cgroup module unit tests and bug fixes. (rmillner@redhat.com)
- Reworked throttler code to work with new cgroups (fotios@redhat.com)
- Separate out libcgroup based functionality and add configurable templates.
  (rmillner@redhat.com)
- Add template and throttler support to cgroups (fotios@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Bug 985035: Add missing requires to frontend_httpd (ironcladlou@gmail.com)
- Merge pull request #3175 from pmorie/dev/upgrade_endpoints
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3173 from rmillner/BZ988519
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3172 from ironcladlou/bz/987836
  (dmcphers+openshiftbot@redhat.com)
- Add endpoint handling to upgrades (pmorie@gmail.com)
- Bug 988519 - Ensure that the gear task runs as unconfined_u.
  (rmillner@redhat.com)
- Bug 987836: Refactor hot deploy marker detection (ironcladlou@gmail.com)
- Merge pull request #3170 from pmorie/dev/upgrade_analysis
  (dmcphers+openshiftbot@redhat.com)
- Upgrade enhancements (ironcladlou@gmail.com)
- Merge pull request #3160 from pravisankar/dev/ravi/card78
  (dmcphers+openshiftbot@redhat.com)
- For consistency, rest api response must display 'delete' instead 'destroy'
  for user/domain/app (rpenta@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- spelling fix (dmcphers@redhat.com)
- Double protect URL arguments in gear (users can't break gear deployment)
  (ccoleman@redhat.com)
- Merge pull request #3090 from BanzaiMan/writing_cart_doc
  (dmcphers+openshiftbot@redhat.com)
- Bug 907410 (dmcphers@redhat.com)
- Bug 907410 (dmcphers@redhat.com)
- Bug 983923 - Add "-h" as an argument to get help. (rmillner@redhat.com)
- Merge pull request #3119 from kraman/bugs/984575
  (dmcphers+openshiftbot@redhat.com)
- Minor tweak in wording (asari.ruby@gmail.com)
- Add sections for readability (asari.ruby@gmail.com)
- A typo (asari.ruby@gmail.com)
- Application's action hooks follow the same semantics as cartridge control
  scripts (asari.ruby@gmail.com)
- Add Windows-friendly instructions (asari.ruby@gmail.com)
- Remove recursive requires node -> container plugin -> node
  https://bugzilla.redhat.com/show_bug.cgi?id=984575 (kraman@gmail.com)
- Mention chmod. (asari.ruby@gmail.com)
- Mention EOL chacacters (asari.ruby@gmail.com)
- bin/* needs to be executable (asari.ruby@gmail.com)
- process_templates need to be String literals (asari.ruby@gmail.com)
- Add version check for gear upgrade extension (pmorie@gmail.com)
- Add error handling to AppContainer plugin loading (pmorie@gmail.com)
- WIP: configure containerization plugin in node.conf (pmorie@gmail.com)
- Merge pull request #3099 from ironcladlou/dev/node-fixes
  (dmcphers+openshiftbot@redhat.com)
- Use oo_spawn for all root scoped shell commands (ironcladlou@gmail.com)
- Bug 984609 - fix a narrow condition where sshd leaves a root owned process in
  the frozen gear cgroup causing gear delete to fail and stale processes/
  (rmillner@redhat.com)
- Add support for upgrade script to be called during cartridge upgrades.
  (pmorie@gmail.com)
- Making assert_repo_reset test more resilient to git versions.
  (kraman@gmail.com)
- remove initial build from cgroups limits (dmcphers@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- Merge pull request #3077 from rmillner/cgfixes
  (dmcphers+openshiftbot@redhat.com)
- Add support to pam enable/disable command to run across all gears.
  (rmillner@redhat.com)
- bump_minor_versions for sprint 31 (admiller@redhat.com)
- The mutex needs to be a global that is instantiated early in order to work in
  all contexts. (rmillner@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.11.9-1
- Add pam control scripts. (rmillner@redhat.com)
- Merge pull request #3071 from ironcladlou/oo-state-show-fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3066 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Fix syntax error in oo-app-state-show (ironcladlou@gmail.com)
- Merge pull request #3067 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 983583: remove gear validation step for compatible upgrades
  (pmorie@gmail.com)
- Switch test to use anonymous git url instead of git@ which requires a valid
  ssh key to clone (kraman@gmail.com)
- Merge pull request #3061 from pmorie/dev/upgrades
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 983583 (pmorie@gmail.com)
- Ignore STDERR while checking for 'scl' (asari.ruby@gmail.com)
- Bug 983190 (asari.ruby@gmail.com)
- Merge pull request #3056 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Bugfix #983308 (kraman@gmail.com)
- Merge pull request #2979 from jwhonce/bug/980253
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3040 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Bug 980253 - Validate version numbers from manifest (jhonce@redhat.com)
- Fix ApplicationStateFunctionalTest for F19 so that it creates test user in
  /var/tmp-tests instead of /tmp. This avoids any poly-instantiated /tmp
  errors. (kraman@gmail.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.8-1
- Merge pull request #3051 from pmorie/bugs/981622
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3048 from BanzaiMan/cartridge_doc_update
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 981622 (pmorie@gmail.com)
- Document pre-repo-archive in the build lifecycle (asari.ruby@gmail.com)
- Removing extra lsof dependency (bleanhar@redhat.com)
- Merge pull request #3034 from fotioslindiakos/BZ913809
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3033 from BanzaiMan/dev/hasari/bz974983
  (dmcphers+openshiftbot@redhat.com)
- Bug 913809 - Proper psql error handling (fotios@redhat.com)
- Merge pull request #3032 from kraman/missing_cgroups
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3030 from rmillner/BZ980497
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3024 from abhgupta/bug_980760
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3022 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Bug 974983 (asari.ruby@gmail.com)
- Fix config variable parsing. Split on comma before use of variable as array
  (kraman@gmail.com)
- Screen out cgroups variables that are missing on the system.
  (rmillner@redhat.com)
- Bug 980497 - Optimize these calls to oo-get-mcs-level. (rmillner@redhat.com)
- Fix for bug 980760  - Preventing multiple versions of a cartridge from being
  added to the application (abhgupta@redhat.com)
- Fix gear env loading by using ApplicationContainer::from_uuid instead of
  ApplicationContainer::new (kraman@gmail.com)
- Updates to allow basic tests to pass on F19 (kraman@gmail.com)
- Merge pull request #3016 from pmorie/dev/fix_tests
  (dmcphers+openshiftbot@redhat.com)
- Fix upgrade functionality and associated tests (pmorie@gmail.com)

* Tue Jul 09 2013 Adam Miller <admiller@redhat.com> 1.11.7-1
- Bug 982403 - Work around contexts where gear environment is incomplete.
  (rmillner@redhat.com)
- Bug 981037 - Use an O(1) generator for the common use case.
  (rmillner@redhat.com)
- Bug 981022 - only load the parts of common that are needed.
  (rmillner@redhat.com)
- Bug 981594 - ApplicationContainer used as an argument needed full module
  paths. (rmillner@redhat.com)
- Merge pull request #3011 from kraman/bugfix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3010 from pravisankar/dev/ravi/bug982172
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3001 from rmillner/pam_rewrite
  (dmcphers+openshiftbot@redhat.com)
- Fixing module path for FileLockError (kraman@gmail.com)
- Making module resolution for UserCreationException and UserDeletionException
  explicit (kraman@gmail.com)
- Make resolution for Utils module explicit (kraman@gmail.com)
- Bug 980841 - Need to pass 'container' instead of 'uuid' for ApplicationState
  constructor (rpenta@redhat.com)
- Had missed that we were setting nproc as a soft value except for freeze.
  Order of applying defaults was backwards. (rmillner@redhat.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 1.11.6-1
- Merge pull request #2992 from brenton/BZ981249
  (dmcphers+openshiftbot@redhat.com)
-  Revamp the cgroups and pam scripts to leverage the system setup for better
  performance and simplify the code. (rmillner@redhat.com)
- Bug 981249 - rubygem-openshift-origin-node was missing open4 dependency
  (bleanhar@redhat.com)

* Fri Jul 05 2013 Adam Miller <admiller@redhat.com> 1.11.5-1
- Merge pull request #2987 from rajatchopra/routing_broker
  (dmcphers+openshiftbot@redhat.com)
- Routing plug-in for broker. Code base from github/miciah/broker-plugin-
  routing-activemq (miciah.masters@gmail.com)

* Wed Jul 03 2013 Adam Miller <admiller@redhat.com> 1.11.4-1
- Merge pull request #2980 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- moving sync into the sdk (dmcphers@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- Merge pull request #2934 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Fixing class/module namespaces Fixing tests Fixing rebase errors Un-hardcode
  context in step_definitions/cartridge-php_steps.rb Fixing paths that were
  broken when going from File.join -> PathUtils.join (kraman@gmail.com)
- Adding traffic control for selinux container (kraman@gmail.com)
- Renamed package to Containerization instead of ApplicationContainerPlugin
  Renamed OpenShift_ApplicationContainer_Class to container_plugin_class and
  made it a class variable instead of global Moved run_in_root_context to
  ApplicationContainer since it is not implementation specific Cleanup unused
  variables (kraman@gmail.com)
- Changing File.join to PathUtils.join in node and common packages Uncommenting
  cgroups Fixing signal handling in oo-gear-init (kraman@gmail.com)
- Fixing tests (assuming selinux container for now) (kraman@gmail.com)
- Make port-forwarding container specific.   * SELinux container uses port-
  proxy   * Libvirt container uses IP Tables (kraman@gmail.com)
- Moving selinux and libvirt container plugins into seperate gem files Added
  nsjoin which allows joining a running container Temporarily disabled cgroups
  Moved gear dir to /var/lib/openshift/gears for libvirt container Moved shell
  definition into container plugin rather than application container
  (kraman@gmail.com)
- Explicitly create a group for the gear user and fail if group cannot be
  created. (kraman@gmail.com)
- Refactor code to use run_in_container_context/run_in_root_context calls
  instead of generically calling oo_spawn and passing uid. Modify frontend
  httpd/proxy classes to accept a container object instead of indivigual
  properties (kraman@gmail.com)
- Refactor code to call set_ro_permission/set_rw_permission instead of calling
  chown/chcon (kraman@gmail.com)
- Moving Node classes into Runtime namespace Removing UnixUser Moving
  functionality into SELinux plugin class (kraman@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Merge pull request #2925 from BanzaiMan/dev/hasari/c157
  (dmcphers+openshiftbot@redhat.com)
- Add gear-level upgrade extensions (pmorie@gmail.com)
- Card online_runtime_157 (asari.ruby@gmail.com)
- Bug 977034 - Removing IDENT breaks destroy (jhonce@redhat.com)
- Bug 977034 - Removing IDENT breaks deconfigure (jhonce@redhat.com)
- Merge pull request #2927 from smarterclayton/bug_970257_support_git_at_urls
  (dmcphers+openshiftbot@redhat.com)
- Rename migrate to upgrade in code (pmorie@gmail.com)
- Merge pull request #2958 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove v2 folder from cart install (dmcphers@redhat.com)
- Bug 977493 - Avoid leaking the lock file descriptor to child processes.
  (rmillner@redhat.com)
- Merge pull request #2827 from genesarm/PULL_2005
  (dmcphers+openshiftbot@redhat.com)
- Move core migration into origin-server (pmorie@gmail.com)
- Merge pull request #2951 from BanzaiMan/mocha_deprecation_warning
  (dmcphers@redhat.com)
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
- Merge pull request #2865 from BanzaiMan/dev/hasari/bz974632
  (dmcphers+openshiftbot@redhat.com)
- Adding lsof dependency (kraman@gmail.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Merge pull request #2928 from BanzaiMan/dev/hasari/bz971622
  (dmcphers+openshiftbot@redhat.com)
- PULL_2005 Changed GEAR_SUPL_GRPS to GEAR_SUPPLEMENTARY_GROUPS in node and
  tests (gsarmien@redhat.com)
- Clean up the assertion (asari.ruby@gmail.com)
- Test recursive case, too. (asari.ruby@gmail.com)
- Generalize the file filtering somewhat (asari.ruby@gmail.com)
- Process dot files, too. (asari.ruby@gmail.com)
- Bug 976112 (asari.ruby@gmail.com)
- Remove V1 code and V2-specific stepdefs (pmorie@gmail.com)
- Merge remote-tracking branch 'origin/master' into
  bug_970257_support_git_at_urls (ccoleman@redhat.com)
- Allow clients to pass an initial_git_url of "empty", which creates a bare
  repo but does not add a commit.  When 'empty' is passed, the node will skip
  starting the gear and also skip the initial build.  This allows clients that
  want to send a local Git repository (one that isn't visible to OpenShift.com,
  for example) to avoid having to push/merge/delete the initial commit, and
  instead submit their own clean repo.  In this case, the user will get a
  result indicating that their repository is empty. (ccoleman@redhat.com)
- Merge pull request #2931 from jwhonce/card/163
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_163 - Validate attempted Gear env var overrides
  (jhonce@redhat.com)
- Bug 970257 - Allow git@ urls (ccoleman@redhat.com)
- removing v1 logic (dmcphers@redhat.com)
- Bug 974983 (asari.ruby@gmail.com)
- Bug 974632 (asari.ruby@gmail.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Thu Jun 20 2013 Adam Miller <admiller@redhat.com> 1.10.5-1
- Bug 976173 - oo-* scripts fail on node with ruby LoadError
  (bleanhar@redhat.com)
- Bug 975700 - check the httpd pid file for corruption and attempt to fix it.
  (rmillner@redhat.com)
- Merge pull request #2903 from ironcladlou/bz/974786
  (dmcphers+openshiftbot@redhat.com)
- Bug 974786: Scaled gear hot deploy logic fix (ironcladlou@gmail.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 1.10.4-1
- Hook documentation updates (ironcladlou@gmail.com)
- Merge pull request #2894 from jwhonce/bug/975183
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2892 from jwhonce/bug/975611
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2890 from ironcladlou/dev/push-profiling
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2886 from pmorie/bugs/975349
  (dmcphers+openshiftbot@redhat.com)
- Bug 975183 -  nested submodule repository cannot be found (jhonce@redhat.com)
- Merge pull request #2884 from fotioslindiakos/BZ975108
  (dmcphers+openshiftbot@redhat.com)
- Bug 975611 - Remove cgroup cpu limit during un-idle (jhonce@redhat.com)
- Optimize gear script for ~50%% Git push overhead reduction
  (ironcladlou@gmail.com)
- Fix bug 975349: always use manifest passed to rhc for downloadable cartridges
  (pmorie@gmail.com)
- Always display message when do_command fails (fotios@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Merge pull request #2878 from pmorie/bugs/975034
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 975034: remove validation for control script executability
  (pmorie@gmail.com)
- Merge pull request #2867 from rmillner/misc_bugs
  (dmcphers+openshiftbot@redhat.com)
- Bug 974268 - Narrow the window where user and quota data can get out of sync
  and set the start time prior to any other collection.  Deal with a race
  condition with the lock files in unix_user. (rmillner@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Merge pull request #2805 from BanzaiMan/dev/hasari/bz972757
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2830 from mrunalp/bugs/972356
  (dmcphers+openshiftbot@redhat.com)
- Make sure we call the hooks on the correct cartridge by reading ident from
  the cartridge_dir (mrunalp@gmail.com)
- Fix typo in gear script (pmorie@gmail.com)
- Merge pull request #2819 from pmorie/dev/cart-repo
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2818 from rmillner/misc_bugs
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 973351: Add CartridgeRepository.latest_versions for use in rhc
  cartridge list (pmorie@gmail.com)
- Bug 972977 - /var/tmp is also polyinstantiated and restorecon was giving
  errors about the old directory. (rmillner@redhat.com)
- Devenv, Hosted and Origin already add pam_cgroup to sshd via their own
  methods along with other edits to those files.  Duplicating this in node.spec
  just adds confusion. (rmillner@redhat.com)
- Bug 972757: Allow vendor names to start with a numeral (asari.ruby@gmail.com)
- Node timeout handling improvements (ironcladlou@gmail.com)
- Bug 971460 - Refactor path_append/prepend to accept multiple elements
  (jhonce@redhat.com)
- Use diy instead of php since php-5.3 is not available on all platforms
  (kraman@gmail.com)
- Create test dir under /data instead of /tmp. /tmp is bind mounted and tests
  fail if homedir is kept under there. (kraman@gmail.com)
- Node fixes where uid is being used instead of gid to set permission. Update
  shell exec to preserve environment when invoking runuser. (kraman@gmail.com)
- Merge pull request #2762 from pmorie/dev/typo
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2752 from detiber/fixShellExecFuncTest
  (dmcphers+openshiftbot@redhat.com)
- Fix typo in v2_cart_model#stop_cartridge (pmorie@gmail.com)
- Merge pull request #2754 from rmillner/BZ970792
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2753 from ironcladlou/bz/969937
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2751 from pmorie/bugs/969828
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2750 from mrunalp/dev/ssl_to_gear
  (dmcphers+openshiftbot@redhat.com)
- Bug 970792 - The SSLVerifyClient stanza causes browser popups.
  (rmillner@redhat.com)
- Bug 969937: Implement gear script deploy method (ironcladlou@gmail.com)
- Fix bug 969828 (pmorie@gmail.com)
- Add ssl_to_gear option. (mrunalp@gmail.com)
- origin_runtime_137 - FrontendHttpServer accepts "target_update" option which
  causes it to read the old options for a connection and just update the
  target. (rmillner@redhat.com)
- <node tests> - Update shell_exec_func_test to create homedir in /var/tmp
  (jdetiber@redhat.com)
- Merge pull request #2735 from pmorie/bugs/969605
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 969605 (pmorie@gmail.com)
- Make NodeLogger pluggable (ironcladlou@gmail.com)
- Fix bug 969605 (pmorie@gmail.com)
- Bug 969725: Ensure cleanup on cartridge deconfigure (ironcladlou@gmail.com)
- Merge pull request #2724 from jwhonce/bug/969599
  (dmcphers+openshiftbot@redhat.com)
- Bug 969599 - selinux policy unnecessarily applied (jhonce@redhat.com)
- Do not default to stauts if gear script is invoked without an invalid
  command. (pmorie@gmail.com)
- Merge pull request #2700 from rmillner/sync_more
  (dmcphers+openshiftbot@redhat.com)
- Unit tests mock File object needed to know about the fsync call.
  (rmillner@redhat.com)
- Bug 969112 - RFC 1121 (sect 2.1) specifies that a host name must start with a
  letter or number. (rmillner@redhat.com)
- Force sync to disk prior to renaming the file for additional safety.
  (rmillner@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.10-1
- Merge pull request #2694 from pmorie/dev/v2_switchyard
  (dmcphers+openshiftbot@redhat.com)
- Add V2 tests for switchyard (pmorie@gmail.com)
- Merge pull request #2688 from mrunalp/dev/idler
  (dmcphers+openshiftbot@redhat.com)
- Auto Idler (mrunalp@gmail.com)
- Merge pull request #2680 from ironcladlou/bz/968228
  (dmcphers+openshiftbot@redhat.com)
- Update README.writing_cartridges.md (ccoleman@redhat.com)
- Update README.writing_cartridges.md (ccoleman@redhat.com)
- Bug 968228: Report analytics on build post-receive (ironcladlou@gmail.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 1.9.9-1
- Merge pull request #2640 from dobbymoodge/oo-admin-ctl-cgroups-debug
  (dmcphers+openshiftbot@redhat.com)
- <oo-admin-ctl-cgroups> Bug 964205 - amend comments for cgroup_exists function
  (jolamb@redhat.com)
- Bug 967118 - Immutable files in cartridges (jhonce@redhat.com)
- Merge pull request #2660 from ironcladlou/dev/v2carts/cucumber
  (dmcphers+openshiftbot@redhat.com)
- Fix client message translation function and add tests (ironcladlou@gmail.com)
- <oo-admin-ctl-groups> Bug 964205 - fix set_blkio function comment to be more
  accurate (jolamb@redhat.com)
- <oo-admin-ctl-cgroups> Bug 964205 - prevent stopping already stopped cgroups
  (jolamb@redhat.com)
- <oo-admin-ctl-cgroups> Bug 964205 - add "repair" command (jolamb@redhat.com)
- <oo-admin-ctl-cgroups> Fix return value handling, code fixes/refactoring
  (jolamb@redhat.com)
- <oo-admin-ctl-groups> Fix typos in echo statements (jolamb@redhat.com)
- <oo-admin-ctl-cgroups> whitespace fixes (jolamb@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.9.8-1
- WIP Cartridge Refactor - Updated Guide (jhonce@redhat.com)
- Various cleanup (dmcphers@redhat.com)
- Merge pull request #2642 from jwhonce/bug/967118
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2641 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Bug 967118 - Make Platform/Cartridge shared files immutable
  (jhonce@redhat.com)
- Merge pull request #2636 from ironcladlou/bz/967016
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2637 from jwhonce/wip/oo-trap-user
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2629 from ironcladlou/bz/966790
  (dmcphers+openshiftbot@redhat.com)
- Replace pre-receive cart control action with pre-repo-archive
  (ironcladlou@gmail.com)
- Bug 967016: Detect v2 carts in a gear more accurately (ironcladlou@gmail.com)
- WIP Cartridge Refactor - remove extraneous syslog messages
  (jhonce@redhat.com)
- Bug 966790: Handle unidling consistently in the cart model
  (ironcladlou@gmail.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.9.7-1
- Merge pull request #2633 from ironcladlou/bz/967017
  (dmcphers+openshiftbot@redhat.com)
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- Bug 965757: Provide output to client on post-configure failure
  (ironcladlou@gmail.com)
- Flatten args to disconnect like the args to connect so that it can be used
  the same way. (rmillner@redhat.com)
- Merge pull request #2627 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)
- Bug 966758 - Disconnect frontend mappings when removing catridge
  (jhonce@redhat.com)
- Don't remove files while the app is still running before the user is
  destroyed. (dmcphers@redhat.com)
- Merge pull request #2612 from jwhonce/bug/964347
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2583 from Miciah/drop-todo-for-v2-switchover
  (dmcphers+openshiftbot@redhat.com)
- Bug 964347 - Run cartridge scripts from cartridge home directory
  (jhonce@redhat.com)
- Delete old TODOs related to v2 switchover (miciah.masters@gmail.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 1.9.6-1
- Merge pull request #2603 from fotioslindiakos/Bug959476
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2601 from ironcladlou/bz/964002
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2600 from mrunalp/bugs/966068
  (dmcphers+openshiftbot@redhat.com)
- Bug 959476: Ensure psql uses the correct .psql_history location
  (fotios@redhat.com)
- Bug 964002: Support hot deployment in scalable apps (ironcladlou@gmail.com)
- Add force-reload functionality. (mrunalp@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.5-1
- Merge pull request #2594 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Modify NodeLogger to use a format consistent with rsyslog
  (calfonso@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.9.4-1
- WIP Cartridge Refactor - Improved error handling (jhonce@redhat.com)
- Merge pull request #2585 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2584 from jwhonce/bug/965364
  (dmcphers+openshiftbot@redhat.com)
- get submodules working in all cases (dmcphers@redhat.com)
- Bug 965364 - ApplicationRepository#deploy assumed template application
  existed (jhonce@redhat.com)
- Merge pull request #2580 from jwhonce/bug/965537
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2578 from ironcladlou/bz/965028
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2577 from mrunalp/dev/safe_yaml
  (dmcphers+openshiftbot@redhat.com)
- Bug 965537 - Dynamically build PassEnv httpd configuration
  (jhonce@redhat.com)
- Merge pull request #2574 from rmillner/BZ965317
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2573 from pmorie/bugs/965357
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2555 from brenton/shell_exec_func_test1
  (dmcphers+openshiftbot@redhat.com)
- Bug 965028: Increase connector timeout (ironcladlou@gmail.com)
- Add safe yaml parsing to node. (mrunalp@gmail.com)
- Bug 965317 - The mutexes must be created as globals which evaluate ahead of
  any multithreaded operations. (rmillner@redhat.com)
- Fix bug 965357: add guard against export in PATH in rhcsh (pmorie@gmail.com)
- Bug 962673 (dmcphers@redhat.com)
- Merge pull request #2566 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2561 from jwhonce/wip/v2v2_migration
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2558 from ironcladlou/bz/965236
  (dmcphers+openshiftbot@redhat.com)
- Improve error messages (dmcphers@redhat.com)
- WIP Cartridge Refactor - V2 -> V2 Migration (jhonce@redhat.com)
- Bug 965236: Restrict endpoint mappings to default route
  (ironcladlou@gmail.com)
- Test fix for shell_exec_func_test.rb (bleanhar@redhat.com)
- The update namespace functionality was removed.  Removing the supporting
  functions that only serviced that function. (rmillner@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.9.3-1
- WIP Cartridge Refactor - Update documentation (jhonce@redhat.com)
- WIP Cartridge Refactor - V2 -> V2 Migration (jhonce@redhat.com)
- Merge pull request #2543 from rmillner/BZ957257
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2539 from ironcladlou/bz/963646
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2535 from abhgupta/abhgupta_dev_2
  (dmcphers+openshiftbot@redhat.com)
- Bug 957257 - add login message about running tidy. (rmillner@redhat.com)
- Merge pull request #2533 from ironcladlou/bz/964265
  (dmcphers+openshiftbot@redhat.com)
- Bug 963646: Quote env var contents to avoid undesirable array evals
  (ironcladlou@gmail.com)
- Preventing failures in deletion of partially created gears
  (abhgupta@redhat.com)
- online_runtime_296 - Change the nproc limit to soft per request but still
  allow gear teardown to set a hard limit of 0 (rmillner@redhat.com)
- Bug 964265: Ignore symlinks when detecting cart dirs in a gear
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Allow CartridgeRepository#instantiate_cartridge
  overlay existing cartridge (jhonce@redhat.com)
- Merge pull request #2528 from pmorie/bugs/963286
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 963286: remove uservars from v2 (pmorie@gmail.com)
- Bug 961785 - Cartridge URL install failed (jhonce@redhat.com)
- Merge pull request #2520 from jwhonce/wip/rm_post_setup
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2518 from ironcladlou/bz/963637
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - remove post-setup support (jhonce@redhat.com)
- Remove defunct test (ironcladlou@gmail.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- Sorting the rubygem-openshift-origin-node deps (bleanhar@redhat.com)
- Bug 963593 - rubygem-openshift-origin-node depends on git
  (bleanhar@redhat.com)
- Merge pull request #2503 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2501 from ironcladlou/dev/v2carts/gearscript
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2491 from ironcladlou/dev/v2carts/private-endpoints-fix
  (dmcphers+openshiftbot@redhat.com)
- process-version -> update-configuration (dmcphers@redhat.com)
- Add trace option to gear script for nicer error messages
  (ironcladlou@gmail.com)
- Bug 963156 (dmcphers@redhat.com)
- Merge pull request #2485 from dobbymoodge/BZ962938-broker-proxytimeout
  (dmcphers+openshiftbot@redhat.com)
- Escape early from endpoint creation when there are none to create
  (ironcladlou@gmail.com)
- <node/httpd conf> Bug 962938 - Set ProxyTimeout for node HTTPD config
  (jolamb@redhat.com)
- <rubygem-openshift-origin-node spec file> Bug 963336 - Add 'Requires' of
  mod_ssl to fix httpd failing to start on node servers due to missing ssl
  module required by 000001_openshift_origin_node.conf (tbielawa@redhat.com)
- fixup tests (dmcphers@redhat.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Merge pull request #2454 from fotioslindiakos/locked_files
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 962934 (pmorie@gmail.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Fix problem in v2_cart_model_test that invalidates accept-node
  (pmorie@gmail.com)
- Fix bug 958977 (pmorie@gmail.com)
- Merge pull request #2452 from jwhonce/bug/960525
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2451 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2426 from abhgupta/abhgupta-dev
  (dmcphers+openshiftbot@redhat.com)
- Bug 960525 - Improve error message display (jhonce@redhat.com)
- Disabling v1 operations when in v2 mode (dmcphers@redhat.com)
- Add unit test coverage for v2_cart_model#unlock_gear (pmorie@gmail.com)
- Switching v2 to be the default (dmcphers@redhat.com)
- Merge pull request #2431 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2108 from getupcloud/patch-1
  (dmcphers+openshiftbot@redhat.com)
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)
- Adding a rewrite to allow X-OpenShift-Host override the HTTP_HOST
  (calfonso@redhat.com)
- WIP Cartridge Refactor - Fixed PATH when using mutliple cartridges
  (jhonce@redhat.com)
- Passing down X-Forwarded-Port (getup@getupcloud.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.9-1
- Merge pull request #2392 from BanzaiMan/dev/hasari/bz959843
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2390 from ironcladlou/bz/958694
  (dmcphers+openshiftbot@redhat.com)
- Do not validate vendor and cartridge names when instantiating Manifest from
  filesystem. (asari.ruby@gmail.com)
- Merge pull request #2379 from fotioslindiakos/Bug959123
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2381 from BanzaiMan/dev/hasari/bz960364
  (dmcphers+openshiftbot@redhat.com)
- Bug 958694: Make .state gear scoped and refactor primary cart concept
  (ironcladlou@gmail.com)
- Bug 959123: Fix Postgresql snapshot restore (fotios@redhat.com)
- Merge pull request #2377 from smarterclayton/fix_cart_messaging
  (dmcphers+openshiftbot@redhat.com)
- Bug 960364 (asari.ruby@gmail.com)
- Merge pull request #2378 from pmorie/bugs/960675
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2376 from ironcladlou/bz/960356
  (dmcphers+openshiftbot@redhat.com)
- Adjust the naming of downloaded cartridges to match decisions
  (ccoleman@redhat.com)
- Fix bug 960675 (pmorie@gmail.com)
- Bug 960356: Make platform log permissions consistent with broker logs
  (ironcladlou@gmail.com)
- Merge pull request #2374 from BanzaiMan/dev/hasari/reserved_cartridge_names
  (dmcphers+openshiftbot@redhat.com)
- Bug 960375: restrict vendor and cartridge names to 32 characters.
  (asari.ruby@gmail.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 1.8.8-1
- Merge pull request #2364 from BanzaiMan/dev/hasari/reserved_cartridge_names
  (dmcphers@redhat.com)
- Do not try to unlock gear after destroy (fotios@redhat.com)
- Check cartridge name for reserved names ('app-root', 'git')
  (asari.ruby@gmail.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 1.8.7-1
- Merge pull request #2357 from pmorie/bugs/951405
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - restore test (jhonce@redhat.com)
- Remove broken test to fix (jhonce@redhat.com)
- WIP Cartridge Refactor - Install cartridges without mco client
  (jhonce@redhat.com)
- Merge pull request #2348 from abhgupta/bug_959178
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2339 from fotioslindiakos/locked_files
  (dmcphers@redhat.com)
- Updates to README for managed_files.yml (fotios@redhat.com)
- Fix for bug 959178 (abhgupta@redhat.com)
- Fix bug 951405 (pmorie@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Ensure cart doesn't try to do_lock on deconfigure (fotios@redhat.com)
- Ensure that lock_files entries have the proper trailing slash and updated
  test for it (fotios@redhat.com)
- Uncommenting out tests (fotios@redhat.com)
- Ensure paths with slashes are tested (fotios@redhat.com)
- Ensure root contains a slash (fotios@redhat.com)
- Fix testS (fotios@redhat.com)
- Add root for all calls of managed_files functions (fotios@redhat.com)
- Use managed_files version of restore_transforms (fotios@redhat.com)
- Fix paths being returned with leading slash (fotios@redhat.com)
- fix tests (dmcphers@redhat.com)
- Fixed missing managed_files.yml (fotios@redhat.com)
- Commented out failing tests (fotios@redhat.com)
- Special file processing (fotios@redhat.com)
- Bugs 958709, 958744, 958757 (dmcphers@redhat.com)
- Using post-configure to deploy quickstarts for v1 (dmcphers@redhat.com)
- Merge pull request #2333 from ironcladlou/bz/949232
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2322 from rmillner/ctl_gears
  (dmcphers+openshiftbot@redhat.com)
- Bug 949232: Make rhc-list-port compatible with both v1/v2 cartridges
  (ironcladlou@gmail.com)
- Bug 957453 - The v2 builder needs to do a complete unidle.
  (rmillner@redhat.com)
- Validate cartridge and vendor names under certain conditions
  (asari.ruby@gmail.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Merge pull request #2232 from smarterclayton/support_external_cartridges
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2318 from mrunalp/dev/web_proxy_remote_deploy
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into support_external_cartridges
  (ccoleman@redhat.com)
- Rename "external cartridge" to "downloaded cartridge".  UI should call them
  "personal" cartridges (ccoleman@redhat.com)
- Add init option to remote deploy. (mrunalp@gmail.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- fixed node test to include new cartridge attributes Versions and Cartridge-
  Vendor (lnader@redhat.com)
- Merge pull request #2293 from ironcladlou/dev/v2carts/cartridge-common
  (dmcphers+openshiftbot@redhat.com)
- Move Runtime::Cartridge to openshift-origin-common (ironcladlou@gmail.com)
- Card online_runtime_266 - Support for LD_LIBRARY_PATH (jhonce@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.8.3-1
- Merge pull request #2283 from rmillner/BZ957883
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2280 from mrunalp/dev/auto_env_vars
  (dmcphers+openshiftbot@redhat.com)
- Bug 957883 - git clone was getting stuck asking for a password in remote
  repository and no amount of redirecting or closing stdin prevented a
  deadlock. (rmillner@redhat.com)
- Merge pull request #2276 from ironcladlou/bz/956967
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2277 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2275 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2274 from rmillner/v2_misc_fixes
  (dmcphers+openshiftbot@redhat.com)
- Bug 956964: Collect teardown output on cart deconfigure
  (ironcladlou@gmail.com)
- minor fixes (dmcphers@redhat.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Fix v2 model unit tests. (rmillner@redhat.com)
- origin_runtime_127: Add X-Request-Start header. (rmillner@redhat.com)
- Bug 957257 - use an internal function to get the MCS label.
  (rmillner@redhat.com)
- The teardown hook needs gear unlock. (rmillner@redhat.com)
- Make this call less chatty. (rmillner@redhat.com)
- Card online_runtime_266 - Renamed OPENSHIFT_<short name>_PATH to
  OPENSHIFT_<short name>_PATH_ELEMENT (jhonce@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- Merge pull request #2267 from jwhonce/bug/957095
  (dmcphers+openshiftbot@redhat.com)
- Bug 957095 - V2 support in rhcsh broke USER_VARS (jhonce@redhat.com)
- Card online_runtime_239 - Remove env required directory (jhonce@redhat.com)
- Merge pull request #2255 from brenton/oo-accept-systems
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_239 - Download cartridge from URL (jhonce@redhat.com)
- Card online_runtime_287 - Bug fix (jhonce@redhat.com)
- Merge pull request #2251 from pmorie/dev/v1_stop_lock
  (dmcphers+openshiftbot@redhat.com)
- Bug 957045 - fixing oo-accept-systems for v2 cartridges (bleanhar@redhat.com)
- Fix issues w/ V1 stop lock (pmorie@gmail.com)
- Add process-version control action (ironcladlou@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #2249 from rmillner/online_runtime_264
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2245 from rmillner/v2_namespace
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2248 from mrunalp/bug/haproxy_fixes
  (dmcphers+openshiftbot@redhat.com)
- Add health check option to front-end for v2 carts. (rmillner@redhat.com)
- The sandbox directory is owned by the gear user in v2. (rmillner@redhat.com)
- Move haproxy shared scripts into /usr/bin. (mrunalp@gmail.com)
- Add a class for accessing cgroups parameters for a gear and reproduce the v1
  behavior. (rmillner@redhat.com)
- Merge pull request #2228 from jwhonce/wip/card287
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2211 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Missed a step in teardown (jhonce@redhat.com)
- Card online_runtime_287 - Add cartridge/usr/template locations
  (jhonce@redhat.com)
- Merge pull request #2225 from rmillner/BZ928621
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2223 from ironcladlou/bz/955463
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_266 - Fix issue with cartridge overrides
  (jhonce@redhat.com)
- Card online_runtime_266 - Build PATH from
  CARTRIDGE_<CARTRIDGE_SHORT_NAME>_PATH (jhonce@redhat.com)
- Merge pull request #2227 from ironcladlou/bz/955538
  (dmcphers+openshiftbot@redhat.com)
- Bug 928621 - needed more information on why the flow does what it does.
  (rmillner@redhat.com)
- Bug 955463: Move hot deploy logic into the v2 model (ironcladlou@gmail.com)
- Merge pull request #2214 from rmillner/TC222
  (dmcphers+openshiftbot@redhat.com)
- Combine stderr/stdout for cartridge actions (ironcladlou@gmail.com)
- Postgres V2 fixes (fotios@redhat.com)
- Feature complete v2 oo-admin-ctl-gears script with integrated idler.
  (rmillner@redhat.com)
- Switch back to native SELinux calls. (rmillner@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- updating cart guide with install/post-install/post-setup
  (dmcphers@redhat.com)
- Adding install/post-setup/post-install (dmcphers@redhat.com)
- Merge pull request #2204 from pmorie/dev/env_var
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2208 from ironcladlou/dev/v2carts/post-configure
  (dmcphers+openshiftbot@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- Write namespace/primary cart dir correctly for v2 (pmorie@gmail.com)
- running oo-cartridge-list stacktrace without any v2 cartridges
  (calfonso@redhat.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2187 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2189 from rmillner/accept-node
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2188 from ironcladlou/dev/v2carts/hot-deploy
  (dmcphers+openshiftbot@redhat.com)
- Adding install and post setup steps (dmcphers@redhat.com)
- Resolve fqdn to uuid when reporting frontend issues and check the selinux
  context of mcollective. (rmillner@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Merge pull request #2183 from jwhonce/wip/raw_envvar
  (dmcphers+openshiftbot@redhat.com)
- Bug 954317 - rhcsh test for V1 vs V2 failed (jhonce@redhat.com)
- Merge pull request #2062 from Miciah/move-plugins.d-README-from-node-to-
  broker (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Update extended tests for raw environment variables
  (jhonce@redhat.com)
- Merge pull request #2174 from mscherer/patch-1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2171 from mscherer/fix/doc_cartridge_syntax
  (dmcphers+openshiftbot@redhat.com)
- Fix typo on miscategorized (misc@zarb.org)
- fix inclusion of the example manifest (misc@zarb.org)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Clean up test executions (ironcladlou@gmail.com)
- Merge pull request #2159 from ironcladlou/bz/953401
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2094 from BanzaiMan/dev/hasari/bz928675
  (dmcphers@redhat.com)
- Bug 953401: Run v1 tidy in the correct user context (ironcladlou@gmail.com)
- Merge pull request #2157 from mrunalp/dev/websocket_port
  (dmcphers+openshiftbot@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Add support for specifying websocket port in the manifest.
  (mrunalp@gmail.com)
- Bug 953357 - Check to make sure the server alias is passed as an argument.
  (rmillner@redhat.com)
- Merge pull request #2148 from brenton/node1
  (dmcphers+openshiftbot@redhat.com)
- /usr/bin/gear relies on the commander gem (bleanhar@redhat.com)
- Add missing bash SDK function (ironcladlou@gmail.com)
- Bug 950984: Implement stop_lock for force stop (ironcladlou@gmail.com)
- Merge pull request #2134 from jwhonce/bug/953002
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2131 from ironcladlou/dev/v2carts/jbossbugs
  (dmcphers+openshiftbot@redhat.com)
- Bug 953002 - Legal URL wrong in Welcome message (jhonce@redhat.com)
- Bug 952044 and 952043: JBoss v2 cart tidy fixes (ironcladlou@gmail.com)
- Sending the snapshot/restore messages stderr (calfonso@redhat.com)
- Merge pull request #2115 from rmillner/fix_primary
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2109 from jwhonce/bug/953002
  (dmcphers+openshiftbot@redhat.com)
- Do not fail on gears without a primary cartridge. (rmillner@redhat.com)
- Merge pull request #2080 from brenton/specs2
  (dmcphers+openshiftbot@redhat.com)
- Bug 953002 - Legal URL wrong in Welcome message (jhonce@redhat.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- Fix the frontend unit tests. (rmillner@redhat.com)
- The .ssh directory was not getting the correct MCS label.
  (rmillner@redhat.com)
- Bug 928621 - Save gear information in a look-aside database and only go to
  the gear as a last resort. (rmillner@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Adding the example cgconfig.conf back to the node spec (bleanhar@redhat.com)
- Move plugins.d/README from the node to the broker (miciah.masters@gmail.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.7.28-1
- Merge pull request #2091 from rmillner/fixselinux
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2095 from jwhonce/bug/952408
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2096 from pmorie/bugs/949425
  (dmcphers+openshiftbot@redhat.com)
- Bug 951994 - Underlying ruby selinux library appears to be unstable.  Rewrite
  to call the command line. (rmillner@redhat.com)
- Fix bug 949425 949426 952096 (pmorie@gmail.com)
- Add more information to the EINVAL errors. (rmillner@redhat.com)
- WIP Cartridge Refactor - V2 support for reading .uservars (jhonce@redhat.com)
- Merge pull request #2084 from pmorie/dev/trap_user
  (dmcphers+openshiftbot@redhat.com)
- Bug 952408 - Node filters threaddump calls (jhonce@redhat.com)
- Merge pull request #2077 from ironcladlou/dev/profiling (dmcphers@redhat.com)
- Merge pull request #2005 from dvusboy/master
  (dmcphers+openshiftbot@redhat.com)
- Add uservars directory to Environ.for_gear (pmorie@gmail.com)
- Optimize private endpoint creation (ironcladlou@gmail.com)
- provision for supplementary groups (sakrishnamurthy@corp.ebay.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 1.7.27-1
- doc updates (dmcphers@redhat.com)
- Ruby admin-ctl-gears-script to more efficiently manage dependency loading.
  (rmillner@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.26-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.7.25-1
- WIP: scalable snapshot/restore (pmorie@gmail.com)
- Merge pull request #2066 from sosiouxme/nodescripts20130413
  (dmcphers+openshiftbot@redhat.com)
- <node> fixing some minor inconsistencies in node scripts (lmeyer@redhat.com)
- Undo comment change so postgres_v2 merges (fotios@redhat.com)
- Fixed set_env_var (fotios@redhat.com)
- Added helpers to sdk (fotios@redhat.com)
- Merge pull request #2044 from jwhonce/wip/oo_trap_user (dmcphers@redhat.com)
- Bug 951368 - V2 support broke reading .uservars (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.24-1
- Merge pull request #2037 from ironcladlou/dev/v2cart/mock
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2028 from brenton/misc5
  (dmcphers+openshiftbot@redhat.com)
- Fix cart-scoped action hook executions (ironcladlou@gmail.com)
- Merge pull request #2029 from rmillner/TC222
  (dmcphers+openshiftbot@redhat.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- WIP Cartridge Refactor - Process manifest overrides for Broker
  (jhonce@redhat.com)
- Merge pull request #2031 from jwhonce/wip/restart_reload
  (dmcphers@redhat.com)
- Merge pull request #2020 from danmcp/master (dmcphers@redhat.com)
- phpmyadmin WIP (dmcphers@redhat.com)
- WIP Cartridge Refactor - Skip reload actions on cartridge unless gear started
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Support skip_hooks when destroying gear
  (jhonce@redhat.com)
- Merge pull request #2015 from ironcladlou/dev/v2carts/build-system
  (dmcphers@redhat.com)
- We don't want the installation of the node-proxy to auto launch the service
  (bleanhar@redhat.com)
- Merge pull request #2019 from jwhonce/wip/restart_reload
  (dmcphers@redhat.com)
- Merge pull request #2016 from pmorie/dev/platform_ssh (dmcphers@redhat.com)
- Merge pull request #2024 from ironcladlou/dev/v2carts/documentation
  (dmcphers@redhat.com)
- Application author documentation (ironcladlou@gmail.com)
- Bug 950451 - Add stop_lock support to scaled cartridge restart/reload
  (jhonce@redhat.com)
- Generate ssh key for web proxy cartridges (pmorie@gmail.com)
- Call cart pre-receive hook during default build lifecycle
  (ironcladlou@gmail.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 1.7.23-1
- Moving openshift_origin_users out of sdk (calfonso@redhat.com)
- Merge pull request #2010 from jwhonce/wip/v2_cart_model
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move range for uid in tests (jhonce@redhat.com)
- Merge pull request #2007 from jwhonce/wip/oo_trap_user (dmcphers@redhat.com)
- Merge pull request #2006 from jwhonce/wip/manifest_overrides
  (dmcphers@redhat.com)
- Merge pull request #1993 from lnader/patch-2 (dmcphers@redhat.com)
- WIP Cartridge Refactor - Finish context checking (jhonce@redhat.com)
- WIP Cartridge Refactor - update versions in manifest to be strings
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Support for version overrides in manifest
  (ironcladlou@gmail.com)
- Update README.writing_cartridges.md (lnader@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.22-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1984 from jwhonce/wip/v2_cart_model (dmcphers@redhat.com)
- Merge pull request #1982 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1979 from pmorie/dev/snapshot_cuke
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Fix for processing dot file ERB's
  (jhonce@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Merge pull request #1959 from pravisankar/dev/ravi/card-537
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1978 from sosiouxme/bz949543 (dmcphers@redhat.com)
- Add core platform test for v2 snapshot/restore (pmorie@gmail.com)
- Merge pull request #1973 from dobbymoodge/BZ920477 (dmcphers@redhat.com)
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)
- node scripts Bug 920477 - replace -? short option with documented -h
  (jolamb@redhat.com)
- <node spec> bug 949543 use resource_limits.template directly as .conf in RPM
  (lmeyer@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.7.21-1
- Merge pull request #1952 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1958 from rajatchopra/master (dmcphers@redhat.com)
- Merge pull request #1951 from jwhonce/wip/git_submodules
  (dmcphers@redhat.com)
- Merge pull request #1950 from mrunalp/dev/remotedeploy (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- delete all calls to remove_ssh_key, and remove_domain_env_vars
  (rchopra@redhat.com)
- Merge pull request #1946 from jwhonce/wip/oo_trap_user (dmcphers@redhat.com)
- Bug 949266 - failed to initialize variable (jhonce@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- %%{_var}/run/openshift is needed, adding it back (calfonso@redhat.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Add support to oo-trap-user for V2 gear env's
  (jhonce@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.20-1
- Merge pull request #1941 from jwhonce/wip/v2_cart_model
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Use gear combined env when calling hooks
  (jhonce@redhat.com)
- Cartridge Bash SDK cleanups (ironcladlou@gmail.com)
- 10gen-mms-agent WIP (dmcphers@redhat.com)
- Merge pull request #1932 from pmorie/dev/v2_mysql (dmcphers@redhat.com)
- Add v2 mysql snapshot (pmorie@gmail.com)
- HAProxy deploy wip. (mrunalp@gmail.com)
- Set sync on STDOUT/STDERR in gear script (ironcladlou@gmail.com)
- cleanup (dmcphers@redhat.com)
- Merge pull request #1903 from fotioslindiakos/cart_utils
  (dmcphers@redhat.com)
- Merge pull request #1914 from pmorie/dev/mock_hooks
  (dmcphers+openshiftbot@redhat.com)
- Added helper function to set env vars (fotios@redhat.com)
- Merge pull request #1912 from calfonso/master (dmcphers@redhat.com)
- Merge pull request #1898 from jwhonce/wip/rhcsh
  (dmcphers+openshiftbot@redhat.com)
- Refactor mock and mock-plugin connection hooks (pmorie@gmail.com)
- Moving root cron configuration out of cartridges and into node
  (calfonso@redhat.com)
- Build lifecycle fixes and tests (ironcladlou@gmail.com)
- Fix unit/functional test isolation (ironcladlou@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Merge pull request #1899 from pmorie/dev/connector_docs (dmcphers@redhat.com)
- Recover pub/sub docs (pmorie@gmail.com)
- WIP Cartridge Refactor - rhcsh support of v2 applications (jhonce@redhat.com)
- WIP Cartridge Refactor - support for git submodules and template url
  (jhonce@redhat.com)
- Merge pull request #1890 from mrunalp/dev/web_proxy_deploy
  (dmcphers@redhat.com)
- Merge pull request #1882 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Deploy for web proxy. (mrunalp@gmail.com)
- adding to the sdk (dmcphers@redhat.com)
- General client message streaming support (ironcladlou@gmail.com)
- Fix how erb binary is resolved. Using util/util-scl packages instead of doing
  it dynamically in code. Separating manifest into RHEL and Fedora versions
  instead of using sed to set version. (kraman@gmail.com)
- WIP: v2 snapshot/restore (pmorie@gmail.com)
- Merge pull request #1872 from pmorie/dev/gear
  (dmcphers+openshiftbot@redhat.com)
- Suppress NodeLogger calls in the context of gear script (pmorie@gmail.com)
- Fix v2 ERB processing (ironcladlou@gmail.com)
- V2 cart state management implementation (ironcladlou@gmail.com)
- Merge pull request #1837 from kraman/php_v2
  (dmcphers+openshiftbot@redhat.com)
- Adding Apache 2.4 and PHP 5.4 support to PHP v2 cartridge Fix Path to erb
  executable (kraman@gmail.com)
- Better rescue for Errno (fotios@redhat.com)
- Added application_state tests (fotios@redhat.com)
- Fixing environ tests (fotios@redhat.com)
- Fixing frontend_proxy_test (fotios@redhat.com)

* Thu Apr 04 2013 Unknown name 1.7.19-1
- fixing (root@ip-10-110-255-166.ec2.internal)

* Thu Apr 04 2013 Unknown name 1.7.18-1
- Moving root cron configuration out of cartridges and into node
  (calfonso@redhat.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Merge pull request #1899 from pmorie/dev/connector_docs (dmcphers@redhat.com)
- Recover pub/sub docs (pmorie@gmail.com)
- WIP Cartridge Refactor - support for git submodules and template url
  (jhonce@redhat.com)
- Merge pull request #1890 from mrunalp/dev/web_proxy_deploy
  (dmcphers@redhat.com)
- Merge pull request #1882 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Deploy for web proxy. (mrunalp@gmail.com)
- adding to the sdk (dmcphers@redhat.com)
- General client message streaming support (ironcladlou@gmail.com)
- Fix how erb binary is resolved. Using util/util-scl packages instead of doing
  it dynamically in code. Separating manifest into RHEL and Fedora versions
  instead of using sed to set version. (kraman@gmail.com)
- WIP: v2 snapshot/restore (pmorie@gmail.com)
- Merge pull request #1872 from pmorie/dev/gear
  (dmcphers+openshiftbot@redhat.com)
- Suppress NodeLogger calls in the context of gear script (pmorie@gmail.com)
- Fix v2 ERB processing (ironcladlou@gmail.com)
- V2 cart state management implementation (ironcladlou@gmail.com)
- Merge pull request #1837 from kraman/php_v2
  (dmcphers+openshiftbot@redhat.com)
- Adding Apache 2.4 and PHP 5.4 support to PHP v2 cartridge Fix Path to erb
  executable (kraman@gmail.com)
- Better rescue for Errno (fotios@redhat.com)
- Added application_state tests (fotios@redhat.com)
- Fixing environ tests (fotios@redhat.com)
- Fixing frontend_proxy_test (fotios@redhat.com)

* Wed Apr 03 2013 Unknown name 1.7.17-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.16-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.16-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.15-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.15-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.14-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.14-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.13-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.13-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.12-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.12-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.11-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.11-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.10-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.10-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.9-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.9-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.8-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.8-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.7-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.7-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.6-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.6-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.5-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.5-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.4-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.4-1
- Automatic commit of package [rubygem-openshift-origin-node] release
  [1.7.3-1]. (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.3-1
- test fix (root@ip-10-114-31-128.ec2.internal)

* Wed Apr 03 2013 Unknown name 1.7.2-1
- Moving root cron configuration out of cartridges and into node
  (calfonso@redhat.com)
- WIP Cartridge Refactor - support for git submodules and template url
  (jhonce@redhat.com)
- Merge pull request #1890 from mrunalp/dev/web_proxy_deploy
  (dmcphers@redhat.com)
- Merge pull request #1882 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- Deploy for web proxy. (mrunalp@gmail.com)
- adding to the sdk (dmcphers@redhat.com)
- General client message streaming support (ironcladlou@gmail.com)
- Fix how erb binary is resolved. Using util/util-scl packages instead of doing
  it dynamically in code. Separating manifest into RHEL and Fedora versions
  instead of using sed to set version. (kraman@gmail.com)
- WIP: v2 snapshot/restore (pmorie@gmail.com)
- Merge pull request #1872 from pmorie/dev/gear
  (dmcphers+openshiftbot@redhat.com)
- Suppress NodeLogger calls in the context of gear script (pmorie@gmail.com)
- Fix v2 ERB processing (ironcladlou@gmail.com)
- V2 cart state management implementation (ironcladlou@gmail.com)
- Merge pull request #1837 from kraman/php_v2
  (dmcphers+openshiftbot@redhat.com)
- Adding Apache 2.4 and PHP 5.4 support to PHP v2 cartridge Fix Path to erb
  executable (kraman@gmail.com)
- Better rescue for Errno (fotios@redhat.com)
- Added application_state tests (fotios@redhat.com)
- Fixing environ tests (fotios@redhat.com)
- Fixing frontend_proxy_test (fotios@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- Merge pull request #1836 from rmillner/fix_ssh_keys
  (dmcphers+openshiftbot@redhat.com)
- No longer matching the comment on ssh_key_remove.  Matching all keys which
  the actual key payload is the same instead. (rmillner@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 1.6.9-1
- Merge pull request #1821 from jwhonce/wip/threaddump
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Roll out old threaddump support (jhonce@redhat.com)
- Merge pull request #1817 from jwhonce/wip/threaddump (dmcphers@redhat.com)
- Merge pull request #1818 from mrunalp/dev/haproxy_wip (dmcphers@redhat.com)
- Merge pull request #1809 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- remove rpmnew env vars (dmcphers@redhat.com)
- Merge pull request #1811 from kraman/gen_docs (dmcphers@redhat.com)
- WIP Cartridge Refactor - Add PHP support for threaddump (jhonce@redhat.com)
- Merge pull request #1804 from jwhonce/wip/connectors
  (dmcphers+openshiftbot@redhat.com)
- Update docs generation and add node/cartridge guides [WIP]
  https://trello.com/c/yUMBZ0P9 (kraman@gmail.com)
- HAProxy WIP. (mrunalp@gmail.com)
- Bug 927614: Fix action hook execution during v2 control ops
  (ironcladlou@gmail.com)
- fixing test cases (dmcphers@redhat.com)
- WIP Cartridge Refactor - Refactor V2 connector_execute to use V1 contract
  (jhonce@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 1.6.8-1
- error handling in gear script (dmcphers@redhat.com)
- Getting jenkins working (dmcphers@redhat.com)
- Merge pull request #1797 from rmillner/BZ924110
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1795 from jwhonce/wip/streaming
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1787 from ironcladlou/oo-delete-endpoints-fix
  (dmcphers+openshiftbot@redhat.com)
- Bug 924110 - ssl certs need to update with namespace updates.
  (rmillner@redhat.com)
- WIP Cartridge Refactor - Add missing slash (jhonce@redhat.com)
- WIP Cartridge Refactor - Stream stdin/stdout/stderr from oo_spawn
  (jhonce@redhat.com)
- Merge pull request #1784 from jwhonce/wip/v2_cart_model
  (dmcphers+openshiftbot@redhat.com)
- Fix public endpoint delete call typo (ironcladlou@gmail.com)
- WIP Cartridge Refactor - Move OPENSHIFT_NAMESPACE to v2 code path
  (jhonce@redhat.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- <oo-cgroup-read> bug 924556 pull in native rubygem-open4 (lmeyer@redhat.com)
- Merge pull request #1769 from calfonso/master (dmcphers@redhat.com)
- Clean up bin/control documentation (ironcladlou@gmail.com)
- Cron and DIY v2 cartridge fixes (calfonso@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1766 from ironcladlou/dev/v2carts/documentation
  (dmcphers@redhat.com)
- Documentation updates (ironcladlou@gmail.com)
- adding openshift node util (dmcphers@redhat.com)
- More v2 jenkins-client progress (ironcladlou@gmail.com)
- implementing builder_cartridge based on cart categories (dmcphers@redhat.com)
- gearctl -> gear and using dmace's default builder (dmcphers@redhat.com)
- More builds WIP (ironcladlou@gmail.com)
- add gearctl (dmcphers@redhat.com)
- Merge pull request #1758 from jwhonce/wip/clean_cartridge_repo
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1757 from ironcladlou/wip/connectors
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1754 from rmillner/better_key_parsing
  (dmcphers@redhat.com)
- WIP Cartridge Refactor - clean cartridge repository on re-install
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Add support for connection hooks (jhonce@redhat.com)
- Merge pull request #1749 from ironcladlou/dev/v2carts/build-system
  (dmcphers@redhat.com)
- More resiliant to arbitrary spaces elsewhere in the line.
  (rmillner@redhat.com)
- Fix all incorrect occurrences of 'who's'. (asari.ruby@gmail.com)
- Reimplement the v2 build process (ironcladlou@gmail.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Merge pull request #1743 from jwhonce/wip/cartridge_ident
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Add new environment variables (jhonce@redhat.com)
- Merge pull request #1740 from ironcladlou/dev/v2carts/build-system
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Add new environment variables (jhonce@redhat.com)
- Merge pull request #1739 from rmillner/lock_ssh (dmcphers@redhat.com)
- Improve build output to client (ironcladlou@gmail.com)
- Protect ssh key edits with a mutex and lock file. (rmillner@redhat.com)
- Fix mixed case if inferring FQDN from gear information. (rmillner@redhat.com)
- Improve logging/client output during build (ironcladlou@gmail.com)
- Merge pull request #1714 from pmorie/dev/v2_mysql (admiller@redhat.com)
- Cart V2 build implementation WIP (ironcladlou@gmail.com)
- Merge pull request #1717 from jwhonce/wip/setup_version
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1704 from sosiouxme/bz919619
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1706 from jwhonce/wip/setup_dot_files
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1719 from jwhonce/wip/documentation (dmcphers@redhat.com)
- WIP Cartridge Refactor - update documentation (jhonce@redhat.com)
- WIP Cartridge Refactor -- restore --version to setup calls
  (jhonce@redhat.com)
- WIP: v2 mysql (pmorie@gmail.com)
- <ApplicationContainer> bug 919619 move git gc later in tidy process.
  (lmeyer@redhat.com)
- WIP Cartridge Refactor - glob dot files from CartridgeRepository
  (jhonce@redhat.com)
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)
- Merge pull request #1695 from jwhonce/wip/coverage
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Work on tests and coverage (jhonce@redhat.com)
- WIP Cartridge Refactor - Mung cartridge-vendor omit spaces and downcase
  (jhonce@redhat.com)
- Merge pull request #1683 from jwhonce/wip/mock_updated (dmcphers@redhat.com)
- WIP Cartridge Refactor - missed commit (jhonce@redhat.com)
- WIP Cartridge Refactor - Fix node_test.rb (jhonce@redhat.com)
- WIP Cartridge Refactor - cucumber test refactor (jhonce@redhat.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 1.6.4-1
- Add SNI upload support to API (lnader@redhat.com)
- WIP Cartridge Refactor - Fix v2_cart_model_test (jhonce@redhat.com)
- WIP Cartridge Refactor - Mock plugin installed from CartridgeRepository
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Refactor V2CartridgeModel to use CartridgeRepository
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Introduce oo-admin-cartridge command
  (jhonce@redhat.com)
- WIP Cartridge Refactor - Refactor V2CartridgeModel to use CartridgeRepository
  (jhonce@redhat.com)
- Update Endpoint documentation (ironcladlou@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- merge with latest pulls (tdawson@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- Remove Cartridge->CartridgeRepository dependency for path setup
  (ironcladlou@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- Merge pull request #1625 from tdawson/tdawson/remove-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1629 from jwhonce/wip/cartridge_repository
  (dmcphers+openshiftbot@redhat.com)
- Bug 920880 - Only allow httpd-singular to return when Apache is fully back up
  and protect the SSL cert operations with the Alias lock.
  (rmillner@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1622 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- remove old obsoletes (tdawson@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Merge pull request #1613 from mrunalp/bugs/920365
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1614 from jwhonce/wip/rhcsh
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Refactor building rhcsh environment
  (jhonce@redhat.com)
- Bug 920365: Fix oo-create-endpoints to call the correct method.
  (mrunalp@gmail.com)
- Bug 876746 - oo-cartridge-info errors when no parameters are passed
  (calfonso@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- And fix the unit test. (rmillner@redhat.com)
- Fix FrontendHttpServer class validation of chained certificates.
  (rmillner@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.15-1
- Merge pull request #1578 from ironcladlou/endpoint_ex_handling
  (dmcphers+openshiftbot@redhat.com)
- Bug 919161: Fix Python 3.3 Endpoint entry (ironcladlou@gmail.com)
- Bug 918888 - Had the wrong exit status. (rmillner@redhat.com)
- Merge pull request #1575 from pmorie/dev/uu
  (dmcphers+openshiftbot@redhat.com)
- Fix destroyed gear check in UnixUser#destroy (pmorie@gmail.com)
- Merge pull request #1570 from rmillner/post_stage
  (dmcphers+openshiftbot@redhat.com)
- Bug 901866 - Put training wheels on the rm command. (rmillner@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.14-1
- BZ873896 - [ORIGIN] 000001_openshift_origin_node.conf not included in
  gemspec, but is in tar.gz (calfonso@redhat.com)
- be sure you dont cache an empty list (dmcphers@redhat.com)
- Bug 918480 (dmcphers@redhat.com)
- Bug 917990 - Multiple fixes. (rmillner@redhat.com)
- Merge pull request #1548 from markllama/dev/cgroup_freezethaw
  (dmcphers+openshiftbot@redhat.com)
- fixed missing case end and cgset syntax (mlamouri@redhat.com)
- added cgset freeze|thaw user (markllama@gmail.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.13-1
- Merge pull request #1545 from pmorie/dev/v2_get_cart (dmcphers@redhat.com)
- Bug 917163 (dmcphers@redhat.com)
- Make v2 get_cartridge use instance dir instead of system path
  (pmorie@gmail.com)
- Merge pull request #1531 from jwhonce/bug/916958 (dmcphers@redhat.com)
- Bug 916958, Bug 917513 - V1 Model not honoring Broker contract
  (jhonce@redhat.com)

* Mon Mar 04 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- WIP Cartridge Refactor - improve robustness of oo_spawn (jhonce@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- remove chown/chmod, errors in mock with Operation Not Permitted, %%files
  section should satisfy this (admiller@redhat.com)
- fixing BuildRequires (admiller@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Bug 912215 - Workaround broken SELinux policy. (rmillner@redhat.com)
- Bug 916839 - The apache user cannot read through /etc/httpd/conf.d on
  STG/INT/PROD for security reasons. (rmillner@redhat.com)
- Merge pull request #1506 from pmorie/dev/cartridge_refactor
  (dmcphers+openshiftbot@redhat.com)
- Add simple v2 app builds (pmorie@gmail.com)
- WIP Cartridge Refactor - Add OPENSHIFT_{Cartridge-Short-Name}_DIR
  (jhonce@redhat.com)
- Remove parsing version from cartridge-name (pmorie@gmail.com)
- Bug 916917 - uninitialized constant ApplicationState (jhonce@redhat.com)
- Merge pull request #1497 from jwhonce/wip/master_unix_user
  (dmcphers@redhat.com)
- Strip out malformed entries. (rmillner@redhat.com)
- Move the blank route files out of %%post. (rmillner@redhat.com)
- WIP Cartridge Refactor - Remove oo_spawn use from v1 path (jhonce@redhat.com)
- Use sync IO for the logger file (ironcladlou@gmail.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Merge pull request #1486 from lnader/revert_pull_request_1
  (dmcphers@redhat.com)
- reverted US2448 (lnader@redhat.com)
- Bug 901424 - Hide the mco command. (rmillner@redhat.com)
- Bug 901743 - Add the various other commonly used TMP variables.
  (rmillner@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Merge pull request #1477 from ironcladlou/dev/cartridge_refactor
  (dmcphers@redhat.com)
- WIP Cartridge Refactor (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- US2448 (lnader@redhat.com)
- Merge pull request #1465 from rmillner/BZ912238
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1462 from rmillner/BZ915471
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1459 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Bug 912238 - The last rescue was catching exit. (rmillner@redhat.com)
- Bug 915471 - The set_selinux_context function was being used in the wrong
  place. (rmillner@redhat.com)
- WIP Cartridge Refactor - Update cartridge author's guide (jhonce@redhat.com)
- Use an openshift specific log for last_access. (rmillner@redhat.com)
- Fix X-Client-IP. (rmillner@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Turn route logging off. (rmillner@redhat.com)
- Fetch returns KeyError. (rmillner@redhat.com)
- Bug 913351 - Cannot create application successfully when district is added
  (jhonce@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.5-2
- bump Release for fixed build target rebuild (admiller@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- fix typo (dmcphers@redhat.com)
- Bug 913423 - Incorrect syntax for ReverseCookiePath, and the way the node
  table lookup works we do not have the information broken out in a way that
  supports the correct syntax. (rmillner@redhat.com)
- Use File.chown/chmod. (rmillner@redhat.com)
- Merge pull request #1429 from jwhonce/dev/wip_master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1420 from kraman/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 913288 - Numeric login effected additional commands (jhonce@redhat.com)
- Removing references to cgconfig/all (kraman@gmail.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Merge pull request #1417 from jwhonce/dev/wip_master
  (dmcphers+openshiftbot@redhat.com)
- Bug 912899 - mcollective changing all numeric mongoid to BigInt
  (jhonce@redhat.com)
- Allow for a __default__ target which matches hosts not otherwise matched.
  (rmillner@redhat.com)
- Fix permissions for db files. (rmillner@redhat.com)
- Merge pull request #1409 from tdawson/tdawson/fix_rubygem_sources
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1408 from jwhonce/format_markers
  (dmcphers+openshiftbot@redhat.com)
- fix rubygem sources (tdawson@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Fixing sed script for F18 config updates (kraman@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Merge pull request #1405 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1379 from markllama/bugs/cgroup-start
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1376 from markllama/bug/oo-cgroup-read
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1404 from kraman/master
  (dmcphers+openshiftbot@redhat.com)
- Fedora 18 moved the httxt2dbm command. (rmillner@redhat.com)
- Fixing sed expression which transforms 000001_openshift_origin_node.conf for
  Apache 2.4 Revert "Adding path to resolve useradd"   This reverts commit
  31d41d77df658b1bb134a9d2cba7cd8ee28cfe64. (kraman@gmail.com)
- Commands and mcollective calls for each FrontendHttpServer API.
  (rmillner@redhat.com)
- Bug 912215: Use oo-ruby for interpreter (ironcladlou@gmail.com)
- Merge pull request #1391 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Add existing community carts to v1 cart list (kraman@gmail.com)
- Adding path to resolve useradd (kraman@gmail.com)
- add check for systemd based os (markllama@gmail.com)
- Merge pull request #1387 from jwhonce/dev/threaddump
  (dmcphers+openshiftbot@redhat.com)
- Bug 911956 - Fixed miss-spelled method name (jhonce@redhat.com)
- Bug 906740 - Update error message (jhonce@redhat.com)
- Fixes to get builds and tests running on RHEL: (kraman@gmail.com)
- Fixes for ruby193 (john@ibiblio.org)
- Bug 868427: Fix tidy for v1 carts (ironcladlou@gmail.com)
- open4 is a rubygem (mlamouri@redhat.com)
- remove community pod (dmcphers@redhat.com)
- minor cleanup (dmcphers@redhat.com)
- Patch node coverage file permissions to work with oo_spawn tests
  (jhonce@redhat.com)
- Fix embed.feature (pmorie@gmail.com)
- Initial write-up of pub/sub hooks (mrunal@me.com)
- Refactor agent and proxy, move all v1 code to v1 model
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Bug [906687] - Lacking usage info of oo-cgroup-read command
  (mlamouri@redhat.com)
- remove use of filesystem cgroup countrol (mlamouri@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- remove BuildRoot: (tdawson@redhat.com)
- move rest api tests to functionals (dmcphers@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- working on testing coverage (dmcphers@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1255 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> active_capacity/max_active_apps/etc switched to
  gear-based accounting (lmeyer@redhat.com)
- Merge pull request #1238 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> reckon by gears (as opposed to git repos), add gear
  status facts (lmeyer@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Bug 905568: Skip endpoint deletion if no Endpoints in manifest
  (ironcladlou@gmail.com)
- Merge pull request #1231 from ironcladlou/expose-port-fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1235 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1117 from mscherer/fix_better_cgroup_listing
  (dmcphers+openshiftbot@redhat.com)
- Bug 874594 Bug 888550 (dmcphers@redhat.com)
- Bug 904100: Tolerate missing Endpoint cart manifest entries
  (ironcladlou@gmail.com)
- BZ896406 - warning message when installing rubygem-openshift-origin-node
  (bleanhar@redhat.com)
- BZ876324 resolve ServerName/NameVirtualHost situation for
  node/broker/ssl.conf (lmeyer@redhat.com)
- Switch calling convention to match US3143 (rmillner@redhat.com)
- adding a dash in the authorized key entry comment to make it more readable
  (abhgupta@redhat.com)
- fix for bug 894948 (abhgupta@redhat.com)
- fix and factorise the function for the list of users as openshift_users do
  not match on the same exact list of people than valid_user ( due to code
  duplication and subtle difference between the copies ) (misc@zarb.org)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.6-1
- Bug 903152: Execute git tidy ops as gear user (ironcladlou@gmail.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- BZ 901449: An SELinux issue prevents forces this script to use system ruby
  and not the SCL version. (rmillner@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.4-1
- Bug 901444 (dmcphers@redhat.com)
- SSL support for custom domains. (mpatel@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Mon Jan 14 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Fix BZ875200: Add statements to rhcsh ctl_all (pmorie@gmail.com)
- Merge pull request #1141 from pmorie/bugs/877306
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1140 from pmorie/bugs/877305
  (dmcphers+openshiftbot@redhat.com)
- Fix usage for oo-admin-ctl-cgroups (pmorie@gmail.com)
- Add newline to each user for oo-admin-ctl-cgroups stopall (pmorie@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1120 from sosiouxme/BZ876324
  (dmcphers+openshiftbot@redhat.com)
- BZ876324 resolve ServerName/NameVirtualHost situation for
  node/broker/ssl.conf (lmeyer@redhat.com)
- Update rhc command usage. Addresses BZ889018. (asari.ruby@gmail.com)
- Typo. (rmillner@redhat.com)
- BZ 888410: The reader sequence can block if there is too much stderr
  (rmillner@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1007 from sosiouxme/US3036-origin
  (openshift+bot@redhat.com)
- Adding oo-accept-systems script for verifying all node hosts from the broker.
  - also verifies cartridge consistency and checks for stale cartridge cache.
  oo-accept-node sanity checks public_ip and public_hostname. Minor edits to
  make node.conf easier to understand. (lmeyer@redhat.com)
- Fix tests.  The file mock was not working. (rmillner@redhat.com)
- Post rebase code cleanup. (rmillner@redhat.com)
- Proper host name validation. (rmillner@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- bug 884409 (dmcphers@redhat.com)
- Merge pull request #1023 from ramr/dev/websockets (openshift+bot@redhat.com)
- Fix frontend httpd tests. (ramr@redhat.com)
- Node web sockets and http(s) proxy support with spec file and package.
  (ramr@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Fix for Bug 883605 (jhonce@redhat.com)
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Merge pull request #1005 from ironcladlou/US2770 (openshift+bot@redhat.com)
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Bug Fixes. (rmillner@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Move force-stop into the the node library (ironcladlou@gmail.com)
- exit code and usage cleanup (dmcphers@redhat.com)
- Merge pull request #962 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #905 from kraman/ruby19 (openshift+bot@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- F18 compatibility fixes   - apache 2.4   - mongo journaling   - JDK 7   -
  parseconfig gem update Bugfix for Bind DNS plugin (kraman@gmail.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- BZ877125 - File attributes on open shift-cgroups init script are incorrect,
  should be -rwxr-x--- (calfonso@redhat.com)
- more ruby1.9 changes (dmcphers@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Ruby 1.9 compatibility fixes (ironcladlou@gmail.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- Merge pull request #886 from rmillner/inhibitidler (dmcphers@redhat.com)
- One of the SELinux denials was accessing the locale file via whois which is
  unnecessary if accessing /etc directly. (rmillner@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Merge remote-tracking branch 'origin-server/master' into BZ874587-origin
  (bleanhar@redhat.com)
- Merge pull request #881 from rmillner/wrongmcs (openshift+bot@redhat.com)
- SS -> OPENSHIFT (dmcphers@redhat.com)
- Was setting mcs label in the wrong place. (rmillner@redhat.com)
- Fix for Bug 875949 (jhonce@redhat.com)
- Bug 874587 - CLOUD_NAME in /etc/openshift/node.conf does not work
  (bleanhar@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- BZ 872379: Dead code cleanup to fix mount parsing problem.
  (rmillner@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #857 from jwhonce/dev/bz874712_master
  (openshift+bot@redhat.com)
- Fix for Bug 874712 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #851 from brenton/no_trace (openshift+bot@redhat.com)
- BZ873970, BZ873966 - disabling HTTP TRACE for the Broker, Nodes and Console
  (bleanhar@redhat.com)
- Increase the table sizes to cover 15000 nodes in dev and prod.
  (rmillner@redhat.com)
- BZ872523 - set quota for gear failed if the device name is too long
  (bleanhar@redhat.com)
- Merge pull request #698 from mscherer/fix_doc_node_bin
  (openshift+bot@redhat.com)
- do not use old name in the script help message (mscherer@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)
