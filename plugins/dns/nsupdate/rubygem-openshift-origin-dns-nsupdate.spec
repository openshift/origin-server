%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-dns-nsupdate
%global rubyabi 1.9.1

Summary:       OpenShift plugin for DNS update service using nsupdate
Name:          rubygem-%{gem_name}
Version:       1.16.3
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
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      rubygem(openshift-origin-common)
Requires:      bind-utils
# GSS-API requires kinit
Requires:      krb5-workstation
Requires:      openshift-origin-broker
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
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
Provides a DNS service update plugin using nsupdate

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
#cp -r doc/* %{buildroot}%{_docdir}/%{name}-%{version}/

#Config file
mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-dns-nsupdate.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf.example

%files
%doc %{gem_docdir}
%doc %{_docdir}/%{name}-%{version}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf.example


%changelog
* Tue Aug 19 2014 Adam Miller <admiller@redhat.com> 1.16.3-1
- Corrected cmd to enable correctly returning STDERR from nsupdate as STDOUT
  Added fqdn to modify_dns method Moved Rails.logger.error to before the raise
  (tiwillia@redhat.com)
- Pass dns action for logger as a string rather than a boolean
  (tiwillia@redhat.com)
- Split duplicate code into seperate method (tiwillia@redhat.com)
- Follow rc convention and use Rails.logger to avoid large amounts of text in
  the exception string (tiwillia@redhat.com)
- nsupdate_plugin: Exception logging now includes error output from nsupdate
  command (tiwillia@redhat.com)
- Merge pull request #5368 from Miciah/specify-key-algorithm-in-nsupdate-
  plugin-del_cmd-and-oo-diagnostics (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4817 from Miciah/plugins-dns-nsupdate-fix-example-of-key-
  algorithm (dmcphers+openshiftbot@redhat.com)
- Add key algorithm for record removal (calfonso@redhat.com)
- plugins/dns/nsupdate: Fix example of key algorithm (miciah.masters@gmail.com)

* Tue Mar 18 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- version bump for openshift-origin-console and dns-nsupdate for OSE rebase
  (admiller@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)
- Merge pull request #3585 from Miciah/plugins-dns-nsupdate-delete-duplicate-
  kinit-command (dmcphers+openshiftbot@redhat.com)
- plugins/dns/nsupdate: Delete duplicate kinit (miciah.masters@gmail.com)
- plugins/dns/nsupdate: Support unauthenticated use (miciah.masters@gmail.com)
- plugins/dns/nsupdate: Specify zone (miciah.masters@gmail.com)

