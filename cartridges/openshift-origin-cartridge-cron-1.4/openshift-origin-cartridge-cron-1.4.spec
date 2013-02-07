%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/cron-1.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/cron-1.4

Summary:       Embedded cron support for express
Name:          openshift-origin-cartridge-cron-1.4
Version:       1.5.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      cronie
Requires:      crontabs
BuildArch:     noarch
Obsoletes:     cartridge-cron-1.4

%description
Provides OpenShift cron cartridge support

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
mkdir -p %{buildroot}/%{_sysconfdir}/cron.d
mkdir -p %{buildroot}/%{_sysconfdir}/cron.minutely
mkdir -p %{buildroot}/%{_sysconfdir}/cron.hourly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.daily
mkdir -p %{buildroot}/%{_sysconfdir}/cron.weekly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.monthly
cp -p jobs/1minutely %{buildroot}/%{_sysconfdir}/cron.d
cp -rp info %{buildroot}%{cartridgedir}/
cp -rp jobs %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir}/jobs/openshift-origin-cron-minutely %{buildroot}/%{_sysconfdir}/cron.minutely/
ln -s %{cartridgedir}/jobs/openshift-origin-cron-hourly %{buildroot}/%{_sysconfdir}/cron.hourly/
ln -s %{cartridgedir}/jobs/openshift-origin-cron-daily %{buildroot}/%{_sysconfdir}/cron.daily/
ln -s %{cartridgedir}/jobs/openshift-origin-cron-weekly %{buildroot}/%{_sysconfdir}/cron.weekly/
ln -s %{cartridgedir}/jobs/openshift-origin-cron-monthly %{buildroot}/%{_sysconfdir}/cron.monthly/

%post
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
  systemctl restart  crond.service || :
%else
  service crond restart || :
%endif

%files
%doc COPYRIGHT LICENSE
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/jobs/
%attr(0755,-,-) %{frameworkdir}
%dir %{_sysconfdir}/cron.minutely
%config(noreplace) %attr(0644,-,-) %{_sysconfdir}/cron.d/1minutely
%attr(0755,-,-) %{_sysconfdir}/cron.minutely/openshift-origin-cron-minutely
%attr(0755,-,-) %{_sysconfdir}/cron.hourly/openshift-origin-cron-hourly
%attr(0755,-,-) %{_sysconfdir}/cron.daily/openshift-origin-cron-daily
%attr(0755,-,-) %{_sysconfdir}/cron.weekly/openshift-origin-cron-weekly
%attr(0755,-,-) %{_sysconfdir}/cron.monthly/openshift-origin-cron-monthly
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml

%changelog
* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.2-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Add locking in cron cartridge (pmorie@gmail.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- BZ 877325: Added websites. (rmillner@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Eliminate duplicate version of this script. (rmillner@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Cleanup spec to Fedora standards (tdawson@redhat.com)
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- Fix for Bug 865358 (jhonce@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.10.4-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.10.3-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.9.2-1
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.9.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

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
- Merge branch 'master' of github.com:openshift/origin-server (rmillner@redhat.com)
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
