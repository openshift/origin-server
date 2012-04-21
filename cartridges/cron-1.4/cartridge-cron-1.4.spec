%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/cron-1.4

Name: cartridge-cron-1.4
Version: 0.5.2
Release: 1%{?dist}
Summary: Embedded cron support for express

Group: Network/Daemons
License: ASL 2.0
URL: https://engineering.redhat.com/trac/Libra
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-cron-1.4

Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: cronie
Requires: crontabs


%description
Provides rhc cron cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
mkdir -p %{buildroot}/%{_sysconfdir}/cron.d
mkdir -p %{buildroot}/%{_sysconfdir}/cron.minutely
mkdir -p %{buildroot}/%{_sysconfdir}/cron.hourly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.daily
mkdir -p %{buildroot}/%{_sysconfdir}/cron.weekly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.monthly
cp jobs/1minutely %{buildroot}/%{_sysconfdir}/cron.d
cp -r info %{buildroot}%{cartridgedir}/
cp -r jobs %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir}/jobs/stickshift-cron-minutely %{buildroot}/%{_sysconfdir}/cron.minutely/
ln -s %{cartridgedir}/jobs/stickshift-cron-hourly %{buildroot}/%{_sysconfdir}/cron.hourly/
ln -s %{cartridgedir}/jobs/stickshift-cron-daily %{buildroot}/%{_sysconfdir}/cron.daily/
ln -s %{cartridgedir}/jobs/stickshift-cron-weekly %{buildroot}/%{_sysconfdir}/cron.weekly/
ln -s %{cartridgedir}/jobs/stickshift-cron-monthly %{buildroot}/%{_sysconfdir}/cron.monthly/

%post
service crond restart || :


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/jobs/
%attr(0644,-,-) %{_sysconfdir}/cron.d/1minutely
%attr(0755,-,-) %{_sysconfdir}/cron.minutely/stickshift-cron-minutely
%attr(0755,-,-) %{_sysconfdir}/cron.hourly/stickshift-cron-hourly
%attr(0755,-,-) %{_sysconfdir}/cron.daily/stickshift-cron-daily
%attr(0755,-,-) %{_sysconfdir}/cron.weekly/stickshift-cron-weekly
%attr(0755,-,-) %{_sysconfdir}/cron.monthly/stickshift-cron-monthly
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Apr 12 2012 Mike McGrath <mmcgrath@redhat.com> 0.5.2-1
- release bump for tag uniqueness (mmcgrath@redhat.com)

* Mon Apr 02 2012 Krishna Raman <kraman@gmail.com> 0.4.3-1
- 

* Fri Mar 30 2012 Krishna Raman <kraman@gmail.com> 0.4.2-1
- Renaming for open-source release

* Sat Mar 17 2012 Dan McPherson <dmcphers@redhat.com> 0.4.1-1
- bump spec numbers (dmcphers@redhat.com)

* Thu Mar 15 2012 Dan McPherson <dmcphers@redhat.com> 0.3.4-1
- Fix for bugz 803658 - rename libra-cron-* scripts to stickshift-cron-*. The
  spec file was changed blindly as part of the libra to stickshift changes but
  not the actual file names themselves. (ramr@redhat.com)

* Wed Mar 14 2012 Dan McPherson <dmcphers@redhat.com> 0.3.3-1
- Bug 803267: Fixing incorrect path (rmillner@redhat.com)

* Fri Mar 09 2012 Dan McPherson <dmcphers@redhat.com> 0.3.2-1
- Batch variable name chage (rmillner@redhat.com)
- Adding export control files (kraman@gmail.com)
- replacing references to libra with stickshift (abhgupta@redhat.com)
- Updating cron li/libra => stickshift (kraman@gmail.com)

* Thu Feb 16 2012 Dan McPherson <dmcphers@redhat.com> 0.3.1-1
- bump spec numbers (dmcphers@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.2.3-1
- Merge branch 'master' of ssh://git1.ops.rhcloud.com/srv/git/li
  (rchopra@redhat.com)
- default profile name should match a listed profile (rchopra@redhat.com)
- Remove extra chmod - not needed. (ramr@redhat.com)
- Support job black/white listing via run-parts. (ramr@redhat.com)

* Mon Feb 13 2012 Dan McPherson <dmcphers@redhat.com> 0.2.2-1
- more abstracting out selinux (dmcphers@redhat.com)
- first pass at splitting out selinux logic (dmcphers@redhat.com)
- Updating models to improove schems of descriptor in mongo Moved
  connection_endpoint to broker (kraman@gmail.com)
- Fixing manifest yml files (kraman@gmail.com)
- Creating models for descriptor Fixing manifest files Added command to list
  installed cartridges and get descriptors (kraman@gmail.com)
- change status to use normal client_result instead of special handling
  (dmcphers@redhat.com)

* Fri Feb 03 2012 Dan McPherson <dmcphers@redhat.com> 0.2.1-1
- bump spec numbers (dmcphers@redhat.com)
- Also add the missed libra cron minutely script for: Reducto email and log
  redirection. (ramr@redhat.com)
- Reducto email and log redirection. Still log messages - useful for
  auditing/debugging. (ramr@redhat.com)
- Fix debug message to only be generated when debug is on ... not needed on
  production as it could potentially fill up mail spool files.
  (ramr@redhat.com)

* Wed Feb 01 2012 Dan McPherson <dmcphers@redhat.com> 0.1.7-1
- fix postgres move and other selinux move fixes (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 0.1.6-1
- add || : (dmcphers@redhat.com)
- move service restart for cron (dmcphers@redhat.com)

* Fri Jan 27 2012 Dan McPherson <dmcphers@redhat.com> 0.1.5-1
- Cleanup logging + rename to 1minutely for now. (ramr@redhat.com)
- Fix spec file for minutely addition and pretty print log output.
  (ramr@redhat.com)
- Add minutely freq as per a hallway ("t-shirt" folding) conversation - if its
  too excessive, can be trimmed down to a per-5 minute basis ala the
  competition. (ramr@redhat.com)
- deploy httpd proxy from migration (dmcphers@redhat.com)
- Keep only the last log 2 log files around. tidy doesn't look to clean
  embedded cartridge log files. (ramr@redhat.com)

* Wed Jan 25 2012 Dan McPherson <dmcphers@redhat.com> 0.1.4-1
- Log messages if user's $freq job exceeds max run time. (ramr@redhat.com)
- Add run time limits + added some log messages for auditing purposes.
  (ramr@redhat.com)
- Cleanup message displayed when cron is embedded into the app.
  (ramr@redhat.com)
- More bug fixes. (ramr@redhat.com)
- Merge branch 'master' of li-master:/srv/git/li (ramr@redhat.com)
- Fix installation paths. (ramr@redhat.com)
- Install libra wrapper job files. (ramr@redhat.com)

* Tue Jan 24 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- Updated License value in manifest.yml files. Corrected Apache Software
  License Fedora short name (jhonce@redhat.com)
- rhc-cartridge-cron-1.4: Modified license to ASL V2 (jhonce@redhat.com)

* Mon Jan 23 2012 Ram Ranganathan <ramr@redhat.com> 0.1.2-1
- new package built with tito

* Tue Jan 17 2012 Ram Ranganathan <ramr@redhat.com> 0.1-1
- Initial packaging
