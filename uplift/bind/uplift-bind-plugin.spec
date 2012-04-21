%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname uplift-bind-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Uplift plugin for BIND service
Name:           rubygem-%{gemname}
Version:        0.8.1
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

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.7.4-1
- 

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.7.3-1
- Renaming for open-source release

* Wed Mar 28 2012 Mark Lamourine <mlamouri@redhat.com>
- new package built with tito
- Added docs and examples to RPM
