Summary:        M-Collective agent file for gearchanger-m-collective-plugin
Name:           stickshift-mcollective-agent
Version:        0.0.2
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       rubygems
Requires:       rubygem-open4
Requires:       rubygem-json
Requires:       rubygem-stickshift-node
Requires:       mcollective
Requires:       facter
BuildArch:      noarch

%description
mcollective communication plugin for amqp 1.0 enabled qpid broker

%prep
%setup -q

%clean
rm -rf %{buildroot}

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/libexec/mcollective/mcollective/agent
mkdir -p %{buildroot}/usr/lib/ruby/site_ruby/1.8/facter
mkdir -p %{buildroot}/etc/cron.minutely
mkdir -p %{buildroot}/usr/libexec/mcollective

cp src/stickshift.rb %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp src/stickshift.ddl %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp facts/stickshift_facts.rb %{buildroot}/usr/lib/ruby/site_ruby/1.8/facter/
cp facts/stickshift-facts %{buildroot}/etc/cron.minutely/
cp facts/update_yaml.rb %{buildroot}/usr/libexec/mcollective/

%files
%defattr(-,root,root,-)
/usr/libexec/mcollective/mcollective/agent/stickshift.rb
/usr/libexec/mcollective/mcollective/agent/stickshift.ddl
/usr/lib/ruby/site_ruby/1.8/facter/stickshift_facts.rb
%attr(0700,-,-) /usr/libexec/mcollective/update_yaml.rb
%attr(0700,-,-) /etc/cron.minutely/stickshift-facts
/etc/cron.minutely/stickshift-facts


%changelog
* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Automatic commit of package [stickshift-mcollective-agent] release [0.0.1-1].
  (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

