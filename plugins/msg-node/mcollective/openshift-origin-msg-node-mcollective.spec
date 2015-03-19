%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global vendor_ruby /opt/rh/%{scl}/root/usr/share/ruby/vendor_ruby/
    %global mco_agent_root /opt/rh/%{scl}/root/usr/libexec/mcollective/mcollective/agent/
    %global update_yaml_root /opt/rh/ruby193/root/usr/libexec/mcollective/
%else
    %global vendor_ruby /usr/share/ruby/vendor_ruby/
    %global mco_agent_root /usr/libexec/mcollective/mcollective/agent/
    %global update_yaml_root /usr/libexec/mcollective/
%endif

Summary:       M-Collective agent file for openshift-origin-msg-node-mcollective
Name:          openshift-origin-msg-node-mcollective
Version: 1.30.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      rubygem-openshift-origin-node
Requires:      %{?scl:%scl_prefix}mcollective
Requires:      %{?scl:%scl_prefix}facter
Requires:      openshift-origin-msg-common
BuildArch:     noarch

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

cp -p src/openshift.rb %{buildroot}%{mco_agent_root}
cp -p facts/openshift_facts.rb %{buildroot}%{vendor_ruby}facter/
cp -p facts/openshift-facts %{buildroot}/etc/cron.minutely/
cp -p facts/update_yaml.rb %{buildroot}%{update_yaml_root}

%files
%{mco_agent_root}openshift.rb
%{vendor_ruby}facter/openshift_facts.rb
%attr(0700,-,-) %{update_yaml_root}/update_yaml.rb
%attr(0700,-,-) %config(noreplace) /etc/cron.minutely/openshift-facts

%changelog
* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.30.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Tue Feb 17 2015 Adam Miller <admiller@redhat.com> 1.29.2-1
- Sanitize credentials when logging request output (ironcladlou@gmail.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.29.1-1
- Merge pull request #6050 from codificat/bz1147116-move-fails-if-eth0-has-no-
  ip (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 57 (admiller@redhat.com)
- Use EXTERNAL_ETH_DEV to determine the node IP (pep@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.28.2-1
- node-msg: rm duplicate+inaccurate agent validations (lmeyer@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- mco agent: Fix single ssh key addition (thunt@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- node archive: improve doc, config logic (jolamb@redhat.com)
- broker/node: Add parameter for gear destroy to signal part of gear creation
  (jolamb@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump version to fix tags (admiller@redhat.com)
- Bug 1141304 - Add path to facts calls (jhonce@redhat.com)
- NodeLogger: add attrs to log, parse execute_parallel actions
  (lmeyer@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com>
- Bug 1141304 - Add path to facts calls (jhonce@redhat.com)
- NodeLogger: add attrs to log, parse execute_parallel actions
  (lmeyer@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Mon Jul 21 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Bug 1119609 - Support vendor in oo-admin-cartridge (jhonce@redhat.com)
- Card origin_node_401 - Support Vendor in CartridgeRepository
  (jhonce@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Mon Jun 30 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Merge pull request #5499 from jwhonce/wip/mcollective
  (dmcphers+openshiftbot@redhat.com)
- WIP Node Platform - Add reference_id and container_uuid to New Relic report
  (jhonce@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 12 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Bug 1101169 - Remove spurious report to New Relic (jhonce@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.22.3-2
- bumpspec to mass fix tags

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- Bug 1087964 - Allow move gear from non-districted/districted node to
  districted node. (rpenta@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- facter ipaddress does not always return the ip that we would want
  (bparees@redhat.com)
- Merge pull request #5153 from jwhonce/bug/1081249
  (dmcphers+openshiftbot@redhat.com)
- Bug 1081249 - Refactor SELinux module to be SelinuxContext singleton
  (jhonce@redhat.com)
- facter ipaddress does not always return the ip that we would want
  (bparees@redhat.com)
- Merge pull request #5095 from jwhonce/bug/1081249
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)
- Bug 1081249 - Synchronize access to selinux matchpath context
  (jhonce@redhat.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- auto expose ports upon configure, but only for scalable apps
  (rchopra@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Use NodeLogger in MCollective agent code (ironcladlou@gmail.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Bug 1064580 - Keep gear boosted during create (jhonce@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Merge pull request #4682 from danmcp/cleaning_specs
  (dmcphers+openshiftbot@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4679 from danmcp/cleanup_mco_ddl
  (dmcphers+openshiftbot@redhat.com)
- Cleanup mco ddl (dmcphers@redhat.com)
- Merge pull request #4616 from brenton/deployment_dir1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4671 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- fix the occluded haproxy gear's frontend upon move when two proxy gears clash
  on a node (rchopra@redhat.com)
- Fix for bug 1060760: Missing variable assignment for exception
  (abhgupta@redhat.com)
- Insure --with-initial-deployment-dir defaults to true in case the args isn't
  supplied. (bleanhar@redhat.com)
- Merge pull request #4624 from ironcladlou/dev/syslog
  (dmcphers+openshiftbot@redhat.com)
- Platform logging enhancements (ironcladlou@gmail.com)
- First pass at avoiding deployment dir create on app moves
  (bleanhar@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Card #185: sending app alias to all web_proxy gears (abhgupta@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4568 from danmcp/bug1049044
  (dmcphers+openshiftbot@redhat.com)
- Node Platform - Optionally generate application key (jhonce@redhat.com)
- Bug 1055371 (dmcphers@redhat.com)
- Bug 1056716 - Agent ignoring RuntimeError (jhonce@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Bug 1056480 - Removed random character in code (jhonce@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4534 from jwhonce/bug/1054825
  (dmcphers+openshiftbot@redhat.com)
- Bug 1054825 - Return better error message for resources exhausted
  (jhonce@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Bug 1044223 (dmcphers@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Allow multiple keys to added or removed at the same time (lnader@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.3-1
- Card online_node_319 - Add quota check to git push (jhonce@redhat.com)
- Fix for bug 1047957 (abhgupta@redhat.com)
- Bug 1045995 - Fix get_gears node implementation (rpenta@redhat.com)
