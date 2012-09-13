%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-console
%global gemversion %(echo %{version} | cut -d'.' -f1-3)
%global geminstdir %{gemdir}/gems/%{gemname}-%{gemversion}

Summary:        OpenShift Origin Management Console
Name:           rubygem-%{gemname}
Version:        0.0.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            https://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       rubygem(rails)
Requires:       rubygem(mocha)

BuildRequires:  ruby
BuildRequires:  rubygems
BuildRequires:  rubygem(rake)
BuildRequires:  rubygem(bundler)
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        OpenShift Origin Management Console
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
This contains the OpenShift Origin Management Console packaged as a rubygem.

%description -n ruby-%{gemname}
This contains the OpenShift Origin Management Console packaged as a ruby site library.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Temporary BEGIN
bundle install
# Temporary END
pushd test/rails_app/
RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile
rm -rf tmp/cache/*
echo > log/production.log
popd

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{gemversion}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{gemversion}
%{gemdir}/gems/%{gemname}-%{gemversion}
%{gemdir}/cache/%{gemname}-%{gemversion}.gem
%{gemdir}/specifications/%{gemname}-%{gemversion}.gemspec

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

