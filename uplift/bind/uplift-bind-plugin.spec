%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname uplift-bind-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Uplift plugin for BIND service
Name:           rubygem-%{gemname}
Version:        0.8.4
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
Requires:       bind
Requires:       bind-utils
Requires:       rubygem(stickshift-broker)
Requires:  		selinux-policy-targeted
Requires:  		policycoreutils-python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Uplift plugin for Bind service
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
Provides a Bind DNS service based plugin

%description -n ruby-%{gemname}
Provides a Bind DNS service based plugin

%prep
%setup -q

%build

%post
pushd /usr/share/selinux/packages/rubygem-uplift-bind-plugin/ && make -f /usr/share/selinux/devel/Makefile ; popd
semodule -i /usr/share/selinux/packages/rubygem-uplift-bind-plugin/dhcpnamedforward.pp

# preserve the existing named config
if [ ! -f /etc/named.conf.orig ]
then
  mv /etc/named.conf /etc/named.conf.orig
fi

# install the local server named
cp /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/named.conf /etc/named.conf
chown root:named /etc/named.conf
/usr/bin/chcon system_u:object_r:named_conf_t:s0 -v /etc/named.conf

echo "copy example.com. keys in place for bind"
mkdir -p /var/named
cp /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/Kexample.com.* /var/named
KEY=$( grep Key: /var/named/Kexample.com.*.private | cut -d' ' -f 2 )


mkdir -p /var/named/dynamic
cp /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/example.com.db /var/named/dynamic/
/sbin/restorecon -v -R /var/named/dynamic/

echo "Enable and start local named"
/sbin/chkconfig named on
/sbin/chkconfig NetworkManager off
/sbin/chkconfig network on

echo "Setup dhcp update hooks"
cat <<EOF > /etc/dhcp/dhclient.conf
# prepend localhost for DNS lookup in dev and test
prepend domain-name-servers 127.0.0.1 ;
EOF

cp /usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/dhclient-up-hooks /etc/dhcp/dhclient-up-hooks

echo " The uplift-bind-plugin requires the following config entries to be present:"
echo " * dns[:server]              - The Bind server IP"
echo " * dns[:port]                - The Bind server Port"
echo " * dns[:keyname]             - The API user"
echo " * dns[:keyvalue]            - The API password"
echo " * dns[:zone]                - The DNS Zone"
echo " * dns[:domain_suffix]       - The domain suffix for applications"

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

# Add documents/examples
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

# Compile SELinux policy
mkdir -p %{buildroot}/usr/share/selinux/packages/rubygem-uplift-bind-plugin
cp %{buildroot}/usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/dhcpnamedforward.* %{buildroot}/usr/share/selinux/packages/rubygem-uplift-bind-plugin/

mkdir -p %{buildroot}/var/named
cp %{buildroot}/usr/lib/ruby/gems/1.8/gems/uplift-bind-plugin-*/doc/examples/Kexample.com.* %{buildroot}/var/named/
KEY=$( grep Key: %{buildroot}/var/named/Kexample.com.*.private | cut -d' ' -f 2 )

mkdir -p %{buildroot}/var/named
cat <<EOF > %{buildroot}/var/named/example.com.key
  key example.com {
    algorithm HMAC-MD5 ;
    secret "${KEY}" ;
  } ;
EOF

mkdir -p %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config
cat <<EOF > %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config/uplift-bind-plugin.rb
Broker::Application.configure do
  config.dns = {
    :server => "127.0.0.1",
    :port => 53,
    :keyname => "example.com",
    :keyvalue => "${KEY}",
    :zone => "example.com"
  }
end
EOF

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%doc %{_docdir}/%{name}-%{version}
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
/usr/share/selinux/packages/rubygem-uplift-bind-plugin
%attr(0750,apache,apache) /var/www/stickshift/broker/config/environments/plugin-config/uplift-bind-plugin.rb
/var/named/example.com.key
/var/named/Kexample.com.*.key
/var/named/Kexample.com.*.private

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Fri Apr 27 2012 Krishna Raman <kraman@gmail.com> 0.8.4-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.8.3-1
- new package built with tito
