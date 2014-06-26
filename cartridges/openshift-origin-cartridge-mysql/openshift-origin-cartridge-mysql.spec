%global cartridgedir %{_libexecdir}/openshift/cartridges/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 1.26.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mysql-server
Requires:      mysql-devel
Requires:      mysql-connector-java
# For RHEL6 install mysql55 from SCL
%if 0%{?rhel}
Requires:      mysql55
Requires:      mysql55-mysql-devel
%endif
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-mysql-5.1 = 2.0.0
Obsoletes:     openshift-origin-cartridge-mysql-5.1 <= 1.99.9
BuildArch:     noarch

%description
Provides mysql cartridge support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/conf
%{cartridgedir}/env
%{cartridgedir}/lib
%{cartridgedir}/metadata
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Merge pull request #5256 from mfojtik/bugzilla/1086807
  (dmcphers+openshiftbot@redhat.com)
- Bug 1086807 - Advertise $PATH for scaled SCL based cartridges
  (mfojtik@redhat.com)
- Bug 1103367: Increasing timeout of the stop action in the MySQL cartridge
  (jhadvig@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Wed May 07 2014 Adam Miller <admiller@redhat.com> 1.24.4-1
- Bump cartridge versions for STG cut (vvitek@redhat.com)

* Tue May 06 2014 Troy Dawson <tdawson@redhat.com> 1.24.3-1
- Bug 1092635 - Assume zero-byte dump file is quota error and report
  (jhonce@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Bug 1085282 - Added OPENSHIFT_MYSQL_AIO variable to allow users to disable
  mysql AIO support (mfojtik@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Revert "Updated cartridges to stop after post_restore" (bparees@redhat.com)
- Merge pull request #5063 from bparees/config_mysql_table_cache
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)
- MySQL table_open_cache size unusually small (bparees@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Updated cartridges to stop after post_restore (mfojtik@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- fix bash regexp in upgrade scripts (vvitek@redhat.com)
- Update mysql cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- Bug 1066945 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Merge pull request #4591 from mfojtik/bugzilla/1051348
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051348 - Added skip-name-resolve to my.cnf (mfojtik@redhat.com)
- Fix path to my.cnf when calling mysql/bin/control restart
  (mfojtik@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Bump up cartridge versions (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4459 from mfojtik/bugzilla/1045342
  (dmcphers+openshiftbot@redhat.com)
- Bug 1045342 - Fix the $MYSQL_VERSION env var is missing for mysql-5.1
  (mfojtik@redhat.com)
- Bug 1051651 - Added more verbose error reporting when MySQL fail to start
  (mfojtik@redhat.com)
- Removed double-slash from my.conf.erb (mfojtik@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Merge pull request #4395 from andrewklau/master
  (dmcphers+openshiftbot@redhat.com)
- Fix quotation for --password in mysql cartridge control file
  (mfojtik@redhat.com)
- mysql cartridge was using a postgresql variable
  (andrew.lau@ready2order.com.au)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- adding OPENSHIFT_MYSQL_TIMEZONE env variable (jhadvig@redhat.com)
