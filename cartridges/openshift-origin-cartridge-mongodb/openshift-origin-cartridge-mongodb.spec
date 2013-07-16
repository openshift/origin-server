%global cartridgedir %{_libexecdir}/openshift/cartridges/mongodb

Summary:       Embedded mongodb support for OpenShift
Name:          openshift-origin-cartridge-mongodb
Version: 1.10.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mongodb-server
Requires:      mongodb-devel
Requires:      libmongodb
Requires:      mongodb
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-mongodb-2.2

%description
Provides mongodb cartridge support to OpenShift

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
* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.10.2-1
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.10.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 1.9.2-1
- First pass at removing v1 cartridges (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.9.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 1.8.6-1
- Bug 962657: Add client result for mongodb credentials during install
  (ironcladlou@gmail.com)

* Fri May 24 2013 Adam Miller <admiller@redhat.com> 1.8.5-1
- Bug 967017: Use underscores for v2 cart script names (ironcladlou@gmail.com)
- remove install build required for non buildable carts (dmcphers@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 1.8.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 1.8.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.8.2-1
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 1.7.5-1
- Special file processing (fotios@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 1.7.4-1
- Bug 958788 - port number missing from OPENSHIFT_MONGODB_DB_URL
  (jhonce@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #2296 from ironcladlou/bz/955538
  (dmcphers+openshiftbot@redhat.com)
- Bug 954209: Remove unnecessary root check (ironcladlou@gmail.com)
- Bug 955538: Fix error handling in mongodb stop routine
  (ironcladlou@gmail.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2176 from mscherer/fix/cartridges/mongo_useless_rm
  (dmcphers+openshiftbot@redhat.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Do not remove file that do not exist (misc@zarb.org)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- Bug 950883 (asari.ruby@gmail.com)
- Merge pull request #2126 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Sending the snapshot/restore messages stderr (calfonso@redhat.com)
- Merge pull request #2121 from ironcladlou/dev/v2carts/documentation
  (dmcphers+openshiftbot@redhat.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 mongodb cartridge Connection URL display fix (calfonso@redhat.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 1.6.11-1
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.6.10-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.6.9-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 1.6.8-1
- Bug 951507 (ffranz@redhat.com)
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Fixing snapshot/restore and status reporting (calfonso@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.6.7-1
- Merge pull request #1976 from calfonso/master (dmcphers@redhat.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Display the mongo password to the client when setting up the db
  (calfonso@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 1.6.6-1
- Merge pull request #1952 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Adding snapshot / restore to v2 mongodb cartridge (calfonso@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.6.5-1
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Tue Apr 02 2013 Dan McPherson <dmcphers@redhat.com> 1.6.4-1
- new package built with tito

* Tue Apr 02 2013 Chris Alfonso <calfonso@redhat.com> 1.6.3-1
- new package built with tito


