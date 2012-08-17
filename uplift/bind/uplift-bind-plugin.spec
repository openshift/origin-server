%global gem_name uplift-bind-plugin

%if 0%{?rhel} <= 6 && 0%{?fedora} <= 16

%global gem_dir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gem_instdir %{gem_dir}/gems/%{gem_name}-%{version}
%global gem_docdir %{gem_dir}/doc/%{gem_name}-%{version}
%global gem_cache %{gem_dir}/cache/%{gem_name}-%{version}.gem 
%global gem_spec %{gem_dir}/specifications/%{gem_name}-%{version}.gemspec 

%endif #end rhel <= 6 && fedora <= 16

Summary:        Uplift plugin for BIND service
Name:           rubygem-%{gem_name}
Version:        0.8.7
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
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

%if 0%{?rhel} <= 6 && 0%{?fedora} <= 16
Requires:       ruby(abi) = 1.8
%endif
%if 0%{?fedora} >= 17
Requires:       ruby(abi) = 1.9.1
BuildRequires:  rubygems-devel
%endif

BuildRequires:  ruby
BuildRequires:  rubygems

BuildArch:      noarch

Provides:       rubygem(%{gem_name}) = %version

%description
Provides a Bind DNS service based plugin

%prep
%setup -q

%build
mkdir -p ./%{gem_dir}

# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

# Add documents/examples
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

# Compile SELinux policy
mkdir -p %{buildroot}%{_prefix}/share/selinux/packages/%{name}
cp %{buildroot}%{gem_dir}/gems/%{gem_name}-%{version}/doc/examples/dhcpnamedforward.* %{buildroot}%{_prefix}/share/selinux/packages/%{name}/

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
%doc %{gem_instdir}/Gemfile
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%dir %{_prefix}/share/selinux/packages/%{name}
%{_prefix}/share/selinux/packages/%{name}/*


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
