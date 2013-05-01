%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/phpmyadmin-3.4
%global frameworkdir %{_libexecdir}/openshift/cartridges/phpmyadmin-3.4

Summary:       Embedded phpMyAdmin support for express
Name:          openshift-origin-cartridge-phpmyadmin-3.4
Version: 1.8.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      phpMyAdmin
Requires:      httpd < 2.4
BuildArch:     noarch

%description
Provides rhc phpMyAdmin cartridge support

%prep
%setup -q

%build

%install
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

%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
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
* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Fixing broker extended tests (abhgupta@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- fix references to rhc app cartridge (dmcphers@redhat.com)
- fix for bug 893876 (abhgupta@redhat.com)
- specifying Requires for 10gen-mms and phpmyadmin cartridges
  (abhgupta@redhat.com)
- Manifest file fixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 903139 (dmcphers@redhat.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

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
