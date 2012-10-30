Summary:        M-Collective agent file for openshift-origin-msg-node-mcollective
Name:           openshift-origin-msg-node-mcollective
Version: 1.0.1
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
BuildArch:      noarch
Obsoletes:      stickshift-mcollective-agent

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

cp src/openshift.rb %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp src/openshift.ddl %{buildroot}/usr/libexec/mcollective/mcollective/agent/
cp facts/openshift_facts.rb %{buildroot}/usr/lib/ruby/site_ruby/1.8/facter/
cp facts/openshift-facts %{buildroot}/etc/cron.minutely/
cp facts/update_yaml.rb %{buildroot}/usr/libexec/mcollective/

%files
%defattr(-,root,root,-)
/usr/libexec/mcollective/mcollective/agent/openshift.rb
/usr/libexec/mcollective/mcollective/agent/openshift.ddl
/usr/lib/ruby/site_ruby/1.8/facter/openshift_facts.rb
%attr(0700,-,-) /usr/libexec/mcollective/update_yaml.rb
%attr(0700,-,-) /etc/cron.minutely/openshift-facts
/etc/cron.minutely/openshift-facts


%changelog
* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Fri Oct 26 2012 Adam Miller <admiller@redhat.com> 0.4.6-1
- Parallelize application status call (rpenta@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.4.5-1
- Fixing obsoletes for openshift-origin-port-proxy (kraman@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.4.4-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.4.3-1
- Merge pull request #595 from mrunalp/dev/typeless (dmcphers@redhat.com)
- Typeless gear changes (mpatel@redhat.com)

* Wed Oct 03 2012 Adam Miller <admiller@redhat.com> 0.4.2-1
- BZ 862350: set proper file context when the yaml file is moved from /tmp to
  /etc (rmillner@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.3.2-1
- Bug 852139: Prevent emails to mailbox. (mpatel@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Thu Aug 16 2012 Adam Miller <admiller@redhat.com> 0.2.2-1
- adding rest api to fetch and update quota on gear group (abhgupta@redhat.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Wed Aug 01 2012 Adam Miller <admiller@redhat.com> 0.1.6-1
- Glob directories only once to calculate git repos and stopped apps.
  (mpatel@redhat.com)

* Mon Jul 30 2012 Dan McPherson <dmcphers@redhat.com> 0.1.5-1
- Merge pull request #288 from
  kraman/dev/kraman/features/remove_old_mcollective (mrunalp@gmail.com)
- Adding missed updates from when plugin was opensourced (kraman@gmail.com)

* Fri Jul 27 2012 Dan McPherson <dmcphers@redhat.com> 0.1.4-1
- Bug 843757 (dmcphers@redhat.com)
- Merge pull request #287 from mrunalp/bugs/841681 (rmillner@redhat.com)
- Fix for BZ841681. (mpatel@redhat.com)

* Thu Jul 26 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- US2439: Add support for getting/setting quota. (mpatel@madagascar.(none))

* Tue Jul 24 2012 Adam Miller <admiller@redhat.com> 0.1.2-1
- Add pre and post destroy calls on gear destruction and move unobfuscate and
  openshift origin-proxy out of cartridge hooks and into node. (rmillner@redhat.com)
- BROKE THE BUILD (admiller@redhat.com)
- BZ 841681: Make update_yaml single instance and use tmp file for
  generating/updating facts. (mpatel@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.0.5-1
- Fix validation. (mpatel@redhat.com)
- Add missing method to DDL. (mpatel@redhat.com)

* Tue Jul 10 2012 Adam Miller <admiller@redhat.com> 0.0.4-1
- Merge pull request #211 from kraman/dev/kraman/bugs/835489
  (dmcphers@redhat.com)
- Fix to work around a bug in mcollective that doesn't convert string true into
  a boolean anymore. (mpatel@redhat.com)
- Fix openshift origin DDL. (mpatel@redhat.com)
- Bugz 835489. Fixing location for district config file and adding in missing
  node_profile_enabled blocks (kraman@gmail.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.3-1
- don't send openshift origin logs to debug, instead use info (mmcgrath@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Automatic commit of package [openshift-origin-msg-node-mcollective] release [0.0.1-1].
  (kraman@gmail.com)
- Fix typo and remove dependency. (mpatel@redhat.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

