%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-frontend-apache-mod-rewrite
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%if 0%{?fedora} >= 18
    %global httxt2dbm /usr/bin/httxt2dbm
%else
    %global httxt2dbm /usr/sbin/httxt2dbm
%endif

Summary:       OpenShift Apache mod_rewrite frontend plugin
Name:          rubygem-%{gem_name}
Version: 0.8.1
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

Conflicts: rubygem-openshift-origin-frontend-apache-vhost


%description
Provides the Apache mod_rewrite plugin for OpenShift web frontends

The mod_rewrite based OpenShift web frontend is intended to be used in
environments with high density (hundreds or thousands of gears per
node) environments where frontend customization is not a priority.

This plugin conflicts with the Apache Virtual Hosts frontend plugin
and they cannot be used together.

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
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-frontend-apache-mod-rewrite.conf.example %{buildroot}/etc/openshift/node-plugins.d/


# Create empty route database files
mkdir -p %{buildroot}%{appdir}/.httpd.d
for map in nodes aliases idler sts
do
    mapf="%{buildroot}%{appdir}/.httpd.d/${map}"
    touch "${mapf}.txt"
    %{httxt2dbm} -f DB -i "${mapf}.txt" -o "${mapf}.db"
done

%if 0%{?fedora} >= 18
  #patch for apache 2.4
  sed -i 's/include /IncludeOptional /g' httpd/000001_openshift_origin_node.conf
  sed -i 's/^RewriteLog/#RewriteLog/g' httpd/openshift_route.include
  sed -i 's/^RewriteLogLevel/#RewriteLogLevel/g' httpd/openshift_route.include
  sed -i 's/^#LogLevel/LogLevel/g' httpd/openshift_route.include
%endif

mkdir -p %{buildroot}/etc/httpd/conf.d
mv httpd/000001_openshift_origin_node.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/openshift_route.include %{buildroot}/etc/httpd/conf.d/
mv httpd/openshift_route_logconf.include %{buildroot}/etc/httpd/conf.d/

mv httpd/frontend-mod-rewrite-https-template.erb %{buildroot}%{appdir}/.httpd.d/frontend-mod-rewrite-https-template.erb

%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%config /etc/httpd/conf.d/openshift_route.include
%config(noreplace) /etc/httpd/conf.d/openshift_route_logconf.include
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node.conf
%attr(0644,root,root)   %config(noreplace) %{appdir}/.httpd.d/frontend-mod-rewrite-https-template.erb
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/nodes.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/aliases.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/idler.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/sts.txt
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/nodes.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/aliases.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/idler.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/sts.db
/etc/openshift/node-plugins.d/

%changelog
* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 0.8.1-1
- Bug 1160861 - Prevent both frontends installed at same time
  (jhonce@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bug 1153313: Disable SSLv3 (lmeyer@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 0.6.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 0.6.0-2
- bumpspec to mass fix tags

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 0.5.2-1
- httpd conf: set better defaults (lmeyer@redhat.com)
- apache frontends: refactor logging conf, includes (lmeyer@redhat.com)
- apache frontends: move directives to global conf (lmeyer@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 0.4.4-1
- bz1072616 - split out log config from mod_rewrite definitions
  (admiller@redhat.com)

* Tue Mar 04 2014 Adam Miller <admiller@redhat.com> 0.4.3-1
- Move rev_proxy_host environment setting higher in the rules
  (bparees@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 0.4.2-1
- Merge pull request #4797 from bparees/jenkins_rproxy
  (dmcphers+openshiftbot@redhat.com)
- add proper reverse proxy config for jenkins (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.4.1-1
- frontend logging: keep openshift_log (bug 1069837) (lmeyer@redhat.com)
- Fix output from decode_connections (andy.goldstein@gmail.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 0.3.4-1
- Bug 1065133: Add websocket option to haproxy manifest and sanitize uri
  returned from mod_rewrite. (mrunalp@gmail.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 0.3.3-1
- Merge pull request #4716 from rajatchopra/bz_1058496
  (dmcphers+openshiftbot@redhat.com)
- fix file permissions for key/crt, bz1058496 (rchopra@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.3.2-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4666 from ncdc/dev/node-access-log-gear-info
  (dmcphers+openshiftbot@redhat.com)
- Update openshift_route.include (andy.goldstein@gmail.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Add app, gear UUIDs to openshift_log (andy.goldstein@gmail.com)
- Enable syslog configurability for frontend access logging
  (ironcladlou@gmail.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Bug 1024721 - Add purge functionality to the frontend plugins.
  (rmillner@redhat.com)
- bump_minor_versions for sprint 36 (admiller@redhat.com)
