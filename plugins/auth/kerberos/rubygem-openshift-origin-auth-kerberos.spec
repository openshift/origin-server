%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname swingshift-kerberos-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        SwingShift plugin for kerberos auth service
Name:           rubygem-%{gemname}
Version:        0.8.7
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(stickshift-common)
Requires:       rubygem(json)
Requires:       rubygem(mocha)
Requires:       stickshift-broker
Requires:  		selinux-policy-targeted
Requires:  		policycoreutils-python
Requires:       rubygem(krb5-auth)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        SwingShift plugin for kerberos auth service
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

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

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

mkdir -p %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config
cat <<EOF > %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config/swingshift-kerberos-plugin.rb
Broker::Application.configure do
  config.auth = {
    :salt => "ClWqe5zKtEW4CJEMyjzQ",
    :privkeyfile => "/var/www/stickshift/broker/config/server_priv.pem",
    :privkeypass => "",
    :pubkeyfile  => "/var/www/stickshift/broker/config/server_pub.pem",
  }
end
EOF

%clean
rm -rf %{buildroot}

%post
/usr/bin/openssl genrsa -out /var/www/stickshift/broker/config/server_priv.pem 2048
/usr/bin/openssl rsa    -in /var/www/stickshift/broker/config/server_priv.pem -pubout > /var/www/stickshift/broker/config/server_pub.pem

echo "The following variables need to be set in your rails config to use swingshift-kerberos-plugin:"
echo "auth[:salt]                    - salt for the password hash"
echo "auth[:privkeyfile]             - RSA private key file for node-broker authentication"
echo "auth[:privkeypass]             - RSA private key password"
echo "auth[:pubkeyfile]              - RSA public key file for node-broker authentication"

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%attr(0440,apache,apache) /var/www/stickshift/broker/config/environments/plugin-config/swingshift-kerberos-plugin.rb

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Thu Aug 16 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.8.7-1
- new package built with tito

* Wed Aug 15 2012 Jason DeTiberus <jason.detiberus@redhat.com> 0.8.6-1
- kerberos auth plugin (jason.detiberus@redhat.com)

* Wed Aug 15 2012 Jason DeTiberus <jason.detiberus@redhat.com> 0.8.5-1
- new package built with tito

