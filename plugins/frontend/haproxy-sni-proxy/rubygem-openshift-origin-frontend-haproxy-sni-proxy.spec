%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-frontend-haproxy-sni-proxy
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift

Summary:       OpenShift HAProxy SNI Proxy frontend plugin
Name:          rubygem-%{gem_name}
Version: 0.5.1
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
Requires:      openshift-origin-node-proxy
%if 0%{?fedora}%{?rhel} <= 6
Requires:      /usr/sbin/haproxy15
Requires:      haproxy
%else
Requires:      haproxy >= 1.5
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
Provides the HAProxy SNI Proxy plugin for OpenShift frontends.


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
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-frontend-haproxy-sni-proxy.conf %{buildroot}/etc/openshift/node-plugins.d/

mkdir -p %{buildroot}%{appdir}/.httpd.d
echo '{}' > %{buildroot}%{appdir}/.httpd.d/sniproxy.json
touch %{buildroot}%{appdir}/.httpd.d/sniproxy.cfg
install -m 640 httpd/*.erb %{buildroot}%{appdir}/.httpd.d/

mkdir -p %{buildroot}/etc/rc.d/init.d/
install -m 755 scripts/openshift-sni-proxy %{buildroot}/etc/rc.d/init.d/

mkdir -p %{buildroot}/usr/bin
install -m 755 scripts/oo-rebuild-haproxy-sni-proxy %{buildroot}/usr/bin

%post
test -s %{appdir}/.httpd.d/sniproxy.cfg || oo-rebuild-haproxy-sni-proxy
/sbin/chkconfig --add openshift-sni-proxy
/sbin/service openshift-sni-proxy condrestart || :

%preun
if [ $1 -eq 0 ]
then
    /sbin/service openshift-sni-proxy stop || :
    /sbin/chkconfig --del openshift-sni-proxy
fi

%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
%attr(0755,root,root) /etc/rc.d/init.d/openshift-sni-proxy
%attr(0755,root,root) /usr/bin/oo-rebuild-haproxy-sni-proxy
%attr(0640,root,haproxy) %config(noreplace) %{appdir}/.httpd.d/sniproxy.json
%attr(0640,root,haproxy) %config(noreplace) %{appdir}/.httpd.d/sniproxy.cfg
%attr(0644,root,root) %config(noreplace) %{appdir}/.httpd.d/*.erb
%attr(0644,root,root) %config(noreplace) /etc/openshift/node-plugins.d/openshift-origin-frontend-haproxy-sni-proxy.conf

%changelog
* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 0.4.2-1
- sni-proxy: have restart re-create conf (lmeyer@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Fri Aug 22 2014 Adam Miller <admiller@redhat.com> 0.3.2-1
- The output message about TLS URLs is not clear when creating jboss-amq
  cartridge (bparees@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.2.2-1
- Cleaning specs (dmcphers@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- Bug 1026969 - rebuild the SNI proxy on start to track changing IP address.
  (rmillner@redhat.com)
- Bug 1024721 - Add purge functionality to the frontend plugins.
  (rmillner@redhat.com)
- bump_minor_versions for sprint 36 (admiller@redhat.com)

