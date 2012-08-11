%global ruby_sitelib %(ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname uplift-bind-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Uplift plugin for BIND service
Name:           rubygem-%{gemname}
Version:        0.8.7
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) >= 1.9
Requires:       rubygems
Requires:       rubygem(stickshift-common)
Requires:       rubygem(json)
Requires:       bind
Requires:       bind-utils
Requires:       rubygem(dnsruby)
Requires:       stickshift-broker
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
cp %{buildroot}%{gemdir}/gems/uplift-bind-plugin-*/doc/examples/dhcpnamedforward.* %{buildroot}/usr/share/selinux/packages/rubygem-uplift-bind-plugin/

%post

echo " The uplift-bind-plugin requires the following config entries to be present:"
echo " * dns[:server]              - The Bind server IP"
echo " * dns[:port]                - The Bind server Port"
echo " * dns[:keyname]             - The API user"
echo " * dns[:keyvalue]            - The API password"
echo " * dns[:zone]                - The DNS Zone"
echo " * dns[:domain_suffix]       - The domain suffix for applications"

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

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Thu Aug 30 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.8.7-1
- adding dnsruby dependency in bind plugin gemspec and spec file
  (abhgupta@redhat.com)

* Mon Aug 20 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.8.6-1
- gemspec refactorings based on Fedora packaging feedback (bleanhar@redhat.com)
- allow ruby versions > 1.8 (mlamouri@redhat.com)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)
- Removing requirement to disable NetworkManager so that liveinst works Adding
  initial support for dual interfaces Adding "xhost +" so that liveinst can
  continue to work after hostname change to broker.example.com Added delay
  befor launching firefox so that network is stable Added rndc key generation
  for Bind Dns plugin instead of hardcoding it (kraman@gmail.com)
- Add modify application dns and use where applicable (dmcphers@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Wed May 30 2012 Krishna Raman <kraman@gmail.com> 0.8.5-1
- Adding livecd build scripts Adding a text only minimal version of livecd
  Added ability to access livecd dns from outside VM (kraman@gmail.com)

* Fri Apr 27 2012 Krishna Raman <kraman@gmail.com> 0.8.4-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.8.3-1
- new package built with tito
