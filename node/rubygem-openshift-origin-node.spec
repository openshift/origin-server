%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
    %global with_systemd 1
%else
    %global with_systemd 0
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
Version: 1.21.0
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
Requires:      %{?scl:%scl_prefix}rubygem(open4)
Requires:      %{?scl:%scl_prefix}rubygem(parallel)
%if 0%{?rhel} <= 6
# non-scl open4 required for ruby 1.8 cartridge
# Also see related bugs 924556 and 912215
Requires:      rubygem(open4)
%endif
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
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
# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' Gemfile


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
mkdir -p %{buildroot}%{_var}/log/openshift/node

# Move the gem configs to the standard filesystem location
mkdir -p %{buildroot}/etc/openshift
rm -rf %{buildroot}%{gem_instdir}/conf/plugins.d/README
mv %{buildroot}%{gem_instdir}/conf/* %{buildroot}/etc/openshift

# Install logrotate files
mkdir -p %{buildroot}/etc/logrotate.d
%if %{with_systemd}
install -D -p -m 644 %{buildroot}%{gem_instdir}/misc/etc/openshift-origin-node.logrotate.systemd %{buildroot}/etc/logrotate.d/%{name}
%else
install -D -p -m 644 %{buildroot}%{gem_instdir}/misc/etc/openshift-origin-node.logrotate.service %{buildroot}/etc/logrotate.d/%{name}
%endif

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

cp %{buildroot}%{gem_instdir}/misc/etc/system-config-firewall-compat %{buildroot}/etc/openshift/

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
%attr(0750,-,-) %{_var}/log/openshift/node
/usr/libexec/openshift/lib/quota_attrs.sh
/usr/libexec/openshift/lib/archive_git_submodules.sh
%dir %attr(0755,-,-) %{openshift_lib}/cartridge_sdk
%dir %attr(0755,-,-) %{openshift_lib}/cartridge_sdk/bash
%attr(0744,-,-) %{openshift_lib}/cartridge_sdk/bash/*
%dir %attr(0755,-,-) %{openshift_lib}/cartridge_sdk/ruby
%attr(0744,-,-) %{openshift_lib}/cartridge_sdk/ruby/*
%dir /etc/openshift
%attr(0644,-,-) %config /etc/openshift/system-config-firewall-compat
%config(noreplace) /etc/openshift/node.conf
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.filter.rules
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.nat.rules
%config(noreplace) /etc/openshift/env/*
%config(noreplace) /etc/logrotate.d/%{name}
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
* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.20.7-1
- Merge pull request #4782 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Increase timeout (dmcphers@redhat.com)
- node: proper logrotate files for the service (mmahut@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.6-1
- Merge pull request #4769 from ncdc/new-ha-app-fix-update-cluster
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064219 - revert iptables location change (lsm5@redhat.com)
- Allow new HA app to be created successfully (andy.goldstein@gmail.com)
- Merge pull request #4764 from jwhonce/bug/1065045
  (dmcphers+openshiftbot@redhat.com)
- Bug 1065045 - Enforce cronjob timeout (jhonce@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Bug 1064219 - handle iptables rules (lsm5@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Speeding up multi ha test and fixing retries (dmcphers@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4720 from lsm5/new-iptables2
  (dmcphers+openshiftbot@redhat.com)
- Bug 1045224 - install iptables rules in new dir (lsm5@redhat.com)
- Bug 1019219 - PassEnv warning messages are shown when deploy app
  (jhadvig@redhat.com)
- Splitting out gear tests (dmcphers@redhat.com)
- Merge pull request #4696 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4709 from danmcp/dev/bug1035046
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4710 from jwhonce/bug/1063142
  (dmcphers+openshiftbot@redhat.com)
- Bug 1035046 - Increase user set env vars to 50 (dmcphers@redhat.com)
- Bug 1063142 - Ignore .stop_lock on gear operations (jhonce@redhat.com)
- fix https://bugzilla.redhat.com/show_bug.cgi?id=1062775 (rchopra@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Bug 1055456 - Handle node env messages better (dmcphers@redhat.com)
- origin_node_185 - Refactor oo-admin-ctl-gears (jhonce@redhat.com)
- Merge pull request #4682 from danmcp/cleaning_specs
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4678 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4679 from danmcp/cleanup_mco_ddl
  (dmcphers+openshiftbot@redhat.com)
- Bug 1061098 (dmcphers@redhat.com)
- Cleanup mco ddl (dmcphers@redhat.com)
- Merge pull request #4616 from brenton/deployment_dir1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4666 from ncdc/dev/node-access-log-gear-info
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Add app, gear UUIDs to openshift_log (andy.goldstein@gmail.com)
- Merge pull request #4659 from bparees/from_url
  (dmcphers+openshiftbot@redhat.com)
- Bug 1054075 - Fail to create drupal quickstart (bparees@redhat.com)
- Bug 1061400 - Add REPORT_BROKER_ANALYTICS (jhonce@redhat.com)
- Merge pull request #4654 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4653 from jwhonce/wip/watchman
  (dmcphers+openshiftbot@redhat.com)
- fix frontend fqdn for ha (rchopra@redhat.com)
- Merge pull request #4655 from jwhonce/bug/1049089
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - Fix tests since performance enhancements (jhonce@redhat.com)
- Bug 1049089 - Speed up selinux labeling usage (jhonce@redhat.com)
- Bug 1045972 - Removing whitespace on default MOTD_FILE value
  (bleanhar@redhat.com)
- Merge pull request #4590 from smarterclayton/origin_broker_193_carts_in_mongo
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4631 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- add app-dns to secondary haproxy gears (rchopra@redhat.com)
- Bug 1038745 - Use oo-ssh when rsync'ing user variables (jhonce@redhat.com)
- Merge pull request #4635 from jwhonce/bug/1057734
  (dmcphers+openshiftbot@redhat.com)
- Bug 1057734 - Protect against divide by zero (jhonce@redhat.com)
- Merge pull request #4624 from ironcladlou/dev/syslog
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Platform logging enhancements (ironcladlou@gmail.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Adding a unit test (bleanhar@redhat.com)
- First pass at avoiding deployment dir create on app moves
  (bleanhar@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Merge pull request #4630 from jwhonce/bug/1059804
  (dmcphers+openshiftbot@redhat.com)
- Bug 1059804 - Watchman support for UTF-8 (jhonce@redhat.com)
- Merge pull request #4626 from jwhonce/bug/1056713
  (dmcphers+openshiftbot@redhat.com)
- Bug 1056713 - Report cgroup attributes and values in JSON (jhonce@redhat.com)
- Merge pull request #4545 from brenton/iptables1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4611 from jwhonce/stage
  (dmcphers+openshiftbot@redhat.com)
- Improving oo-admin-ctl-iptables-port-proxy's start method to handle a missing
  INPUT rule (bleanhar@redhat.com)
- Various iptables integration fixes (bleanhar@redhat.com)
- Revert "Merge pull request #4488 from lsm5/new-node_conf" (jhonce@redhat.com)
- Revert "Merge pull request #4519 from lsm5/new-node_conf" (jhonce@redhat.com)
- Keeping tests of same type in same group (dmcphers@redhat.com)
- Fix bug 1055653 for cases when httpd is down (pmorie@gmail.com)
- Fixing common test case timeout (dmcphers@redhat.com)
- Speeding up tests (dmcphers@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.17-1
- Merge pull request #4581 from jwhonce/wip/head_key_flag
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049044 - Create more of .openshift_ssh environment (jhonce@redhat.com)
- Bug 1049044 - Restore setting ssh config settings for gear
  (jhonce@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.16-1
- Bug 1057219 - deconfigure didn't capture RuntimeError (jhonce@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.15-1
- Fix bug 1055653: handle exceptions from RestClient (pmorie@gmail.com)
- Merge pull request #4568 from danmcp/bug1049044
  (dmcphers+openshiftbot@redhat.com)
- Fixing essentials test (dmcphers@redhat.com)
- rsync private key over to new proxy gears (rchopra@redhat.com)
- Node Platform - Optionally generate application key (jhonce@redhat.com)
- Bug 1055371 (dmcphers@redhat.com)
- Merge pull request #4527 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4542 from bparees/duplicate_reporting
  (dmcphers+openshiftbot@redhat.com)
- fix bz 1049063 - do not throw exception for status call (rchopra@redhat.com)
- Bug 1025485 - Git push reports deployments to the broker twice
  (bparees@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.14-1
- Merge pull request #4547 from pmorie/bugs/1055653
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1055653 and improve post-receive output readability
  (pmorie@gmail.com)
- Just use an empty list to lock only the container (dmcphers@redhat.com)
- Merge pull request #4540 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1055961 - 'gear activate' must validate deployment id
  (contact@fabianofranz.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.13-1
- Fix test cases (dmcphers@redhat.com)
- Merge pull request #4536 from danmcp/bug982921
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4535 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 982921 (dmcphers@redhat.com)
- Merge pull request #4525 from jwhonce/bug/1055647
  (dmcphers+openshiftbot@redhat.com)
- Bug 966766 (dmcphers@redhat.com)
- Merge pull request #4528 from danmcp/bug1038559
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4524 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1038559 (dmcphers@redhat.com)
- Bug 1055647 - rhcsh quota check incorrect (jhonce@redhat.com)
- Better message for bug 1028633 (dmcphers@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Bug 1051015 - Look for UID_BEGIN, default to 1000 (lsm5@redhat.com)
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Merge pull request #4504 from bparees/revert_jenkins_dl
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4509 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4507 from jwhonce/bug/1054403
  (dmcphers+openshiftbot@redhat.com)
- Bug 1044223 (dmcphers@redhat.com)
- Bug 1054403 - Reset empty metadata.json file (jhonce@redhat.com)
- Revert "Bug 995807 - Jenkins builds fail on downloadable cartridges"
  (bparees@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Merge pull request #4488 from lsm5/new-node_conf
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4497 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4500 from mrunalp/bugs/1040113
  (dmcphers+openshiftbot@redhat.com)
- cleanup (dmcphers@redhat.com)
- Don't make deconfigure fail when cartridge isn't found in the cartridge
  repostory. (mrunalp@gmail.com)
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)
- Bug 1044225 (dmcphers@redhat.com)
- Merge pull request #4495 from jwhonce/wip/watchman
  (dmcphers+openshiftbot@redhat.com)
- do not use new values in node.conf BZ #1051015 (lsm5@redhat.com)
- lookup both old and new conf values BZ #1051015) (lsm5@redhat.com)
- keep consistency for new parameter description (lsm5@redhat.com)
- minor typo fix (lsm5@redhat.com)
- @port_begin also uses PROXY_MIN_PORT_NUM (lsm5@nagato.usersys.redhat.com)
- Card origin_node_374 - Port Watchman to Origin (jhonce@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Bug 1053782 - Make sure httpd restart succeed for broken httpd
  (mfojtik@redhat.com)
- Card origin_node_374 - Port Watchman to Origin (jhonce@redhat.com)
- Card origin_node_374 - Port Watchman to Origin Bug 1053423 - Restore
  OPENSHIFT_GEAR_DNS check to watchman Bug 1053397 - Fix encoding error reading
  spec file Bug 1053422 - Fix state vs. stop_lock check (jhonce@redhat.com)

* Wed Jan 15 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Merge pull request #4436 from bparees/jenkins_dl_cart
  (dmcphers+openshiftbot@redhat.com)
- Bug 995807 - Jenkins builds fail on downloadable cartridges
  (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4474 from
  liggitt/bug_1053099_write_downloadable_manifest_before_validating
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1053099: write downloadable manifest before validating extracted
  cartridge (jliggitt@redhat.com)
- Bug 1030777 - Remove gear dir even if gear not in passwd file
  (jhonce@redhat.com)
- Merge pull request #4468 from Miciah/bug-999117–oo-admin-cartridge-a
  -install-does-not-restorecon-the-installed-cartridge
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4467 from jwhonce/bug/1051833
  (dmcphers+openshiftbot@redhat.com)
- CartridgeRepository#install: Don't keep context (miciah.masters@gmail.com)
- Bug 1051833 - PathUtils.flock() not removing lock file (jhonce@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4458 from jwhonce/bug/1051984
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051984 - Add -w to quota command (jhonce@redhat.com)
- Merge pull request #4452 from bparees/zend_path_error
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4376 from pmorie/fix-tests
  (dmcphers+openshiftbot@redhat.com)
- Bug 1046618 - Syntax error is shown when SSH to zend application
  (bparees@redhat.com)
- Add retries in functional api (pmorie@gmail.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.6-1
- Card origin_node_319 - Add quota check to ssh login (jhonce@redhat.com)
- Card online_node_319 - Add quota check to git push (jhonce@redhat.com)
