%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname gearchanger-mcollective-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        GearChanger plugin for mcollective service
Name:           rubygem-%{gemname}
Version: 0.1.5
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       mcollective-client
Requires:       qpid-cpp-client
Requires:       ruby-qpid-qmf
#Requires:       qpid-tools
Requires:       rubygem(stickshift-common)
Requires:       rubygem(json)
Requires:       selinux-policy-targeted
Requires:       policycoreutils-python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        GearChanger plugin for mcollective based node/gear manager
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
GearChanger plugin for mcollective based node/gear manager

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
* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.1.5-1
- send mcollective requests to multiple nodes at the same time
  (dmcphers@redhat.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.1.4-1
- Bug 843757 (dmcphers@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- Mongo deleted_gears fix (rpenta@redhat.com)
- Merge pull request #265 from kraman/dev/kraman/bugs/806824
  (dmcphers@redhat.com)
- Stop calling deconfigure on destroy (dmcphers@redhat.com)
- Bug 806824 - [REST API] clients should be able to get informed about reserved
  application names (kraman@gmail.com)
- US2439: Add support for getting/setting quota. (mpatel@madagascar.(none))

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.1.2-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  stickshift-proxy out of cartridge hooks and into node. (rmillner@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.0.9-1
- mcollective-plugin pkg doesn't require qpid-cpp-server or mcollective, only
  -client (admiller@redhat.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.0.8-1
- Merge pull request #211 from kraman/dev/kraman/bugs/835489
  (dmcphers@redhat.com)
- Add modify application dns and use where applicable (dmcphers@redhat.com)
- Bugz 835489. Fixing location for district config file and adding in missing
  node_profile_enabled blocks (kraman@gmail.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.0.7-1
- Bug 838786 (dmcphers@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.6-1
- cleanup specs (dmcphers@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.5-1
- fix for bug#837579 - handle better messaging on find_available_node failure
  (rchopra@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Fix for BZ 837522. (mpatel@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.3-1
- fixed a couple typos (admiller@redhat.com)
- Automatic commit of package [rubygem-gearchanger-mcollective-plugin] release
  [0.0.1-1]. (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com>
- fixed a couple typos (admiller@redhat.com)
- Automatic commit of package [rubygem-gearchanger-mcollective-plugin] release
  [0.0.1-1]. (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

