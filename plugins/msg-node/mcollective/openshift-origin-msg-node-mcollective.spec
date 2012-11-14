%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%if 0%{?fedora}
    %global vendor_ruby /usr/share/ruby/vendor_ruby/
%endif
%if 0%{?rhel}
    %global vendor_ruby /opt/rh/ruby193/root/usr/share/ruby/vendor_ruby/
%endif

Summary:        M-Collective agent file for openshift-origin-msg-node-mcollective
Name:           openshift-origin-msg-node-mcollective
Version: 1.1.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       rubygems
Requires:       rubygem-open4
Requires:       rubygem-json
Requires:       rubygem-openshift-origin-node
Requires:       mcollective
Requires:       facter
%if 0%{?fedora}%{?rhel} <= 6
Requires:       %{?scl:%scl_prefix}mcollective-common
Requires:       %{?scl:%scl_prefix}facter
%endif
BuildArch:      noarch
Obsoletes:      openshift-mcollective-agent

%description
mcollective communication plugin

%prep
%setup -q

%clean
rm -rf %{buildroot}

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/libexec/mcollective/mcollective/agent
mkdir -p %{buildroot}%{vendor_ruby}facter
mkdir -p %{buildroot}/etc/cron.minutely
mkdir -p %{buildroot}/usr/libexec/mcollective

cp src/openshift.rb %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp src/openshift.ddl %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp facts/openshift_facts.rb %{buildroot}%{vendor_ruby}facter
cp facts/openshift-facts %{buildroot}/etc/cron.minutely/
cp facts/update_yaml.rb %{buildroot}/usr/libexec/mcollective/

%files
%defattr(-,root,root,-)
/usr/libexec/mcollective/mcollective/agent/openshift.rb
/usr/libexec/mcollective/mcollective/agent/openshift.ddl
%{vendor_ruby}facter/openshift_facts.rb
%attr(0700,-,-) /usr/libexec/mcollective/update_yaml.rb
%attr(0700,-,-) /etc/cron.minutely/openshift-facts
/etc/cron.minutely/openshift-facts


%changelog
* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)
