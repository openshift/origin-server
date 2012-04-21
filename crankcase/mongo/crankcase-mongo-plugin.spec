%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname crankcase-mongo-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Crankcase plugin for MongoDB
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

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Crankcase plugin for MongoDB
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
Provides a MongoDB based datastore plugin

%description -n ruby-%{gemname}
Provides a MongoDB based datastore plugin

%prep
%setup -q

%build

%post

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

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.8.4-1
- new package built with tito

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.3-1
- test commit (mmcgrath@redhat.com)

* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.8.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Wed Apr 11 2012 Adam Miller <admiller@redhat.com> 0.7.6-1
- fix mongo put_app where ngears < 0; dont save an app after
  deconfigure/destroy if it has not persisted, because the destroy might have
  been called for a failure upon save (rchopra@redhat.com)

* Mon Apr 09 2012 Mike McGrath <mmcgrath@redhat.com> 0.7.5-1
- cleaning up location of datatstore configuration (kraman@gmail.com)
- Merge remote-tracking branch 'origin/master' (kraman@gmail.com)
- Bug fixes after initial merge of OSS packages (kraman@gmail.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.7.4-1
- 

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.7.3-1
- Renaming for open-source release

