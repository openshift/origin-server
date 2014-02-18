%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-frontend-apache-vhost
%global rubyabi 1.9.1

Summary:       OpenShift Apache Virtual Hosts frontend plugin
Name:          rubygem-%{gem_name}
Version: 0.4.0
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
Requires:      rubygem(openshift-origin-frontend-apachedb)
Requires:      httpd
%if 0%{?fedora} >= 18
Requires:      httpd-tools
BuildRequires: httpd-tools
%else
BuildRequires: httpd
%endif
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
Provides the Apache Virtual Hosts plugin for OpenShift web frontends

The Virtual Hosts based OpenShift web frontend is intended to be used
in environments where density is low (a hundred gears per node) and
customization is a priority.

This plugin conflicts with the Apache mod_rewrite frontend plugin and
they cannot be used together.


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

mkdir -p %{buildroot}/etc/openshift/node-plugins.d
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-frontend-apache-vhost.conf.example %{buildroot}/etc/openshift/node-plugins.d/

%if 0%{?fedora} >= 18
  #patch for apache 2.4
  sed -i 's/include /IncludeOptional /g' httpd/000001_openshift_origin_frontend_vhost.conf
%endif



mkdir -p %{buildroot}/etc/httpd/conf.d/openshift
mv httpd/000001_openshift_origin_frontend_vhost.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/frontend-vhost-https-template.erb %{buildroot}/etc/httpd/conf.d/openshift/
mv httpd/frontend-vhost-http-template.erb %{buildroot}/etc/httpd/conf.d/openshift/


%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_frontend_vhost.conf
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-http-template.erb
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-https-template.erb
/etc/openshift/node-plugins.d/

%changelog
* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.3.3-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4666 from ncdc/dev/node-access-log-gear-info
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Add app, gear UUIDs to openshift_log (andy.goldstein@gmail.com)
- Enable syslog configurability for frontend access logging
  (ironcladlou@gmail.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 0.3.2-1
- Fix the Apache vhost plugin (andy.goldstein@gmail.com)