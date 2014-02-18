%global brokerdir %{_var}/www/openshift/broker

%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-auth-remote-user
%global rubyabi 1.9.1

Summary:       OpenShift plugin for remote-user authentication
Name:          rubygem-%{gem_name}
Version: 1.19.0
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
Requires:      rubygem(openshift-origin-common)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      openshift-broker
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
Provides a remote-user auth service based plugin

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
cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gem_name}-basic.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gem_name}-ldap.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d
install -m 755 conf/%{gem_name}-kerberos.conf.sample %{buildroot}%{brokerdir}/httpd/conf.d

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp conf/openshift-origin-auth-remote-user.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf.example

%files
%doc %{gem_docdir}
%doc %{_docdir}/%{name}-%{version}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%{brokerdir}/httpd/conf.d/%{gem_name}-basic.conf.sample
%{brokerdir}/httpd/conf.d/%{gem_name}-ldap.conf.sample
%{brokerdir}/httpd/conf.d/%{gem_name}-kerberos.conf.sample
/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf.example

%post

if [ $1 -ne 1 ] # this is an update; fix the previously configured realm.
then
  conf='/var/www/openshift/broker/httpd/conf.d/openshift-origin-auth-remote-user.conf'
  # The configuration file may not be present if the plug-in was installed
  # but never enabled.
  if [ -e "$conf" ]
  then
    sed -i -e 's/AuthName.*/AuthName "OpenShift Broker API"/' "$conf"
  fi
fi

%changelog
* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.17.3-1
- Fix regex for base64 encoded broker auth iv/token values (kraman@gmail.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Add passthrough config for broker auth (iv/token) based on request headers
  (kraman@gmail.com)