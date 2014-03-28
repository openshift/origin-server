%global cartridgedir %{_libexecdir}/openshift/cartridges/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 1.23.0
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
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
