%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/phpmyadmin-3.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/phpmyadmin-3.4

Name: openshift-origin-cartridge-phpmyadmin-3.4
Version: 1.4.0
Release: 1%{?dist}
Summary: Embedded phpMyAdmin support for express

Group: Applications/Internet
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: phpMyAdmin
Obsoletes: cartridge-phpmyadmin-3.4

%description
Provides rhc phpMyAdmin cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
ln -s %{cartridgedir}/../../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}

%post
cp %{cartridgedir}/info/configuration/etc/phpMyAdmin/config.inc.php %{_sysconfdir}/phpMyAdmin/config.inc.php

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/html/
%attr(0644,-,-) %{cartridgedir}/info/html/*
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.4-1
- Bug 903139 Removing user/pw from cart props since this cart doesnt control
  them (dmcphers@redhat.com)

* Tue Jan 22 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Fix typos in rhc instructions displayed to client (ironcladlou@gmail.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.2-1
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- US2770: [cartridges-new] Re-implement scripts (part 1) (jhonce@redhat.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Fri Nov 16 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- BZ 877325: Added websites. (rmillner@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Fri Oct 19 2012 Adam Miller <admiller@redhat.com> 0.20.5-1
- BZ 843286: Enable auth files via htaccess (rmillner@redhat.com)

* Mon Oct 08 2012 Dan McPherson <dmcphers@redhat.com> 0.20.4-1
- renaming crankcase -> origin-server (dmcphers@redhat.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.20.3-1
- new package built with tito

* Thu Oct 04 2012 Adam Miller <admiller@redhat.com> 0.20.2-1
- Typeless gear changes (mpatel@redhat.com)

* Wed Sep 12 2012 Adam Miller <admiller@redhat.com> 0.20.1-1
- bump_minor_versions for sprint 18 (admiller@redhat.com)

* Fri Sep 07 2012 Adam Miller <admiller@redhat.com> 0.19.4-1
- Merge pull request #451 from pravisankar/dev/ravi/zend-fix-description
  (openshift+bot@redhat.com)
- Return display_name, description fields in RestCartridge model
  (rpenta@redhat.com)

* Thu Sep 06 2012 Adam Miller <admiller@redhat.com> 0.19.3-1
- Fix for bugz 852518 - Failed move due to httpd.pid file being empty.
  (ramr@redhat.com)

* Thu Aug 30 2012 Adam Miller <admiller@redhat.com> 0.19.2-1
- Fix for bugz 852518 - Failed move due to httpd.pid file being empty.
  (ramr@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.19.1-1
- bump_minor_versions for sprint 17 (admiller@redhat.com)

* Wed Aug 22 2012 Adam Miller <admiller@redhat.com> 0.18.3-1
- Update manifest to register cartridge data. (rmillner@redhat.com)

* Tue Aug 14 2012 Adam Miller <admiller@redhat.com> 0.18.2-1
- Fix broken cartridge hook symlinks (ironcladlou@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.18.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Wed Aug 01 2012 Adam Miller <admiller@redhat.com> 0.17.4-1
- Merge pull request #311 from rmillner/dev/rmillner/bug/843326
  (rmillner@redhat.com)
- Some frameworks (ex: mod_wsgi) need HTTPS set to notify the app that https
  was used. (rmillner@redhat.com)

* Tue Jul 31 2012 Adam Miller <admiller@redhat.com> 0.17.3-1
- Move direct calls to httpd init script to httpd_singular locking script
  (rmillner@redhat.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.17.2-1
- Fixes for bugz 840030 - Apache blocks access to /icons. Remove these as
  mod_autoindex has now been turned OFF (see bugz 785050 for more details).
  (ramr@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.17.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Thu Jul 05 2012 Adam Miller <admiller@redhat.com> 0.16.2-1
- more cartridges have better metadata (rchopra@redhat.com)
- Merge pull request #161 from VojtechVitek/php.ini-max_file_uploads
  (mmcgrath+openshift@redhat.com)
- cart metadata work merged; depends service added; cartridges enhanced; unit
  tests updated (rchopra@redhat.com)
- Add max_file_uploads INI setting to php.ini files (vvitek@redhat.com)

* Wed Jun 20 2012 Adam Miller <admiller@redhat.com> 0.16.1-1
- bump_minor_versions for sprint 14 (admiller@redhat.com)

* Fri Jun 15 2012 Adam Miller <admiller@redhat.com> 0.15.3-1
- Security - BZ785050 removed mod_autoindex from the two httpd.conf files
  (tkramer@redhat.com)

* Fri Jun 15 2012 Tim Kramer <tkramer@redhat.com>
- Fix for BZ785050 remove mod_autoindex from httpd.confs (tkramer@redhat.com)

* Thu Jun 14 2012 Adam Miller <admiller@redhat.com> 0.15.2-1
- Fix for bug 812046 (abhgupta@redhat.com)

* Fri Jun 01 2012 Adam Miller <admiller@redhat.com> 0.15.1-1
- bumping spec versions (admiller@redhat.com)

* Thu May 24 2012 Adam Miller <admiller@redhat.com> 0.14.4-1
- disabling cgroups for deconfigure and configure events (mmcgrath@redhat.com)

* Tue May 22 2012 Dan McPherson <dmcphers@redhat.com> 0.14.3-1
- Automatic commit of package [openshift-origin-cartridge-phpmyadmin-3.4] release [0.14.2-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (jhonce@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-phpmyadmin-3.4] release [0.13.4-1].
  (admiller@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Merge branch 'master' into US2109 (ramr@redhat.com)
- Typeless gears - create app/ dir, rollback logs, manage repo, data and state.
  (ramr@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.14.2-1
- silence the overlaping alias issues (mmcgrath@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.14.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.13.4-1
- Bug 819739 (dmcphers@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.13.3-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.13.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.13.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.12.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.12.4-1
- new package built with tito
