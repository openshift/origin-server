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
Version: 1.17.1.3
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

conf='/etc/httpd/conf.d/000002_openshift_origin_broker_proxy.conf'
if ! grep  'RequestHeader unset X-Remote-User' $conf 2>&1 > /dev/null
then
  cat <<EOF >> $conf
# Required for the remote-user plugin
RequestHeader unset X-Remote-User
EOF

  if service httpd status 2>&1 > /dev/null
  then
    service httpd restart
  fi
fi

%changelog
* Thu Jan 16 2014 Krishna Raman <kraman@gmail.com> 1.17.1.3-1
- Bumping version number for rubygem-openshift-origin-auth-remote-user
  (kraman@gmail.com)
- Fix regex for base64 encoded broker auth iv/token values (kraman@gmail.com)

* Tue Jan 14 2014 Krishna Raman <kraman@gmail.com> 1.17.1.2-1
- Bumping package versions (kraman@gmail.com)
- Add passthrough config for broker auth (iv/token) based on request headers
  (kraman@gmail.com)

* Fri Dec 06 2013 Krishna Raman <kraman@gmail.com> 1.17.1.1-1
- Bumping versions for OpenShift Origin Release 3 (kraman@gmail.com)

* Wed Dec 04 2013 Krishna Raman <kraman@gmail.com> 1.17.1.1-1
- 

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 1.17.1-1
- bump_minor_versions for sprint 36 (admiller@redhat.com)

* Fri Oct 25 2013 Adam Miller <admiller@redhat.com> 1.16.2-1
- Add config value (jliggitt@redhat.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.16.1-1
- bump_minor_versions for sprint 35 (admiller@redhat.com)

* Thu Oct 03 2013 Adam Miller <admiller@redhat.com> 1.15.2-1
- Updating tests to register mongo-auth based user in the correct database
  based on Rails environment. (kraman@gmail.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Tue Jul 30 2013 Adam Miller <admiller@redhat.com> 1.12.3-1
- Merge pull request #2941 from Miciah/fix-plugins-auth-remote-user-post-
  scriptlet (dmcphers+openshiftbot@redhat.com)
- Fixing comprehensive doc to include latest changes in broker/node setup.
  Fixing openshift-origin-auth-remote-user-* for Apache 2.2 and 2.4 Fixing
  openshift-origin-console.spec to include missing gems (kraman@gmail.com)
- remote-user: Fix .conf migration in %%post (miciah.masters@gmail.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- <broker> re-base the broker URI from /broker => / (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Avoid harmless but annoying deprecation warning (asari.ruby@gmail.com)
- KrbLocalUserMapping enables conversion to local users.
  (jpazdziora@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- Letting environment unprotected is ok, it matches openshift.com.
  (jpazdziora@redhat.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Merge pull request #1858 from mscherer/fix/gem_spec/auth_remote
  (dmcphers+openshiftbot@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Adding support for Bearer auth in the sample remote-user plugin
  (bleanhar@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Fix gemspec for missing and incorrect requirement (misc@zarb.org)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- fix the extension of the ldif file ( used by vim for syntaxic coloration )
  (mscherer@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 1.6.3-1
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Make packages build/install on F19+ (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- RemoteUserAuthService should use authenticate_request, not authenticate
  (ccoleman@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- Implement authorization support in the broker (ccoleman@redhat.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- fix rubygem sources (tdawson@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Fixes for ruby193 (john@ibiblio.org)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- Merge pull request #1289 from
  smarterclayton/isolate_api_behavior_from_base_controller
  (dmcphers+openshiftbot@redhat.com)
- Merge branch 'improve_action_logging' into
  isolate_api_behavior_from_base_controller (ccoleman@redhat.com)
- change %%define to %%global (tdawson@redhat.com)
- Remove legacy login() method on authservice (ccoleman@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

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
