%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global vendor_ruby /opt/rh/%{scl}/root/usr/share/ruby/vendor_ruby/
    %global mco_agent_root /opt/rh/%{scl}/root/usr/libexec/mcollective/mcollective/agent/
%else
    %global vendor_ruby /usr/share/ruby/vendor_ruby/
    %global mco_agent_root /usr/libexec/mcollective/mcollective/agent/
%endif

Summary:       M-Collective agent file for openshift-origin-msg-node-mcollective
Name:          openshift-origin-msg-node-mcollective
Version:       1.5.2
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      rubygem-openshift-origin-node
Requires:      mcollective
Requires:      facter
%if 0%{?fedora}%{?rhel} <= 6
Requires:      %{?scl:%scl_prefix}facter
%endif
Requires:      openshift-origin-msg-common
BuildArch:     noarch
Obsoletes:     openshift-mcollective-agent

%description
mcollective communication plugin

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{mco_agent_root}
mkdir -p %{buildroot}%{vendor_ruby}facter
mkdir -p %{buildroot}/etc/cron.minutely
mkdir -p %{buildroot}/usr/libexec/mcollective

cp src/openshift.rb %{buildroot}%{mco_agent_root}
cp -p facts/openshift_facts.rb %{buildroot}%{vendor_ruby}facter/
cp -p facts/openshift-facts %{buildroot}/etc/cron.minutely/
cp -p facts/update_yaml.rb %{buildroot}/usr/libexec/mcollective/

%files
%{mco_agent_root}openshift.rb
%{vendor_ruby}facter/openshift_facts.rb
%attr(0700,-,-) /usr/libexec/mcollective/update_yaml.rb
%attr(0700,-,-) /etc/cron.minutely/openshift-facts
/etc/cron.minutely/openshift-facts


%changelog
* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1255 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> active_capacity/max_active_apps/etc switched to
  gear-based accounting (lmeyer@redhat.com)
- Merge pull request #1238 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> reckon by gears (as opposed to git repos), add gear
  status facts (lmeyer@redhat.com)
- <facter> some code cleanup - no functional change (lmeyer@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Reduce logging noise in MCollective agent (ironcladlou@gmail.com)
- Switch calling convention to match US3143 (rmillner@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.3-1
- SSL support for custom domains. (mpatel@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Tue Dec 18 2012 Adam Miller <admiller@redhat.com> 1.3.2-1
- - oo-setup-broker fixes:  - Open dns ports for access to DNS server from
  outside the VM   - Turn on SELinux booleans only if they are off (Speeds up
  re-install)   - Added console SELinux booleans - oo-setup-node fixes:  -
  Setup mcollective to use broker IPs - Updates abstract cartridges to set
  proper order for php-5.4 and postgres-9.1 cartridges - Updated broker to add
  fedora 17 cartridges - Fixed facts cron job (kraman@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- Merge pull request #1052 from rmillner/BZ877321 (openshift+bot@redhat.com)
- Add username to filter list. (rmillner@redhat.com)
- Hide the password in mcollective logs. (rmillner@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Proper host name validation. (rmillner@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Security - Fix the full path to restorecon it was causing errors in the logs
  (tkramer@redhat.com)
- more mco 2.2 changes (dmcphers@redhat.com)
- repacking for mco 2.2 (dmcphers@redhat.com)
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Merge pull request #1002 from tdawson/tdawson/fed-update/msg-node-
  mcollective-1.1.4 (openshift+bot@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)
- Removed spec clutter for building on rhel5 (tdawson@redhat.com)
- mco value passing cleanup (dmcphers@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- add any validator for mco 2.2 (dmcphers@redhat.com)
- Various mcollective changes getting ready for 2.2 (dmcphers@redhat.com)
- Move force-stop into the the node library (ironcladlou@gmail.com)
- add backtraces to error conditions in agent (dmcphers@redhat.com)
- Changing same uid move to rsync (dmcphers@redhat.com)
- use /bin/env for cron (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- Add method to get the active gears (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ 876942:Disable threading until we can explore proper concurrency
  management (rmillner@redhat.com)
- Only use scl if it's available (ironcladlou@gmail.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- add config to gemspec (dmcphers@redhat.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
