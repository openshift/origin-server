Summary:        Utility scripts for the OpenShift Origin broker
Name:           openshift-origin-broker-util
Version:        1.0.1
Release:        1%{?dist}
Group:          Network/Daemons
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}-%{version}.tar.gz

Requires:       openshift-broker
Requires:       ruby(abi) >= 1.8
%if 0%{?fedora} >= 17
BuildRequires:  rubygems-devel
%else
BuildRequires:  rubygems
%endif
BuildArch:      noarch

%description
This package contains a set of utility scripts for the broker.  They must be
run on a broker instance.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
cp oo-* %{buildroot}%{_bindir}/
cp complete-origin-setup %{buildroot}%{_bindir}/

mkdir -p %{buildroot}%{_mandir}/man8/
cp man/*.8 %{buildroot}%{_mandir}/man8/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(0755,-,-) %{_bindir}/oo-admin-chk
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-app
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-district
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-domain
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-template
%attr(0755,-,-) %{_bindir}/oo-admin-ctl-user
%attr(0755,-,-) %{_bindir}/oo-admin-move
%attr(0755,-,-) %{_bindir}/oo-register-dns
%attr(0755,-,-) %{_bindir}/oo-setup-bind
%attr(0755,-,-) %{_bindir}/oo-setup-broker
%attr(0755,-,-) %{_bindir}/oo-accept-broker
%attr(0755,-,-) %{_bindir}/complete-origin-setup
%doc LICENSE
%{_mandir}/man8/oo-admin-chk.8.gz
%{_mandir}/man8/oo-admin-ctl-app.8.gz
%{_mandir}/man8/oo-admin-ctl-district.8.gz
%{_mandir}/man8/oo-admin-ctl-domain.8.gz
%{_mandir}/man8/oo-admin-ctl-template.8.gz
%{_mandir}/man8/oo-admin-ctl-user.8.gz
%{_mandir}/man8/oo-admin-move.8.gz
%{_mandir}/man8/oo-register-dns.8.gz
%{_mandir}/man8/oo-setup-bind.8.gz
%{_mandir}/man8/oo-setup-broker.8.gz
%{_mandir}/man8/oo-accept-broker.8.gz

%changelog
* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- Added man pages for broker-util/node-util, port complete-origin-setup to bash
  (admiller@redhat.com)
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
- fix broker-util version number (admiller@redhat.com)
- Updating broker setup script (kraman@gmail.com)
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)
- sudo is not allowed within a command that is being executed using su
  (abhgupta@redhat.com)
- Merge pull request #741 from pravisankar/dev/ravi/bug/853082
  (openshift+bot@redhat.com)
- Fix for bug# 853082 (rpenta@redhat.com)
- Updating setup-broker, moving broken gem setup to after bind plugn setup is
  completed. Fixing cucumber test helper to use correct selinux policies
  (kraman@gmail.com)
- Merge pull request #737 from sosiouxme/master (dmcphers@redhat.com)
- have openshift-broker report bundler problems rather than silently fail. also
  fix typo in oo-admin-chk usage (lmeyer@redhat.com)
- Bug 868858 (dmcphers@redhat.com)
- Fixing Origin build scripts (kraman@gmail.com)
- removing remaining cases of SS and config.ss (dmcphers@redhat.com)
- Fix for Bugs# 853082, 847572 (rpenta@redhat.com)
- Set a password on the mongo admin db so that application and ssh'd users
  cannot access the DB. Misc other fixes (kraman@gmail.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Merge pull request #681 from pravisankar/dev/ravi/bug/821107
  (openshift+bot@redhat.com)
- Merge pull request #678 from jwhonce/dev/scripts (dmcphers@redhat.com)
- Support more ssh key types (rpenta@redhat.com)
- Automatic commit of package [openshift-origin-broker-util] release
  [0.0.6.2-1]. (admiller@redhat.com)
- Port oo-init-quota command (jhonce@redhat.com)
- Port admin scripts for on-premise (jhonce@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.0.6.2-1
- Port admin scripts for on-premise (jhonce@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Fixing a few missed references to ss-* Added command to load openshift-origin
  selinux module (kraman@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)

* Tue Oct 09 2012 Krishna Raman <kraman@gmail.com> 0.0.6.1-1
- Removing old build scripts Moving broker/node setup utilities into util
  packages (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- Bug 864005 (dmcphers@redhat.com)
- Bug: 861346 - fixing ss-admin-ctl-domain script (abhgupta@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.0.5-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Disable analytics for admin scripts (dmcphers@redhat.com)
- Commiting Rajat's fix for bug#827635 (bleanhar@redhat.com)
- Subaccount user deletion changes (rpenta@redhat.com)
- fixing build requires (abhgupta@redhat.com)

* Mon Sep 24 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- Removing the node profile enforcement from the oo-admin-ctl scripts
  (bleanhar@redhat.com)
- Adding LICENSE file to new packages and other misc cleanup
  (bleanhar@redhat.com)

* Thu Sep 20 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.2-1
- new package built with tito

