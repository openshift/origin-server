%define brokerdir %{_localstatedir}/www/openshift/broker

%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-auth-remote-user
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift Origin plugin for remote-user authentication
Name:           rubygem-%{gemname}
Version:        0.0.10
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
install -m 755 %{gemname}.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 %{gemname}-ldap.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 %{gemname}-kerberos.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp lib/openshift-origin-auth-remote-user/config/initializers/openshift-origin-auth-remote-user-defaults.conf %{buildroot}/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf

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
%{brokerdir}/httpd/conf.d/%{gemname}.conf.sample
%{brokerdir}/httpd/conf.d/%{gemname}-ldap.conf.sample
%{brokerdir}/httpd/conf.d/%{gemname}-kerberos.conf.sample

%config(noreplace) %{_sysconfdir}/openshift/plugins.d/openshift-origin-auth-remote-user.conf

%changelog
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

