%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname stickshift-node
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Cloud Development Node
Name:           rubygem-%{gemname}
Version:        0.9.9
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(json)
Requires:       rubygem(parseconfig)
Requires:       rubygem(stickshift-common)
Requires:       rubygem(mocha)
Requires:       rubygem(rspec)
Requires:       python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Cloud Development Node Library
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the Cloud Development Node packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the Cloud Development Node packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}/ss
mkdir -p %{buildroot}%{_sysconfdir}/stickshift
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{_bindir}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Move the gem binaries to the standard filesystem location
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rm -rf %{buildroot}%{gemdir}/bin

# Move the gem configs to the standard filesystem location
mv %{buildroot}%{geminstdir}/conf/* %{buildroot}%{_sysconfdir}/stickshift

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

#move the shell binaries into proper location
mv %{buildroot}%{geminstdir}/misc/bin/* %{buildroot}%{_bindir}/
rm -rf %{buildroot}%{geminstdir}/misc

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
%{_sysconfdir}/stickshift
%{_bindir}/*

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%post
echo "/usr/bin/ss-trap-user" >> /etc/shells

# copying this file in the post hook so that this file can be replaced by rhc-node
# copy this file only if it doesn't already exist
if ! [ -f /etc/stickshift/resource_limits.conf ]; then
  cp -f /etc/stickshift/resource_limits.template /etc/stickshift/resource_limits.conf
fi

%changelog
* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.9.9-1
- Updating gem versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.8-1
- Updating gem versions (admiller@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.7-1
- Updating gem versions (dmcphers@redhat.com)
- cleaning up spec (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.6-1
- Updating gem versions (dmcphers@redhat.com)
- forcing builds (dmcphers@redhat.com)
