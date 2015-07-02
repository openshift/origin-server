%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-dns-dynect
%global rubyabi 1.9.1

Summary:        OpenShift plugin for Dynect DNS service
Name:           rubygem-%{gem_name}
Version: 1.14.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       rubygem(openshift-origin-common)
Requires:       %{?scl:%scl_prefix}rubygem(json)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  %{?scl:%scl_prefix}build
BuildRequires:  scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version
Obsoletes: rubygem-uplift-dynect-plugin

%description
Provides a DYN DNS service based plugin

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

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

#Config file
mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-dns-dynect.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-dynect.conf.example

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/plugins.d/openshift-origin-dns-dynect.conf.example

%changelog
* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 1.14.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Tue Jun 30 2015 Wesley Hearn <whearn@redhat.com> 1.13.2-1
- Formatting fixes (dmcphers@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.13.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Thu Sep 04 2014 Adam Miller <admiller@redhat.com> 1.12.3-1
- Spec file fixes (jdetiber@redhat.com)

* Thu Aug 28 2014 Adam Miller <admiller@redhat.com> 1.12.2-1
- new package built with tito


