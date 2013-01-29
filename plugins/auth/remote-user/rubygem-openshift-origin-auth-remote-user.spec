%define brokerdir %{_var}/www/openshift/broker

%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-auth-remote-user
%global rubyabi 1.9.1

Summary:        OpenShift plugin for remote-user authentication
Name:           rubygem-%{gem_name}
Version: 1.4.2
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       rubygem(openshift-origin-common)
Requires:       %{?scl:%scl_prefix}rubygem(json)
Requires:       openshift-broker

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version

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

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
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
  sed -i -e 's/AuthName.*/AuthName "OpenShift Broker API"/' /var/www/openshift/broker/httpd/conf.d/openshift-origin-auth-remote-user.conf
fi

%changelog
* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- 875575 (dmcphers@redhat.com)
- separate out console and broker realms per BZ893369 (lmeyer@redhat.com)
- %%post script to fix the realm from any previous install. (lmeyer@redhat.com)
- removing app templates and other changes (dmcphers@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #697 from Miciah/plugins-auth-remote-user-README-updates
  (dmcphers+openshiftbot@redhat.com)
- remote-user README: delete known issues that have been resolved
  (miciah.masters@gmail.com)
- remote-user README: fix name of openshift-broker service
  (miciah.masters@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- add oo-ruby (dmcphers@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- add config to gemspec (dmcphers@redhat.com)
- Moving plugins to Rails 3.2.8 engine (kraman@gmail.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)
