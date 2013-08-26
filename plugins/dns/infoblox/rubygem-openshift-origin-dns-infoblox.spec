%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-dns-infoblox
%global rubyabi 1.9.1

Summary:       OpenShift plugin for InfoBlox DNS update
Name:          rubygem-%{gem_name}
Version:       0.1.5
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{gem_name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      rubygem(openshift-origin-common)
Requires:      openshift-origin-broker
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: ruby193-build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
Provides a plugin for Infoblox DNS service

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p ./%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec
rdoc
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

# Add documents/examples
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

#Config file
mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-dns-infoblox.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-infoblox.conf.example


%files
%doc %{gem_docdir}
%doc %{_docdir}/%{name}-%{version}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/plugins.d/openshift-origin-dns-infoblox.conf.example


%changelog
* Wed Oct 09 2013 Mark Lamourine <<mlamouri@redhat.com>> 0.1.5-1
- completed init conversion for error checking (markllama@gmail.com)
- add infoblox plugin for DNS updates (mlamouri@redhat.com)

* Wed Sep 04 2013 Mark Lamourine <<mlamouri@redhat.com>> 0.1.4-1
- add infoblox plugin for DNS updates (mlamouri@redhat.com)

* Tue Aug 27 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.3-1
- Automatic commit of package [rubygem-openshift-origin-dns-infoblox] release
  [0.1.2-1]. (mlamouri@redhat.com)
- added example config file (mlamouri@redhat.com)
- updated package name in gemspec (mlamouri@redhat.com)
- Automatic commit of package [rubygem-openshift-origin-dns-infoblox] release
  [0.1.1-1]. (mlamouri@redhat.com)
- reverted version to 0.1.0 (mlamouri@redhat.com)
- added module and class wrapper to plugin methods (mlamouri@redhat.com)
- added plugin package elements (mlamouri@redhat.com)
- add infoblox plugin for DNS updates (mlamouri@redhat.com)

* Mon Aug 26 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.2-1
- added example config file (mlamouri@redhat.com)
- updated package name in gemspec (mlamouri@redhat.com)

* Mon Aug 26 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.1-1
- first attempt to package infoblox DNS plugin

