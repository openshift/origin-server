%define brokerdir %{_localstatedir}/www/stickshift/broker

%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-auth-remote-user
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        SwingShift plugin for remote-user authentication
Name:           rubygem-%{gemname}
Version:        0.0.3
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(stickshift-common)
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

mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 %{gemname}.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d

mkdir -p %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config
# TODO: This needs to use configuration under /etc and not be hardcoded here.
cat <<EOF > %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config/openshift-origin-auth-remote-user.rb
Broker::Application.configure do
  config.auth = {
    :trusted_header => "REMOTE_USER",
    :salt           => "ClWqe5zKtEW4CJEMyjzQ",
    :privkeyfile    => "/var/www/stickshift/broker/config/server_priv.pem",
    :privkeypass    => "",
    :pubkeyfile     => "/var/www/stickshift/broker/config/server_pub.pem",
  }
end
EOF

%clean
rm -rf %{buildroot}

%files
#%doc LICENSE COPYRIGHT Gemfile
#%exclude %{gem_cache}
#%{gem_instdir}
#%{gem_spec}
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{brokerdir}/httpd/conf.d/%{gemname}.conf.sample

%attr(0440,apache,apache) /var/www/stickshift/broker/config/environments/plugin-config/openshift-origin-auth-remote-user.rb

%changelog
* Fri Sep 28 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.3-1
- new package built with tito

