%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-dns-route53
%global rubyabi 1.9.1

Summary:       OpenShift plugin for AWS Route53 service
Name:          rubygem-%{gem_name}
Version:       1.10.2
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{gem_name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      rubygem(openshift-origin-common)
Requires:      openshift-origin-broker
Requires:      %{?scl:%scl_prefix}rubygem-aws-sdk >= 1.8.0
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: ruby193-build
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
Provides an AWS Route53  DNS update service based plugin

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p ./%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec
rdoc
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
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

#Config file
mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-dns-route53.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-route53.conf.example


%files
%doc %{gem_docdir}
%doc %{_docdir}/%{name}-%{version}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/plugins.d/openshift-origin-dns-route53.conf.example


%changelog
* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- Bug 928675 (asari.ruby@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.5.2-1
- Updating rest-client and rake gem versions to match F18 (kraman@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.1-1
- Add yard documentation markup to DNS plugins (mlamouri@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.0-1
- Update to version 1.5.0

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Fix up tag after initial github merge

* Wed Feb 20 2013 Mark Lamourine <<mlamouri@redhat.com>> 0.1.4-1
- update copyright (mlamouri@redhat.com)
- remove references to selinux (mlamouri@redhat.com)
- Create DNS plugin using Amazon Web Services Route 53 (mlamouri@redhat.com)

* Thu Feb 14 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.3-1
- new package built with tito

* Thu Feb 14 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.2-1
- get packaging to work
- added example file and ignore doc directory (mlamouri@redhat.com)
- create rdoc documentation (mlamouri@redhat.com)
- cleaning packaging (mlamouri@redhat.com)

* Thu Feb 14 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.1-1
- new package built with tito

* Mon Feb 11 2013 Mark Lamourine <mlamouri@redhat.com> 0.1.0
- Initial checkin of a skeleton for a new plugin
