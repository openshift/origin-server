%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-frontend-apachedb
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%if 0%{?fedora} >= 18
    %global httxt2dbm /usr/bin/httxt2dbm
%else
    %global httxt2dbm /usr/sbin/httxt2dbm
%endif

Summary:       OpenShift ApacheDB frontend plugin
Name:          rubygem-%{gem_name}
Version: 0.6.1
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
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      openshift-origin-node-util
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
Provides the ApacheDB plugin for OpenShift web frontends

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
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-frontend-apachedb.conf.example %{buildroot}/etc/openshift/node-plugins.d/

mkdir -p %{buildroot}/etc/httpd/conf.d
mkdir -p %{buildroot}%{appdir}/.httpd.d
ln -sf %{appdir}/.httpd.d %{buildroot}/etc/httpd/conf.d/openshift

echo '{}' > "%{buildroot}%{appdir}/.httpd.d/geardb.json"

mkdir -p %{buildroot}/etc/httpd/conf.d
mv httpd/000001_openshift_origin_node_servername.conf %{buildroot}/etc/httpd/conf.d/



%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node_servername.conf
%attr(0750,-,-) /etc/httpd/conf.d/openshift
%dir %attr(0750,root,apache) %{appdir}/.httpd.d
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/geardb.json
/etc/openshift/node-plugins.d/

%changelog
* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 0.5.2-1
- bump spec to fix tags (admiller@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 0.4.2-1
- move env var guard for all http plugins and not just the vhost plugin
  (rchopra@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.3.2-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4666 from ncdc/dev/node-access-log-gear-info
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Add app, gear UUIDs to openshift_log (andy.goldstein@gmail.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Wed Dec 04 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 37 (admiller@redhat.com)

