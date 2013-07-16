%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-container-libvirt
%global rubyabi 1.9.1
%define  debug_package %{nil}

Summary:       OpenShift plugin for LibVirt-LXC based containers
Name:          rubygem-%{gem_name}
Version:       0.0.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      rubygem(openshift-origin-node)
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
Requires:      libvirt-sandbox
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
Provides:      rubygem(%{gem_name}) = %version

%description
Provides a LibVirt LXC based container plugin

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
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
%{?scl:EOF}

mkdir -p ./gear-init
gcc -g -o ./gear-init/oo-gear-init misc/gear-init/oo-gear-init.c -lpthread

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

#move the shell binaries into proper location
#mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/sbin
#mv %{buildroot}%{gem_instdir}/bin/* %{buildroot}/usr/bin/
mv ./gear-init/* %{buildroot}/usr/sbin/

mkdir -p %{buildroot}/etc/openshift/node-plugins.d
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-container-libvirt.conf.example %{buildroot}/etc/openshift/node-plugins.d/

%files
%attr(0755,-,-) /usr/sbin/*
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/node-plugins.d/

%changelog

