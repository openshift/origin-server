%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-auth-kerberos
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        OpenShift Origin plugin for kerberos auth service
Name:           rubygem-%{gemname}
Version:        1.0.0
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(openshift-origin-common)
Requires:       rubygem(json)
Requires:       rubygem(mocha)
Requires:       openshift-origin-broker
Requires:  		selinux-policy-targeted
Requires:  		policycoreutils-python
Requires:       rubygem(krb5-auth)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        OpenShift Origin plugin for kerberos auth service
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version
Obsoletes:      rubygem-swingshift-kerberos-plugin

%description
Provides a kerberos auth service based plugin

%description -n ruby-%{gemname}
Provides a kerberos auth service based plugin

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{buildroot}/etc/openshift/plugins.d

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

mkdir -p %{buildroot}/openshift/plugins.d
cp conf/openshift-origin-auth-kerberos.conf.example %{buildroot}/etc/openshift/plugins.d/

%clean
rm -rf %{buildroot}

%post
/usr/bin/openssl genrsa -out /var/www/openshift/broker/config/server_priv.pem 2048
/usr/bin/openssl rsa    -in /var/www/openshift/broker/config/server_priv.pem -pubout > /var/www/openshift/broker/config/server_pub.pem

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{_sysconfdir}/openshift/plugins.d/openshift-origin-auth-kerberos.conf.example

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Fri Jan 11 2013 Troy Dawson <tdawson@redhat.com> 1.0.0-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
- Moving broker config to /etc/openshift/broker.conf Rails app and all oo-*
  scripts will load production environment unless the
  /etc/openshift/development marker is present Added param to specify default
  when looking up a config value in OpenShift::Config Moved all defaults into
  plugin initializers instead of separate defaults file No longer require
  loading 'openshift-origin-common/config' if 'openshift-origin-common' is
  loaded openshift-origin-common selinux module is merged into F16 selinux
  policy. Removing from broker %%postrun (kraman@gmail.com)
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- Merge pull request #613 from kraman/master (openshift+bot@redhat.com)
- Module name and gem path fixes for auth plugins (kraman@gmail.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.8.9-1
- 

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.8.8-1
- new package built with tito

* Thu Aug 16 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.8.7-1
- new package built with tito

* Wed Aug 15 2012 Jason DeTiberus <jason.detiberus@redhat.com> 0.8.6-1
- kerberos auth plugin (jason.detiberus@redhat.com)

* Wed Aug 15 2012 Jason DeTiberus <jason.detiberus@redhat.com> 0.8.5-1
- new package built with tito

