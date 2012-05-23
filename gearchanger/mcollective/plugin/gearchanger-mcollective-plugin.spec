%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname gearchanger-mcollective-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        GearChanger plugin for m-colective service
Name:           rubygem-%{gemname}
Version:        0.0.0
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       mcollective
Requires:       mcollective-client
Requires:       qpid-cpp-server
Requires:       qpid-cpp-client
Requires:       ruby-qpid
#Requires:       qpid-tools
Requires:       rubygem(stickshift-common)
Requires:       stickshift-broker
Requires:       rubygem(json)
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        GearChanger plugin for m-colective based node/gear manager
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
GearChanger plugin for m-colective based node/gear manager

%description -n ruby-%{gemname}
GearChanger plugin for mcollective based node/gear manager

%prep
%setup -q

%build

%post
chown root:apache /etc/mcollective/client.cfg
chmod og+r /etc/mcollective/client.cfg

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
cat <<EOF > %{buildroot}/var/www/stickshift/broker/config/environments/plugin-config/gearchanger-mcollective-plugin.rb
Broker::Application.configure do
  config.gearchanger = {
    :rpc_options => {
    	:disctimeout => 5,
    	:timeout => 60,
    	:verbose => false,
    	:progress_bar => false,
    	:filter => {"identity" => [], "fact" => [], "agent" => [], "cf_class" => []},
    	:config => "/etc/mcollective/client.cfg"
    },
    :districts => {
        :enabled => false,
        :require_for_app_create => false,
        :max_capacity => 6000, #Only used by district create
        :first_uid => 1000
    },
    :node_profile_enabled => false
  }
end
EOF

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
/var/www/stickshift/broker/config/environments/plugin-config/gearchanger-mcollective-plugin.rb

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
