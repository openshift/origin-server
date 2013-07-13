%global cartridgedir %{_libexecdir}/openshift/cartridges/mysql

Summary:       Provides embedded mysql support
Name:          openshift-origin-cartridge-mysql
Version: 0.6.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mysql-server
Requires:      mysql-devel
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-mysql-5.1

%description
Provides mysql cartridge support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%posttrans
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 0.5.3-1
- Fix bug 981622 (pmorie@gmail.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Wed Jun 19 2013 Adam Miller <admiller@redhat.com> 0.4.3-1
- Bug 970914 - Mysql big data snapshot restore failed (fotios@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Bug 971296: Display mysql environment variables rather than IPs during
  install (ironcladlou@gmail.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Merge pull request #2596 from fotioslindiakos/Bug960707
  (dmcphers+openshiftbot@redhat.com)
- Bug960707: MySQL snapshot and restore across applications (fotios@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Bug 962662 (dmcphers@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.3.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Special file processing (fotios@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- Merge pull request #2246 from ironcladlou/bz/955538
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2241 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2239 from jwhonce/wip/raw_envvar
  (dmcphers+openshiftbot@redhat.com)
- Bug 955538: Don't fail on error in mysql control (ironcladlou@gmail.com)
- Fix bug 956018 - communicate database name to broker for v2 mysql
  (pmorie@gmail.com)
- WIP Cartridge Refactor - cleanup in cartridges (jhonce@redhat.com)
- Bug 956667 - Updated MySQL v2 cart to install with oo-admin-cartridge in
  %%post (jdetiber@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- implementing install and post-install (dmcphers@redhat.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Merge pull request #2161 from pmorie/dev/v2_mysql
  (dmcphers+openshiftbot@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Move v2 mysql setup invocation marker to gear data directory
  (pmorie@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.1.7-1
- Fix bug 927850 (pmorie@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.1.6-1
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1968 from pmorie/dev/v2_mysql (dmcphers@redhat.com)
- Add mysql v2 snapshot/restore tests (pmorie@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Add v2 mysql snapshot (pmorie@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)
- Correct mysqld setup and control status. (pmorie@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Dan McPherson <dmcphers@redhat.com> 0.0.5-1
- 

* Wed Mar 20 2013 Adam Miller <admiller@redhat.com> 0.0.4-1
- new package built with tito

* Wed Mar 20 2013 Paul Morie <pmorie@gmail.com> 0.0.3-1
- new package built with tito

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.2-1
- WIP: mysql v2 (pmorie@gmail.com)

* Wed Mar 13 2013 Paul Morie <pmorie@gmail.com> 0.0.1-1
- new package built with tito

