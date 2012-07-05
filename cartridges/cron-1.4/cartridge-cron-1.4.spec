%global cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/cron-1.4

Name: cartridge-cron-1.4
Version: 0.8.3
Release: 1%{?dist}
Summary: Embedded cron support for express

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

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
rm -rf %{buildroot}


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
* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.8.3-1
- Merge pull request #176 from rajatchopra/master (rpenta@redhat.com)
- Optimize cron run time - down to 0.5 seconds on a c9 instance.
  (ramr@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.8.2-1
- Fix for bugz 837130. (ramr@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.8.1-1
- bumping spec versions (admiller@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.7.3-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.7.2-1
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)
- For US2109, fixup usage of repo and logs in cartridges. (ramr@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.7.1-1
- bumping spec versions (admiller@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.6.4-1
- Merge branch 'master' of github.com:openshift/crankcase (rmillner@redhat.com)
- Some of the ctl script were not sourcing util from abstract.
  (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.6.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.6.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.6.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.5.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.5.4-1
- new package built with tito
