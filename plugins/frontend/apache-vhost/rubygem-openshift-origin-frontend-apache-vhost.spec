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
Version: 0.13.1
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

Conflicts: rubygem-openshift-origin-frontend-apache-mod-rewrite

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
mv httpd/openshift-vhost-logconf.include %{buildroot}/etc/httpd/conf.d/


%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_frontend_vhost.conf
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-http-template.erb
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-https-template.erb
%config(noreplace) /etc/httpd/conf.d/openshift-vhost-logconf.include
/etc/openshift/node-plugins.d/

%changelog
* Thu Sep 17 2015 Unknown name 0.13.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Tue Aug 11 2015 Wesley Hearn <whearn@redhat.com> 0.12.4-1
- openshift-origin-frontend-apache-vhost: Bumping version due to error in
  building (whearn@redhat.com)
- Bug 1243532 - Downcase legacy app names in vhost setup (agrimm@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 0.12.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 0.11.3-1
- Merge pull request #5954 from ncdc/bug/1161072-vhost-multi-ha-app-dns
  (dmcphers+openshiftbot@redhat.com)
- Register app dns vhost for secondary haproxy gears (agoldste@redhat.com)

* Wed Nov 12 2014 Adam Miller <admiller@redhat.com> 0.11.2-1
- Revert "Add logging about idling/unidling in vhost plugin"
  (agoldste@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 0.11.1-1
- Merge pull request #5935 from jwhonce/bug/1161263
  (dmcphers+openshiftbot@redhat.com)
- Bug 1161263 - Support class method truncate() (jhonce@redhat.com)
- Add logging about idling/unidling in vhost plugin (agoldste@redhat.com)
- File.join -> PathUtils.join (agoldste@redhat.com)
- Bug 1160861 - Prevent both frontends installed at same time
  (jhonce@redhat.com)
- Bug 1160752 - Make apache-vhost more atomic (jhonce@redhat.com)
- Bug 1160652 - Set defaults for the new crt/key/chain apache vhost plugin
  configuration (bleanhar@redhat.com)
- for custom certs; chain file is the same as ssl file (rchopra@redhat.com)
- make the default crt/key/chain file to be configurable in vhost template
  (rchopra@redhat.com)
- fix bz 1156361. Race condition between destroy-app and configure.
  (rchopra@redhat.com)
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 0.10.2-1
- Bug 1153313: Disable SSLv3 (lmeyer@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Mon Sep 08 2014 Adam Miller <admiller@redhat.com> 0.9.3-1
- Apply more restrictive permissions to cert files (ironcladlou@gmail.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 0.9.2-1
- consistent trailing slashes - bz1133694 (rchopra@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 0.9.1-1
- move env var guard for all http plugins and not just the vhost plugin
  (rchopra@redhat.com)
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 0.8.2-1
- put apache reload in guard of an env variable (rchopra@redhat.com)
- bz1131404 - ProxyPassReverse fix (rchopra@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 0.8.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bug 1101836: Apache shouldn't disable backend when it can't connect to it.
  (mrunalp@gmail.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 0.7.1-1
- apache-vhost: fix BZ 1090358 on moving custom certs (lmeyer@redhat.com)
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed Apr 30 2014 Adam Miller <admiller@redhat.com> 0.6.3-1
- vhost frontend: fix annotation logging (lmeyer@redhat.com)

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
- Merge pull request #4850 from vbatts/408-3-rewrite_to_proxypass
  (dmcphers+openshiftbot@redhat.com)
- vhost-plugin: remove keepalive=On for now (vbatts@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)
- vhost-plugin: switch from rewrite back to proxypass (vbatts@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 0.4.2-1
- Merge pull request #4797 from bparees/jenkins_rproxy
  (dmcphers+openshiftbot@redhat.com)
- add proper reverse proxy config for jenkins (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.4.1-1
- frontend logging: keep openshift_log (bug 1069837) (lmeyer@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

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
