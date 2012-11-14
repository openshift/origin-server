%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-auth-mongo
%global rubyabi 1.9.1

Summary:        OpenShift plugin for mongo auth service
Name:           rubygem-%{gem_name}
Version:        1.1.0
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(activeresource)
Requires:       %{?scl:%scl_prefix}rubygem(json)
Requires:       %{?scl:%scl_prefix}rubygem(mocha)
Requires:       rubygem(openshift-origin-common)
Requires:       openshift-origin-broker
Requires:     selinux-policy-targeted
Requires:     policycoreutils-python
Requires:       openssl
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version
Obsoletes:      rubygem-swingshift-mongo-plugin

%description
Provides a mongo auth service based plugin

%package doc
Summary:        OpenShift plugin for mongo auth service ri documentation

%description doc
OpenShift plugin for mongo auth service ri documentation

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir .%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* %{buildroot}%{gem_dir}/

# If there were programs installed:
mkdir -p %{buildroot}/usr/bin
cp -a ./%{_bindir}/* %{buildroot}/usr/bin

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-auth-mongo.conf.example %{buildroot}/etc/openshift/plugins.d/


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc LICENSE COPYRIGHT Gemfile
%exclude %{gem_cache}
%{gem_instdir}
%{gem_spec}
/usr/bin/*
/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf.example

%files doc
%doc %{gem_docdir}

%changelog
* Thu Oct 11 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.8.9-1
- fix for mongo auth plugin spec file (abhgupta@redhat.com)
- Centralize plug-in configuration (miciah.masters@gmail.com)
- Removing old build scripts Moving broker/node setup utilities into util
  packages Fix Auth service module name conflicts (kraman@gmail.com)
- Merge pull request #613 from kraman/master (openshift+bot@redhat.com)
- Module name and gem path fixes for auth plugins (kraman@gmail.com)