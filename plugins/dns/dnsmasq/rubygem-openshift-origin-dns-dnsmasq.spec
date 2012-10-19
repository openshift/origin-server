%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname openshift-origin-dns-dnsmasq

%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        Openshift Origin plugin for DNS service using DNSMasq 
Name:           rubygem-%{gemname}
Version:        0.1.13
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) >= 1.8
Requires:       rubygems
Requires:       rubygem(openshift-origin-common)
Requires:       dnsmasq
Requires:       bind-utils

BuildRequires:  ruby
BuildRequires:  rubygems
BuildRequires:  rubygem(rake)
BuildRequires:  rubygem(rspec-core)
BuildRequires:  rubygem(rdoc)
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        Openshift Origin plugin for DNS service using Dnsmasq
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
Provides a DNSMasq service based plugin

%description -n ruby-%{gemname}
Provides a DNSMasq service based plugin

%prep
%setup -q

%build
rake doc

%check
# Run Rspec tests before building
#rake spec

%post

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}
mkdir -p %{buildroot}/etc/openshift/plugins.d

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

# create docs and copy them into the shared space
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}
cp README* LICENSE COPYRIGHT %{buildroot}%{_docdir}/%{name}-%{version}/

#Config file
cp %{buildroot}%{gemdir}/gems/%{gemname}-%{version}/conf/openshift-origin-dns-dnsmasq.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-dnsmasq.conf.example

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
/etc/openshift/plugins.d/openshift-origin-dns-dnsmasq.conf.example

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.13-1
- naww.  The rdocs get installed in the gem space anyway (mlamouri@redhat.com)
- just symlink the rdoc output (mlamouri@redhat.com)
- just symlink the rdoc output (mlamouri@redhat.com)
- just symlink the rdoc output (mlamouri@redhat.com)
- try installing rdoc from the right place (mlamouri@redhat.com)
- try installing rdoc into the right place (mlamouri@redhat.com)
- try installing rdoc into the right place (mlamouri@redhat.com)
- require adding rdoc files (mlamouri@redhat.com)

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.12-1
- removed I hope last reference to -plugin files (mlamouri@redhat.com)

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.11-1
- 

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.10-1
- 

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.9-1
- 

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.8-1
- new package built with tito

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.7-1
- fixed typo in requires (mlamouri@redhat.com)

* Mon Nov 05 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.6-1
- remove check because test requirements arent there (markllama@gmail.com)
- still fixing rpm and gem spec filenames (markllama@gmail.com)
- still fixing rpm and gem spec filenames (markllama@gmail.com)
- still fixing rpm and gem spec filenames (markllama@gmail.com)
- still fixing rpm and gem spec filenames (markllama@gmail.com)
- Automatic commit of package [rubygem-openshift-origin-dns-dnsmasq-plugin]
  release [0.1.5-1]. (markllama@gmail.com)
- rename spec file for rubygem (markllama@gmail.com)
- rename spec file for rubygem (markllama@gmail.com)
- Automatic commit of package [rubygem-%%{gemname}] release [0.1.4-1].
  (markllama@gmail.com)
- Automatic commit of package [rubygem-%%{gemname}] release [0.1.3-1].
  (markllama@gmail.com)
- added commentary and configuration information (markllama@gmail.com)
- added a sleep to another test after publish.  Maybe the sleep should be in
  publish? (markllama@gmail.com)
- added config from rails test (mlamouri@redhat.com)
- fixing naming still (mlamouri@redhat.com)
- fixing naming still (mlamouri@redhat.com)
- copied over dnsmasq from pre-rename workspace and ported to new component
  names (mlamouri@redhat.com)

* Fri Oct 26 2012 Mark Lamourine <markllama@gmail.com> 0.1.5-1
- new package built with tito


* Fri Oct 26 2012 Mark Lamourine <markllama@gmail.com> 0.1.4-1
- new package built with tito

* Thu Aug 16 2012 Mark Lamourine <mlamouri@redhat.com> 0.1.2-1
- initial skeleton of a plugin package
* Wed Aug 08 2012 Mark Lamourine <markllama@gmail.com> 0.1.1-1
- new package built with tito

