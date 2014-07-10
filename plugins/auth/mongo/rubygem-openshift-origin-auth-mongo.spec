%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-auth-mongo
%global rubyabi 1.9.1

Summary:       OpenShift plugin for mongo auth service
Name:          rubygem-%{gem_name}
Version:       1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(activeresource)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(mocha)
Requires:      rubygem(openshift-origin-common)
Requires:      openshift-origin-broker
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
Requires:      openssl
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
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
#cp -a ./%{_bindir}/* %{buildroot}/usr/bin
cp -a bin/oo-register-user %{buildroot}/usr/bin

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-auth-mongo.conf.example %{buildroot}/etc/openshift/plugins.d/


%files
%doc LICENSE COPYRIGHT Gemfile
%exclude %{gem_cache}
%{gem_instdir}
%{gem_spec}
/usr/bin/*
/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf.example

%files doc
%doc %{gem_docdir}

%changelog
* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)
- <broker> re-base the broker URI from /broker => / (lmeyer@redhat.com)
- Make set_log_tag lazy, so that all controllers have a default behavior Allow
  controllers to override log tag on their class, not on the instance Make
  allowances for legacy behavior (ccoleman@redhat.com)
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
