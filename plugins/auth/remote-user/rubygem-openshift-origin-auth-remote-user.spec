%define brokerdir %{_localstatedir}/www/openshift/broker

%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-auth-remote-user
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift Origin plugin for remote-user authentication
Name:           rubygem-%{gemname}
Version:        0.0.15
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(openshift-origin-common)
Requires:       rubygem(json)
Requires:       openshift-broker

BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%description
Provides a remote-user auth service based plugin

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{buildroot}%{_bindir}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Add documents/examples
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gemname}-basic.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gemname}-ldap.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gemname}-kerberos.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp conf/openshift-origin-auth-remote-user.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf.example

%clean
rm -rf %{buildroot}

%files
#%doc LICENSE COPYRIGHT Gemfile README-LDAP README-KERB
%doc %{_docdir}/%{name}-%{version}
#%exclude %{gem_cache}
#%{gem_instdir}
#%{gem_spec}
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%doc %{geminstdir}/README-LDAP
%doc %{geminstdir}/README-KERB
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{brokerdir}/httpd/conf.d/%{gemname}-basic.conf.sample
%{brokerdir}/httpd/conf.d/%{gemname}-ldap.conf.sample
%{brokerdir}/httpd/conf.d/%{gemname}-kerberos.conf.sample
%{_sysconfdir}/openshift/plugins.d/openshift-origin-auth-remote-user.conf.example

%changelog
* Mon Oct 29 2012 Adam Miller <admiller@redhat.com> 0.0.15-1
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)
- Bug 870339 - Authorization is failed on JbossTool (bleanhar@redhat.com)

* Wed Oct 24 2012 Adam Miller <admiller@redhat.com> 0.0.14-1
- BZ867340 new password does not take effect until reboot broker service
  (calfonso@redhat.com)

* Mon Oct 22 2012 Adam Miller <admiller@redhat.com> 0.0.13-1
- BZ847976 - Fixing Jenkins integration (bleanhar@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.0.12-1
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)

* Tue Oct 16 2012 Adam Miller <admiller@redhat.com> 0.0.11-1
- Merge pull request #670 from Miciah/openshift-origin-plugin-auth-remote-user-
  install-README (openshift+bot@redhat.com)
- openshift-origin-auth-remote-user: install README (miciah.masters@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.0.10-1
- Minor fix for the kerberos/ldap sample config files (bleanhar@redhat.com)

* Thu Oct 11 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.9-1
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Merge pull request #619 from kraman/master (openshift+bot@redhat.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- US2635 [Authentication] Kerberos integration for authentication
  (calfonso@redhat.com)

* Tue Oct 09 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.8-1
- Merge pull request #613 from kraman/master (openshift+bot@redhat.com)
- Module name and gem path fixes for auth plugins (kraman@gmail.com)

* Mon Oct 08 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Merge pull request #612 from calfonso/master (dmcphers@redhat.com)
- Merge pull request #607 from brenton/streamline_auth_misc1-rebase
  (openshift+bot@redhat.com)
- US2634 [Authentication] LDAP integration for authentication
  (calfonso@redhat.com)
- Minor updates changes to the remote-auth plugin (bleanhar@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- 

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.0.5-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 2: variables, modules, classes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Minor doc update for the remote-user auth plugin (bleanhar@redhat.com)

* Fri Sep 28 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.3-1
- new package built with tito

