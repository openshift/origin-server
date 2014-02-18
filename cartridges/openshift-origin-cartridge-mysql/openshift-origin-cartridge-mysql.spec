%global cartridgedir %{_libexecdir}/openshift/cartridges/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 1.21.0
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

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/mysql_context.rhel %{buildroot}%{cartridgedir}/lib/mysql_context
%endif

%if 0%{?fedora} > 18
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/mysql_context.fedora %{buildroot}%{cartridgedir}/lib/mysql_context
%endif

# Remove what left
%__rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*
%__rm %{buildroot}%{cartridgedir}/lib/mysql_context.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
