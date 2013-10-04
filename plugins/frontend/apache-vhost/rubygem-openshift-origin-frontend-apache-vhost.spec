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
Version: 0.2.0
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
Conflicts:     rubygem(openshift-origin-frontend-apache-mod-rewrite)

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
  sed -i 's/include /IncludeOptional /g' httpd/000001_openshift_origin_node.conf
%endif



mkdir -p %{buildroot}/etc/httpd/conf.d/openshift
mv httpd/000001_openshift_origin_node.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/000001_openshift_origin_node_servername.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/frontend-vhost-https-template.erb %{buildroot}/etc/httpd/conf.d/openshift/
mv httpd/frontend-vhost-http-template.erb %{buildroot}/etc/httpd/conf.d/openshift/


%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node.conf
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node_servername.conf
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-http-template.erb
%config(noreplace) /etc/httpd/conf.d/openshift/frontend-vhost-https-template.erb
/etc/openshift/node-plugins.d/

%changelog
* Wed Sep 25 2013 Troy Dawson <tdawson@redhat.com> 0.1.6-1
- Bug 1010047 - The http configuration was also needed for an alias with an SSL
  cert since we get rid of the ServerAlias record for it. (rmillner@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 0.1.5-1
- Port ssl_to_gear changes to the frontend plugins. (rmillner@redhat.com)
- Fix up conflicts in frontend plugins. (rmillner@redhat.com)
- Bug 1010047 - Change alias handling to that SNI requests do not misroute.
  (rmillner@redhat.com)
- Report an error if there are no frontend plugins defined.
  (rmillner@redhat.com)

* Tue Sep 17 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- fixing tito tags

* Sat Sep 14 2013 Rob Millner <rmillner@redhat.com> 0.1.3-1
- Functional tests for the frontend plugins. (rmillner@redhat.com)
- Ensure ordering between the alias and base config file. (rmillner@redhat.com)

* Fri Sep 06 2013 Rob Millner <rmillner@redhat.com> 0.1.2-1
- Break out FrontendHttpServer class into plugin modules.
- Migration tool and fixes.

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Bug 988410 - Allow the userdel to safely fail if the user is already gone.
  (rmillner@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Cgroup module unit tests and bug fixes. (rmillner@redhat.com)
- Separate out libcgroup based functionality and add configurable templates.
  (rmillner@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Merge pull request #3160 from pravisankar/dev/ravi/card78
  (dmcphers+openshiftbot@redhat.com)
- For consistency, rest api response must display 'delete' instead 'destroy'
  for user/domain/app (rpenta@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Remove recursive requires node -> container plugin -> node
  https://bugzilla.redhat.com/show_bug.cgi?id=984575 (kraman@gmail.com)
- WIP: configure containerization plugin in node.conf (pmorie@gmail.com)
- Merge pull request #3099 from ironcladlou/dev/node-fixes
  (dmcphers+openshiftbot@redhat.com)
- Use oo_spawn for all root scoped shell commands (ironcladlou@gmail.com)
- Bug 984609 - fix a narrow condition where sshd leaves a root owned process in
  the frozen gear cgroup causing gear delete to fail and stale processes/
  (rmillner@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.0.7-1
- Merge pull request #3056 from kraman/libvirt-f19-2
  (dmcphers+openshiftbot@redhat.com)
- Bugfix #983308 (kraman@gmail.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 0.0.6-1
- Merge pull request #3016 from pmorie/dev/fix_tests
  (dmcphers+openshiftbot@redhat.com)
- Fix upgrade functionality and associated tests (pmorie@gmail.com)

* Tue Jul 09 2013 Adam Miller <admiller@redhat.com> 0.0.5-1
- Fix module path for FrontendProxyServer (kraman@gmail.com)
- Making module resolution for UserCreationException and UserDeletionException
  explicit (kraman@gmail.com)

* Mon Jul 08 2013 Adam Miller <admiller@redhat.com> 0.0.4-1
-  Revamp the cgroups and pam scripts to leverage the system setup for better
  performance and simplify the code. (rmillner@redhat.com)

* Wed Jul 03 2013 Adam Miller <admiller@redhat.com> 0.0.3-1
- artificial bump to get build reporting back in line (admiller@redhat.com)

* Wed Jul 03 2013 Adam Miller <admiller@redhat.com> 0.0.2-1
- First tito tag

* Sun Jun 23 2013 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

