%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-routing-activemq
%global rubyabi 1.9.1

Summary:       OpenShift plugin for publishing routing information on ActiveMQ
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
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      rubygem(openshift-origin-common)
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

%description
OpenShift plug-in for publishing routing information on an ActiveMQ queue.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Build and install into the rubygem structure
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp conf/openshift-origin-routing-activemq.conf.example %{buildroot}/etc/openshift/plugins.d/openshift-origin-routing-activemq.conf.example

%files
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE README
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
/etc/openshift/plugins.d/openshift-origin-routing-activemq.conf.example

%changelog
* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 0.8.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 0.7.2-1
- BZ1165606 - enable activemq ssl connections for routing (calfonso@redhat.com)
- BZ#1128857 - Fixes failover of activemq hosts during broker publish
  (calfonso@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Tue Oct 07 2014 Adam Miller <admiller@redhat.com> 0.6.2-1
- SPI routing amq plugin: remove deprecated actions (lmeyer@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 0.5.2-1
- plugins/routing/activemq: s/TOPIC/DESTINATION/ (miciah.masters@gmail.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 0.4.2-1
- plugins/routing/activemq: Take array of hosts (miciah.masters@gmail.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.3.2-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 0.3.1-1
- Allow gemspecs to be parsed on non RPM systems (like the rest of cartridges)
  (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 0.2.3-1
- Route changes (ccoleman@redhat.com)

