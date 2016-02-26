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
Version: 1.38.4
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
# non-scl json required for oo-cgroup-read
# Also see related bugs 924556 and 912215
Requires:      rubygem(json)
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
Requires:      mod_ssl
Requires:      openshift-origin-node-proxy
Requires:      openshift-origin-logshifter
Requires:      pam_openshift
Requires:      python
Requires:      quota
Requires:      rubygem(openshift-origin-common)
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
mkdir -p %{buildroot}%{_root_mandir}/man8/

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

cp -p misc/man8/*.8 %{buildroot}%{_root_mandir}/man8/

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
%attr(0751,-,-) %{_var}/log/openshift/node
%attr(0640,-,-) %ghost %{_var}/log/openshift/node/platform.log
%attr(0640,-,-) %ghost %{_var}/log/openshift/node/platform-trace.log
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
%config(noreplace) /etc/openshift/logshifter.conf
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.filter.rules
%attr(0600,-,-) %config(noreplace) /etc/openshift/iptables.nat.rules
%config(noreplace) /etc/openshift/env/*
%config(noreplace) /etc/logrotate.d/%{name}
%attr(0640,-,-) %config(noreplace) /etc/openshift/resource_limits.conf*
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

%{_root_mandir}/man8/oo-admin-ctl-tc.8.gz
%{_root_mandir}/man8/oo-admin-ctl-iptables-port-proxy.8.gz

%changelog
* Fri Oct 23 2015 Wesley Hearn <whearn@redhat.com> 1.38.4-1
- FrontendHttpServer: Recover from missing manifest (miciah.masters@gmail.com)

* Thu Oct 15 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.3-1
- Merge pull request #6247 from Miciah/bug-1111501-REPORT_BUILD_ANALYTICS-
  should-be-set-to-false-by-default (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6269 from dobbymoodge/rhcsh_cart-hook_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Log errs and skip bad lines when writing env vars (miciah.masters@gmail.com)
- fix rhcsh error output, clean up cart sub hooks (jolamb@redhat.com)
- REPORT_BUILD_ANALYTICS=false by default (miciah.masters@gmail.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 1.38.2-1
- Merge pull request #6236 from Miciah/make-console-functional-tests-less-
  random (dmcphers+openshiftbot@redhat.com)
- Delete deadcode in node functional test (miciah.masters@gmail.com)

* Thu Sep 17 2015 Unknown name 1.38.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 1.37.2-1
- Merge pull request #6220 from tiwillia/bz1250904
  (dmcphers+openshiftbot@redhat.com)
- Fixed AuthorizedKeyFile model test to run with other unit tests successfully
  (tiwillia@redhat.com)
- Bug 1250904 - Allow ssh keys to be replaced with an empty list
  (tiwillia@redhat.com)
- Removing oo-broker prefixes for admin commands (abhgupta@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.37.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.36.3-1
- Bug 1031796 - Install missing man pages (jhonce@redhat.com)
- Merge pull request #6173 from jwhonce/bug/1232907
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6174 from jwhonce/bug/1130488
  (dmcphers+openshiftbot@redhat.com)
- Fix test_start_cartridge_system_initiated_no_stoplock (jhonce@redhat.com)
- Bug 1130488 - Capture StandardError not Exception (jhonce@redhat.com)
- Bug 1232907 - Only unidle on start by user (jhonce@redhat.com)
- Bug 965364 - Restore creating gear with no git template (jhonce@redhat.com)
- Merge pull request #6168 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1139538 (dmcphers@redhat.com)
- Merge pull request #6165 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Fixes 1140552 and 1140558 (dmcphers@redhat.com)
- Merge pull request #6091 from sdodson/bz1198777
  (dmcphers+openshiftbot@redhat.com)
- Fix spelling errors (dmcphers@redhat.com)
- Change the priority number for openshift-tc (william17.burton@gmail.com)
- Scale inodes by 80k per GB in example configs (sdodson@redhat.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 1.36.2-1
- Bug 1136425 Bug link https://bugzilla.redhat.com/show_bug.cgi?id=1136425
  Disable password aging for gear users (tiwillia@redhat.com)
- BZ1216220 - oo-snapshot fails when run outside of a gear
  (tiwillia@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.36.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)
- Don't delete archives if tar returns !0 (jolamb@redhat.com)

* Wed Feb 25 2015 Adam Miller <admiller@redhat.com> 1.35.4-1
- Sanitize credentials during post-configure logging (ironcladlou@gmail.com)

* Tue Feb 24 2015 Adam Miller <admiller@redhat.com> 1.35.3-1
- Bug 1190856 - Allow Operator to stop gear with .stop_lock (jhonce@redhat.com)

* Tue Feb 17 2015 Adam Miller <admiller@redhat.com> 1.35.2-1
- Bug 1192557 - Fixed creating application using --from-code=empty when
  database cartridge is also specified. (maszulik@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.35.1-1
- bump spec to fix tags (admiller@redhat.com)
- Handle all encodings during regex comparisons (ironcladlou@gmail.com)
- Merge pull request #6044 from detiber/bz1179006
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6065 from ncdc/bz1187829-exclude-GEM_HOME-from-gear-
  commands (dmcphers+openshiftbot@redhat.com)
- Protect 'gear' command from gems in $GEM_HOME (agoldste@redhat.com)
- Allow gear prioritization in startall/stopall (agrimm@redhat.com)
- Merge pull request #6010 from a13m/bz1171289-master
  (dmcphers+openshiftbot@redhat.com)
- Fix tests for OOMPlugin (agrimm@redhat.com)
- Bug 1179006 - CartridgeRepository latest_versions (jdetiber@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com>
- Handle all encodings during regex comparisons (ironcladlou@gmail.com)
- Merge pull request #6044 from detiber/bz1179006
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #6065 from ncdc/bz1187829-exclude-GEM_HOME-from-gear-
  commands (dmcphers+openshiftbot@redhat.com)
- Protect 'gear' command from gems in $GEM_HOME (agoldste@redhat.com)
- Allow gear prioritization in startall/stopall (agrimm@redhat.com)
- Merge pull request #6010 from a13m/bz1171289-master
  (dmcphers+openshiftbot@redhat.com)
- Fix tests for OOMPlugin (agrimm@redhat.com)
- Bug 1179006 - CartridgeRepository latest_versions (jdetiber@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.34.1-1
- bump spec to fix tags (admiller@redhat.com)
- Merge pull request #6027 from sosiouxme/bz1155677-secondaryha-fqdn
  (dmcphers+openshiftbot@redhat.com)
- Bug 1178188 - Enhance logging ApplicationContainer#activate_local_gear
  failures (jhonce@redhat.com)
- node: fix secondary haproxy app fqdn (lmeyer@redhat.com)
- Revert "we do not want %%ghost-ed log files" (lmeyer@redhat.com)
- Removing debug logging added as a part of #4059 for bug 1025043
  (j.hadvig@gmail.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com>
- Merge pull request #6027 from sosiouxme/bz1155677-secondaryha-fqdn
  (dmcphers+openshiftbot@redhat.com)
- Bug 1178188 - Enhance logging ApplicationContainer#activate_local_gear
  failures (jhonce@redhat.com)
- node: fix secondary haproxy app fqdn (lmeyer@redhat.com)
- Revert "we do not want %%ghost-ed log files" (lmeyer@redhat.com)
- Removing debug logging added as a part of #4059 for bug 1025043
  (j.hadvig@gmail.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.33.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)
- Bug 1163964: Clarify message when ssh repository url fails
  (jliggitt@redhat.com)
- Bug 1163910 - Rename watchman log files (jhonce@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.32.3-1
- Merge pull request #5954 from ncdc/bug/1161072-vhost-multi-ha-app-dns
  (dmcphers+openshiftbot@redhat.com)
- Register app dns vhost for secondary haproxy gears (agoldste@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 1.32.2-1
- Merge pull request #5910 from a13m/aggressive-oom-kill
  (dmcphers+openshiftbot@redhat.com)
- Fix unit test for oom_plugin (agrimm@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.32.1-1
- Fix formatting (dmcphers@redhat.com)
- Bug 1160494 - Protect Ops stop_gear from cartridge errors (jhonce@redhat.com)
- Bug 1160752 - Add Watchman plugin to clean up vhost configurations
  (jhonce@redhat.com)
- Merge pull request #5813 from sztsian/bz1073725
  (dmcphers+openshiftbot@redhat.com)
- Bug 1160652 - Set defaults for the new crt/key/chain apache vhost plugin
  configuration (bleanhar@redhat.com)
- make the default crt/key/chain file to be configurable in vhost template
  (rchopra@redhat.com)
- Merge branch 'bz1073725' of https://github.com/sztsian/origin-server into
  bz1073725 (zsun@fedoraproject.org)
- Merge branch 'master' of https://github.com/openshift/origin-server into
  bz1073725 (zsun@fedoraproject.org)
- bz 1116750 fix the description of command "aliases" (zsun@fedoraproject.org)
- add unit test function for bz 1073725 (sztsian@gmail.com)
- iptables-port-proxy: use -n on iptables -L (lmeyer@redhat.com)
- oo-trap-user: preserve quoting on shell commands (lmeyer@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- bz 1073725 https://bugzilla.redhat.com/show_bug.cgi?id=1073725 Test if the
  env exists before reporting exceeded USER_VARIABLE_MAX_COUNT. If all the env
  exists, just update them, otherwise report the error (zsun@fedoraproject.org)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.31.7-1
- Merge pull request #5890 from sosiouxme/rfe1134139
  (dmcphers+openshiftbot@redhat.com)
- oo-trap-user: make gear login syslog optional (lmeyer@redhat.com)
- ssh keys: remove special logins (lmeyer@redhat.com)
- ssh_authorized_keys: shell-escape the login (lmeyer@redhat.com)
- fix whitespace (lmeyer@redhat.com)
- app container proxy: Add user login to ssh authorized_keys file
  (thunt@redhat.com)
- oo-trap-user: Add support for OPENSHIFT_LOGIN environment variable
  (thunt@redhat.com)
- Bug 1146750 - Do not remove PI tmp directory when tidying (jhonce@redhat.com)
- Bug 1153542 - Correct usage message (jhonce@redhat.com)
- node: configure vhost as default frontend instead of mod-rewrite
  (lmeyer@redhat.com)

* Mon Oct 13 2014 Adam Miller <admiller@redhat.com> 1.31.6-1
- Bug 1151648 - Skip any files in .cartridge_repository directory
  (jhonce@redhat.com)

* Thu Oct 09 2014 Adam Miller <admiller@redhat.com> 1.31.5-1
- Bug 1148252 - Add status message (jhonce@redhat.com)
- WIP Node Platform - Skip partial deployments (jhonce@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.31.4-1
- node.conf: correct IP_ADDRESS_WRAPAROUND_OFFSET param (lmeyer@redhat.com)
- delete partial/broken archive on "tar" command failure (jolamb@redhat.com)
- node archive: improve doc, config logic (jolamb@redhat.com)
- broker/node: Add parameter for gear destroy to signal part of gear creation
  (jolamb@redhat.com)
- v2_cart_model: allow archiving of destroyed gears (jolamb@redhat.com)

* Tue Sep 30 2014 Adam Miller <admiller@redhat.com> 1.31.3-1
- Bug 1146767 - Check if hook file exists before showing notice
  (mfojtik@redhat.com)
- Bug 1145696 - Print notice to users when pushing non-executable action hooks
  (mfojtik@redhat.com)

* Tue Sep 23 2014 Adam Miller <admiller@redhat.com> 1.31.2-1
- Expose haproxy-sni-proxy mapped ports as environmental variables
  (bparees@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.31.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)
- Merge pull request #5794 from sosiouxme/improve-platform-logging-bz1139359
  (dmcphers+openshiftbot@redhat.com)
- NodeLogger: add attrs to log, parse execute_parallel actions
  (lmeyer@redhat.com)

* Tue Sep 09 2014 Adam Miller <admiller@redhat.com> 1.30.5-1
- Bug 1024531 - /proc/net provides too much information (jhonce@redhat.com)

* Mon Sep 08 2014 Adam Miller <admiller@redhat.com> 1.30.4-1
- Merge pull request #5787 from bparees/unique_domain_env_vars
  (dmcphers+openshiftbot@redhat.com)
- check for domain environment variable uniqueness on app create
  (bparees@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.30.3-1
- Merge pull request #3516 from Filirom1/patch-1
  (dmcphers+openshiftbot@redhat.com)
- node.conf: comments for external port range (lmeyer@redhat.com)
- Merge pull request #5772 from jwhonce/wip/node_essentials
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5753 from sosiouxme/bz1133936
  (dmcphers+openshiftbot@redhat.com)
- node conf: supply resource_limit.conf examples (lmeyer@redhat.com)
- WIP Node Platform - Restore cartridge_repository_web_func_test.rb
  (jhonce@redhat.com)
- WIP Node Platform - Stabilize cartridge_repository_web_func_test.rb
  (jhonce@redhat.com)
- Merge pull request #5742 from bparees/resource_limits
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5741 from brenton/BZ1124094
  (dmcphers+openshiftbot@redhat.com)
- add new resource limits template for xpaas cartridges (bparees@redhat.com)
- Bug 1124094 - oo-admin-upgrade does not work for unsupported cartridges
  (bleanhar@redhat.com)
- fix http://stackoverflow.com/questions/4826639/repack-of-git-repository-fails
  (filirom1@gmail.com)

* Fri Aug 22 2014 Adam Miller <admiller@redhat.com> 1.30.2-1
- Merge pull request #5738 from bparees/sni_port_message
  (dmcphers+openshiftbot@redhat.com)
- The output message about TLS URLs is not clear when creating jboss-amq
  cartridge (bparees@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.29.4-1
- Fix bug 1131089: use correct mysql client for 5.5 (pmorie@gmail.com)

* Thu Aug 14 2014 Adam Miller <admiller@redhat.com> 1.29.3-1
- Merge pull request #5683 from soltysh/binary_deploy_tests
  (dmcphers+openshiftbot@redhat.com)
- Reafactored binary deployment tests for running them faster.
  (maszulik@redhat.com)

* Tue Aug 12 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Update get_quota to handle grace values (agoldste@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Merge pull request #5441 from dobbymoodge/sclmongo
  (dmcphers+openshiftbot@redhat.com)
- Bug 1121217 - Symbol leak in Throttler cgroup code (jhonce@redhat.com)
- Bug 1121217 - Symbol leak in Throttler cgroup code (jhonce@redhat.com)
- mongodb cart: clean up `mongodb_context`, `rhcsh` (jolamb@redhat.com)
- mongodb cart: Support non-SCL systems (jolamb@redhat.com)
- mongodb cart: address bugs with scaled carts (jolamb@redhat.com)
- <mongodb cart> adapt to use SCL-provided mongodb (jolamb@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.28.5-1
- Merge pull request #5622 from Miciah/bug-1121200-oo-iptables-port-proxy-
  getaddr-check-ipaddr (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5640 from a13m/bz1122166
  (dmcphers+openshiftbot@redhat.com)
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)
- oo-iptables-port-proxy: getaddr: check ipaddr (miciah.masters@gmail.com)
- oo-iptables-port-proxy: Rewrite getaddr (miciah.masters@gmail.com)

* Mon Jul 28 2014 Adam Miller <admiller@redhat.com> 1.28.4-1
- Merge pull request #5625 from Miciah/bug-1121238-fix-frontend-
  system_proxy_delete-and-system_proxy_set-methods-return-value-ordering
  (dmcphers+openshiftbot@redhat.com)
- Fix typo (dmcphers@redhat.com)
- Fix frontend system_proxy_delete/system_proxy_set (miciah.masters@gmail.com)

* Thu Jul 24 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Card origin_node_401 - Fix extended tests (jhonce@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- Bug 1118588 - Fix oo-cgroup-read for parsing blkio stats (agrimm@redhat.com)
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Mon Jul 07 2014 Adam Miller <admiller@redhat.com> 1.27.4-1
- Bug 1116135 - Add -u to bash sdk pgrep calls (jhonce@redhat.com)
- Bug 1116062 - Remove spurious call to facter (jhonce@redhat.com)

* Tue Jul 01 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Merge pull request #5561 from jwhonce/bug/1111077
  (dmcphers+openshiftbot@redhat.com)
- Bug 1111077 - Enforce FrontendHttpServer state to match .state file
  (jhonce@redhat.com)

* Mon Jun 30 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Merge pull request #5499 from jwhonce/wip/mcollective
  (dmcphers+openshiftbot@redhat.com)
- WIP Node Platform - Add reference_id and container_uuid to New Relic report
  (jhonce@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- Revert "Bug 1111077 - Ensure frontend and state in sync" (jhonce@redhat.com)
- Bug 1111077 - Ensure frontend and state in sync (jhonce@redhat.com)
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.26.8-1
- Merge pull request #5523 from jhadvig/status
  (dmcphers+openshiftbot@redhat.com)
- Making apache server-status optional with a marker (jhadvig@redhat.com)
- Merge pull request #5478 from a13m/bz1104902
  (dmcphers+openshiftbot@redhat.com)
- Bug 1104902 - Fix unit tests (jhonce@redhat.com)
- Bug 1104902 - Fix several bugs in OOM Plugin app restarts (agrimm@redhat.com)

* Wed Jun 18 2014 Adam Miller <admiller@redhat.com> 1.26.7-1
- Merge pull request #5522 from pmorie/bugs/1108951
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5518 from jwhonce/bug/1110283
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1108951: correct nodejs update-configuration function
  (pmorie@gmail.com)
- Bug 1110283 - Escape Source-Url during clone/copy (jhonce@redhat.com)

* Tue Jun 17 2014 Adam Miller <admiller@redhat.com> 1.26.6-1
- Merge pull request #5513 from pmorie/bugs/1108951
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1108951: fix rhcsh 'node' wrapper (pmorie@gmail.com)

* Mon Jun 16 2014 Troy Dawson <tdawson@redhat.com> 1.26.5-1
- Merge pull request #5509 from pmorie/bugs/1108951
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1108951: add rhcsh wrapper for nodejs (pmorie@gmail.com)

* Fri Jun 13 2014 Adam Miller <admiller@redhat.com> 1.26.4-1
- Merge pull request #5503 from a13m/bz1103849
  (dmcphers+openshiftbot@redhat.com)
- Bug 1103849 - Remove quota for deleted gear by uid (agrimm@redhat.com)

* Wed Jun 11 2014 Adam Miller <admiller@redhat.com> 1.26.3-1
- Merge pull request #5496 from jwhonce/bug/1101164
  (dmcphers+openshiftbot@redhat.com)
- Bug 1101164 - Support gear registry with no web framework (jhonce@redhat.com)
- Merge pull request #5494 from jwhonce/wip/oom_plugin_test
  (dmcphers+openshiftbot@redhat.com)
- Bug 1106413: psql wrapper always return zero even if psql command is already
  failed (jhadvig@redhat.com)
- WIP Node Platform - Add tests for OOM Plugin (jhonce@redhat.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Merge pull request #5470 from brenton/BZ1064631
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5481 from jwhonce/bug/1105232
  (dmcphers+openshiftbot@redhat.com)
- Bug 1105232 - Output rsync results from gear distribute (jhonce@redhat.com)
- Bug 1064631 - Wrap UID-based ip addresses and netclasses calculations
  (bleanhar@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- Bug 1101499: Adjusting logic of gear state restoration (jhadvig@redhat.com)
- Merge pull request #5466 from jhadvig/post_restore_stop
  (dmcphers+openshiftbot@redhat.com)
- Document bash SDK httpd helper functions (vvitek@redhat.com)
- Bug 1101499: Stopping secondary gear after restore snapshot for scaleable app
  (jhadvig@redhat.com)
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.6-1
- Merge pull request #5443 from a13m/bz1100518
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5126 from mmahut/handle_zombie
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-gear: error out if we're not able to move the cgroup pid into the
  default group because the process does not exist or is a zombie process
  (mmahut@redhat.com)
- Fix throttler math in monitored_gear_test (agrimm@redhat.com)
- Move cgroup sample timestamp insertion and fix unit test (agrimm@redhat.com)
- Bug 1101156 - Always initialize container_plugin (jhonce@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.25.5-1
- Merge pull request #5447 from jwhonce/bug/1100619
  (dmcphers+openshiftbot@redhat.com)
- Bug 1100619 - Uppercase primary cartridge name for use in env vars
  (jhonce@redhat.com)

* Fri May 23 2014 Adam Miller <admiller@redhat.com> 1.25.4-1
- Merge pull request #5438 from jwhonce/bug/1099754
  (dmcphers+openshiftbot@redhat.com)
- Bug 1099754 - Set default_command to help (jhonce@redhat.com)

* Thu May 22 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- WIP Node Platform - Skip syslog_plugin test if it has been disabled
  (jhonce@redhat.com)

* Wed May 21 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Merge pull request #5434 from jwhonce/bug/1099772
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5433 from jwhonce/bug/1099835
  (dmcphers+openshiftbot@redhat.com)
- Bug 1099772 - Add message for unidle on secondary gear (jhonce@redhat.com)
- Bug 1099835 - Add missing require (jhonce@redhat.com)
- Disable OOM kills for gear cgroups (agrimm@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- Bug 1088623 - Removed unused .uservars directory references
  (jhonce@redhat.com)
- Use the local1 facility for Syslog trace logs (ironcladlou@gmail.com)
- Bug 1096591 - Escape filenames for downloadable cartridges
  (jhonce@redhat.com)
- Prevent unwanted syslog message interpolation (ironcladlou@gmail.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Troy Dawson <tdawson@redhat.com> 1.24.7-1
- Bug 1094541 - check for null values (lnader@redhat.com)
- Merge pull request #5383 from jwhonce/bug/1091433
  (dmcphers+openshiftbot@redhat.com)
- Bug 1091433 - Add setting to detune GearStatePlugin (jhonce@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 1.24.6-1
- Merge pull request #5380 from jwhonce/bug/1093197
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5379 from mrunalp/bug/1052302
  (dmcphers+openshiftbot@redhat.com)
- Bug 1083197 - remove NULL's from environment variables (jhonce@redhat.com)
- Bug 1052302: Add windowMemory setting for git repos. (mrunalp@gmail.com)
- Merge pull request #5375 from ironcladlou/scalable-unidling
  (dmcphers+openshiftbot@redhat.com)
- Support unidling scalable apps (ironcladlou@gmail.com)

* Fri May 02 2014 Adam Miller <admiller@redhat.com> 1.24.5-1
- rhcsh: Fix quota check if quotas disabled (miciah.masters@gmail.com)

* Tue Apr 29 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Bug 1092077 - Adding comment for the default PLATFORM_LOG_CLASS.
  (bleanhar@redhat.com)

* Mon Apr 28 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Merge pull request #5288 from dobbymoodge/BZ1088005
  (dmcphers+openshiftbot@redhat.com)
- v2_cart_model: guarantee user env vars override (jolamb@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.9-1
- Merge pull request #5299 from bparees/psql_unary
  (dmcphers+openshiftbot@redhat.com)
-  Meet "unary operator expected" error when use psql in rhcsh but postgresql
  is not added to app (bparees@redhat.com)

* Thu Apr 17 2014 Troy Dawson <tdawson@redhat.com> 1.23.8-1
- Merge pull request #5291 from lnader/bugs (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5296 from jwhonce/bug/1086886
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086886 - Don't read managed_file.yml twice (jhonce@redhat.com)
- Bug 1088620 - Check for empty OPENSHIFT_PRIMARY_CARTRIDGE_DIR values
  (lnader@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.7-1
- Bug 1061926 - Use lock file to prevent race between idle/unidle
  (jhonce@redhat.com)

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.6-1
- remove unused code (dmcphers@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.5-1
- Improving the inline docs for TRAFFIC_CONTROL_ENABLED in node.conf
  (bleanhar@redhat.com)
- Bug 1086427 - JSON.load() allowed empty JSON files (jhonce@redhat.com)
- Bug 1086427 - Do not use JSON.load() with untrusted JSON (jhonce@redhat.com)
- Bug 1086886 - Add guard for empty managed_files.yml (jhonce@redhat.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Merge pull request #5245 from lnader/bugs (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5234 from brenton/BZ1086691
  (dmcphers+openshiftbot@redhat.com)
- Fix formatting (dmcphers@redhat.com)
- Fix typo (dmcphers@redhat.com)
- Bug 1086691 - Accessing a Gear by ssh shows "Your application is out of disk
  space" when "quota" command is missing (bleanhar@redhat.com)
- Merge pull request #5219 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086886 - Check for empty managed_files.yml and return a better error
  message (lnader@redhat.com)
- Merge pull request #5239 from ncdc/bug/1086549
  (dmcphers+openshiftbot@redhat.com)
- DNS may have been stored as mixed case, but should always be used downcased
  (rchopra@redhat.com)
- Don't show backtrace when metrics script times out (andy.goldstein@gmail.com)
- Merge pull request #5231 from mfojtik/bugzilla/1070173
  (dmcphers+openshiftbot@redhat.com)
- Bug 1070173 - Add '-v' option for oo-admin-ctl-tc to turn verbose output
  (mfojtik@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- cleanup whitespace (dmcphers@redhat.com)
- Add platform attribute to cartridge serialization and fixed tests
  (abhgupta@redhat.com)
- Merge pull request #5208 from bparees/haproxy_scale
  (dmcphers+openshiftbot@redhat.com)
- Add the ability to adjust when haproxy shutsdown the app cart in the lead
  gear (bparees@redhat.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5212 from ironcladlou/upgrade-error-handling
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5200 from ncdc/metrics (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5207 from ncdc/selinux-turbo-boost
  (dmcphers+openshiftbot@redhat.com)
- Handle missing/invalid HTTP response during upgrade validation
  (ironcladlou@gmail.com)
- Speed up chcon calls (andy.goldstein@gmail.com)
- Metrics - code review changes (andy.goldstein@gmail.com)
- Metrics (andy.goldstein@gmail.com)
- Metrics work (teddythetwig@gmail.com)
- Metrics work (teddythetwig@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Adding new default setting for traffic control (bleanhar@redhat.com)
- Bug 1075760 - Allow traffic control to be disabled (bleanhar@redhat.com)
- Merge pull request #5153 from jwhonce/bug/1081249
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5141 from bparees/facter
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5161 from bparees/unrevert_restore_state
  (dmcphers+openshiftbot@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Bug 1081249 - Fix up code after reviews (jhonce@redhat.com)
- hide output from pgrep (bparees@redhat.com)
- Bug 1081249 - Refactor SELinux module to be SelinuxContext singleton
  (jhonce@redhat.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- Node Platform - Remove ruby version of oo-trap-user (jhonce@redhat.com)
- Merge pull request #5131 from bparees/revert_restore_state
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5135 from bparees/process_running_check
  (dmcphers+openshiftbot@redhat.com)
- fix process running check to use proper return code check
  (bparees@redhat.com)
- Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore" (bparees@redhat.com)
- Adding a function test for outbound traffic control (bleanhar@redhat.com)
- Adding error checking for outbound tc settings (bleanhar@redhat.com)
- Bug 1076217 - Making the tc outbound settings configurable
  (bleanhar@redhat.com)
- facter ipaddress does not always return the ip that we would want
  (bparees@redhat.com)
- Bug 1082488 - Silence error message on node with no gears (jhonce@redhat.com)
- Merge pull request #5095 from jwhonce/bug/1081249
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5100 from jwhonce/bug/1081441
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)
- Bug 1081249 - Synchronize access to selinux matchpath context
  (jhonce@redhat.com)
- Bug 1081441 - unprivileged_unidle not updating idler.txt (jhonce@redhat.com)
- Bug 1081249 - Synchronize access to selinux matchpath context
  (jhonce@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.10-1
- Merge pull request #5094 from ironcladlou/binary-deploy-bug
  (dmcphers+openshiftbot@redhat.com)
- Fix raise during initial deployment meta creation (ironcladlou@gmail.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.9-1
- Sanitize usage of 'ps' command in Bash SDK (mfojtik@redhat.com)
- Bug 1081367 - Use process_running in shutdown_httpd_graceful
  (mfojtik@redhat.com)
- Merge pull request #5078 from jwhonce/bug/1065276
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5062 from bparees/ctl_app_restart
  (dmcphers+openshiftbot@redhat.com)
- Bug 1065276 - Skip *.rpmnew when loading environments (jhonce@redhat.com)
- Action hooks run are not consistent between `ctl_all restart` and `rhc app-
  restart` (bparees@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.8-1
- Merge pull request #5075 from ironcladlou/force-stop-fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5066 from dobbymoodge/BZ1077077
  (dmcphers+openshiftbot@redhat.com)
- Check for pid existence in graceful shutdown func (ironcladlou@gmail.com)
- Bug 1078814: Adding more validations for cartridge manifests
  (abhgupta@redhat.com)
- Merge pull request #5065 from bparees/logdir_refs
  (dmcphers+openshiftbot@redhat.com)
- node spec: add rubygem(json) Bug 1077077 (jolamb@redhat.com)
- write logs to expected jboss filename so watchman finds it
  (bparees@redhat.com)
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.7-1
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.22.6-1
- Merge pull request #5032 from a13m/oo-sched-jobs-nogrep
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5037 from jwhonce/bug/1079261
  (dmcphers+openshiftbot@redhat.com)
- fix vendor match on cron cart check (agrimm@redhat.com)
- Bug 1079261 - Update to support new cgroup mounts (jhonce@redhat.com)
- Remove excessive grep invocations from oo-scheduled-jobs (agrimm@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Merge pull request #5029 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #5021 from ironcladlou/initial-build-limiting
  (dmcphers+openshiftbot@redhat.com)
- Fixing extended tests (dmcphers@redhat.com)
- Limit initial build client output to 10Kb (ironcladlou@gmail.com)
- fix default expose_port option to false (rchopra@redhat.com)
- Update tests to not use any installed gems and use source gems only Add
  environment wrapper for running broker util scripts (jforrest@redhat.com)
- Bug 1079072 - Hide quota error messsages (jhonce@redhat.com)
- Merge pull request #5003 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5002 from tdawson/2014-03/tdawson/move-node-requires
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #5001 from bparees/missing_ident
  (dmcphers+openshiftbot@redhat.com)
- auto expose ports upon configure, but only for scalable apps
  (rchopra@redhat.com)
- move some node requires to diy cartridge dependencies (tdawson@redhat.com)
- Check for cartridge IDENT before starting gear upgrade process
  (bparees@redhat.com)
- error out of upgrade as soon as a bad gear configuration is detected
  (bparees@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bug 1061926 - Ensure frontend unidled if backend unidled (jhonce@redhat.com)
- cart configure should expose ports as well (rchopra@redhat.com)

* Tue Mar 18 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #4976 from mfojtik/bugzilla/1076626
  (dmcphers+openshiftbot@redhat.com)
- Bug 1076626 - Fix LD_LIBRARY_PATH for cron_runjobs (mfojtik@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Merge pull request #4965 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1076366 - Need to migrate 'platform' into gear-registry.json for scaling
  applications (vlad.iovanov@uhurusoftware.com)
- Bug 1067008 - Delete gear when missing a Cartridge Ident (jhonce@redhat.com)
- Card origin_cartridge_133 - Maintain application state across
  snapshot/restore (mfojtik@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Merge pull request #4956 from bparees/binary_deploy
  (dmcphers+openshiftbot@redhat.com)
- undo unnecessary reording of permissions (bparees@redhat.com)
- Merge pull request #4944 from UhuruSoftware/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1067008 - Guard gear delete from missing Cartridge IDENT
  (jhonce@redhat.com)
- Merge pull request #4943 from bparees/binary_deploy
  (dmcphers+openshiftbot@redhat.com)
- Add support for multiple platforms in OpenShift. Changes span both the broker
  and the node. (vlad.iovanov@uhurusoftware.com)
- Bug 1075673 - Unable to perform git deploy after binary deployment
  (bparees@redhat.com)
- Bug 1075221 - Prevent mcollective and watchman restart after logrotate
  (mfojtik@redhat.com)
- Adding tests for cartridge sdk version comparisons (bleanhar@redhat.com)
- Adding methods for version comparisons to the cartridge sdk
  (bleanhar@redhat.com)
- Use NodeLogger in MCollective agent code (ironcladlou@gmail.com)
- Adding additional gear extended queue (dmcphers@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Merge pull request #4895 from pmorie/bugs/1072663
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1072663, 1072663: (pmorie@gmail.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Bug 1072249 (dmcphers@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4865 from pmorie/bugs/1066980
  (dmcphers+openshiftbot@redhat.com)
- msg change for tc when its already active (rchopra@redhat.com)
- Fix bug 1066980: relax matching conditions for secondary groups in scalable
  app (pmorie@gmail.com)
- fix bz1071473 - add fixaddr to the chkconfiged service 'openshift-iptables-
  port-proxy' (rchopra@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Bug 1071721 - Show errors when env vars aren't found (dmcphers@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #4856 from jwhonce/origin_node_39
  (dmcphers+openshiftbot@redhat.com)
- Card origin_node_39 - Fix unit test (jhonce@redhat.com)
- check if gears are already throttled.
  https://bugzilla.redhat.com/show_bug.cgi?id=1071167 (rchopra@redhat.com)
- Python - DocumentRoot logic, Repository Layout simplification
  (vvitek@redhat.com)
- Reworked rhcsh to be more efficient (mfojtik@redhat.com)
- Update oo-trap-user to handle LD_LIBRARY_PATH_ELEMENT (mfojtik@redhat.com)
- Use SDK functions in rhcsh and cronjob task to build PATH/LD_LIBRARY_PATH
  (mfojtik@redhat.com)
- Card origin_cartridge_31 - Add support for LD_LIBRARY_PATH_ELEMENT to node
  (mfojtik@redhat.com)
- Merge pull request #4846 from jwhonce/origin_node_39
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4838 from ncdc/bug/1070656-require-args
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4844 from pmorie/activate
  (dmcphers+openshiftbot@redhat.com)
- Card origin_node_39 - Fix functional tests (jhonce@redhat.com)
- Relax catch clause for errors during activation (pmorie@gmail.com)
- Validate required args exist for gear actions (andy.goldstein@gmail.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Card origin_node_39 - Make test optional (jhonce@redhat.com)
- Merge pull request #4829 from jwhonce/origin_node_39
  (dmcphers+openshiftbot@redhat.com)
- Card origin_node_39 - Fix unit test (jhonce@redhat.com)
- Bug 1068891 - Remove redundant call to date (jhonce@redhat.com)
- Card origin_node_39 - Introduce GearStatePlugin (jhonce@redhat.com)
- fix PHP functional api test (vvitek@redhat.com)
- Bug 1056713 - Remove nil from output (jhonce@redhat.com)
- Merge pull request #4776 from jwhonce/origin_node_39
  (dmcphers+openshiftbot@redhat.com)
- Bug 1067031 - Do not include old versions of carts in latest carts just
  because they have a unique software version (dmcphers@redhat.com)
- Fix typo (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)
- Merge pull request #4788 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1025195 - Reset quota to the min extra (dmcphers@redhat.com)
- Card origin_node_39 - Have Watchman attempt honor state of gear
  (jhonce@redhat.com)

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
