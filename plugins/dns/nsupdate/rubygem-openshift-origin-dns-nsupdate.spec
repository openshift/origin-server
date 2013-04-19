%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-dns-nsupdate
%global rubyabi 1.9.1

Summary:       OpenShift plugin for DNS update service using nsupdate
Name:          rubygem-%{gem_name}
Version:       1.5.2
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
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      rubygem(openshift-origin-common)
Requires:      bind-utils
# GSS-API requires kinit
Requires:      krb5-workstation
Requires:      openshift-origin-broker
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
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
Provides a DNS service update plugin using nsupdate

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

# Add documents/examples
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
#cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

#Config file
mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-dns-nsupdate.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf.example

%files
%doc %{gem_docdir}
%doc %{_docdir}/%{name}-%{version}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf.example


%changelog
* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.5.2-1
- Fixing broker and nsupdate plugin deps (bleanhar@redhat.com)
- The nsupdate plugin was calling a method that didn't exist (kraman@gmail.com)
- The nsupdate plugin was calling a method that didn't exist
  (bleanhar@redhat.com)
- Fix typo in dns plugin initializer (kraman@gmail.com)
- Fixing krb workstation dependency (kraman@gmail.com)
- added krb5 features (markllama@gmail.com)
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.1-1
- Add yard documentation markup to DNS plugins (mlamouri@redhat.com)
- fix rubygem sources (tdawson@redhat.com)
- Fixes for ruby193 (john@ibiblio.org)
- change %%define to %%global (tdawson@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.0-1
- Update to version 1.5.0

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 0.0.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 0.0.2-1
- 875575 (dmcphers@redhat.com)

* Fri Jan 25 2013 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

