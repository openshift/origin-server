%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname swingshift-mongo-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        SwingShift plugin for mongo auth service
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
Requires:       stickshift-broker
Requires:  		selinux-policy-targeted
Requires:  		policycoreutils-python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        SwingShift plugin for mongo auth service
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
Provides a mongo auth service based plugin

%description -n ruby-%{gemname}
Provides a mongo auth service based plugin

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

# Move the gem binaries to the standard filesystem location
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rm -rf %{buildroot}%{gemdir}/bin

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

mkdir -p %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config
cat <<EOF > %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config/swingshift-mongo-plugin.rb
Broker::Application.configure do
  config.auth = {
    :salt => "ClWqe5zKtEW4CJEMyjzQ",
    
    # Replica set example: [[<host-1>, <port-1>], [<host-2>, <port-2>], ...]
    :mongo_replica_sets => false,
    :mongo_host_port => ["localhost", 27017],
  
    :mongo_user => "stickshift",
    :mongo_password => "mooo",
    :mongo_db => "stickshift_broker_dev",
    :mongo_collection => "auth_user"
  }
end
EOF


%clean
rm -rf %{buildroot}

%post
echo "The following variables need to be set in your rails config to use swingshift-mongo-plugin:"
echo "auth[:salt]                    - salt for the password hash"
echo "auth[:mongo_replica_sets]      - List of replica servers or false if replicas is disabled eg: [[<host-1>, <port-1>], [<host-2>, <port-2>], ...]"
echo "auth[:mongo_host_port]         - Address of mongo server if replicas are disabled. eg: [\"localhost\", 27017]"
echo "auth[:mongo_user]              - Username to log into mongo"
echo "auth[:mongo_password]          - Password to log into mongo"
echo "auth[:mongo_db]                - Database name to store user login/password data"
echo "auth[:mongo_collection]        - Collection name to store user login/password data"

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{_bindir}/*

%attr(0440,apache,apache) /var/www/stickshift/broker/config/environments/plugin-config/swingshift-mongo-plugin.rb

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Thu Apr 26 2012 Krishna Raman <kraman@gmail.com> 0.8.4-1
- Added README for SwingShift-mongo plugin (rpenta@redhat.com)
- cleaning up spec files (dmcphers@redhat.com)
- decoding the broker auth key before returning from login in the auth plugin
  (abhgupta@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.8.3-1
- new package built with tito
