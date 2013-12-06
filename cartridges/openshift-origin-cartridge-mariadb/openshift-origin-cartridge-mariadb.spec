%global cartridgedir %{_libexecdir}/openshift/cartridges/mariadb

Summary:       Provides embedded mariadb support
Name:          openshift-origin-cartridge-mariadb
Version:       1.15.1.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      mariadb-server
Requires:      mariadb-devel
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

%description
Provides mariadb cartridge support to OpenShift. (Cartridge Format V2)

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
%attr(0755,-,-) %{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Dec 06 2013 Krishna Raman <kraman@gmail.com> 1.15.1.1-1
- Bumping versions for OpenShift Origin Release 3 (kraman@gmail.com)
- Bump cartridge versions for 2.0.35 (pmorie@gmail.com)
- Bump cartridge versions (fotios@redhat.com)
- Fix mariadb tests. (mrunalp@gmail.com)
- MariaDB update based on MySQL cart changes (kraman@gmail.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)
- Bug 980515 - Remove extraneous Conflicts element (jhonce@redhat.com)

* Wed Dec 04 2013 Krishna Raman <kraman@gmail.com> 1.15.1.1-1
- Bump cartridge versions for 2.0.35 (pmorie@gmail.com)
- Bump cartridge versions (fotios@redhat.com)
- Fix mariadb tests. (mrunalp@gmail.com)
- MariaDB update based on MySQL cart changes (kraman@gmail.com)
- Origin UI 72 - Membership (ccoleman@redhat.com)
- Merge pull request #3707 from rajatchopra/master
  (dmcphers+openshiftbot@redhat.com)
- add mappings support to routing spi, and add protocols to cart manifests
  (rchopra@redhat.com)
- Bug 982434 - remove extraneous set_app_info usage (jhonce@redhat.com)
- Bug 980515 - Remove extraneous Conflicts element (jhonce@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)
- Cartridge version bumps for 2.0.33 (ironcladlou@gmail.com)
- Updated cartridges and scripts for phpmyadmin-4 (mfojtik@redhat.com)
- Cartridge - Sprint 2.0.32 cartridge version bumps (jhonce@redhat.com)
- <cartridges> Additional cart version and test fixes (jolamb@redhat.com)
- Bug 968280 - Ensure Stopping/Starting messages during git push Bug 983014 -
  Unnecessary messages from mongodb cartridge (jhonce@redhat.com)
- Cartridge - Clean up manifests (jhonce@redhat.com)
- Various cleanup (dmcphers@redhat.com)
- Pulled cartridge READMEs into Cartridge Guide (hripps@redhat.com)
- Bug 985514 - Update CartridgeRepository when mcollectived restarted
  (jhonce@redhat.com)
- Bug 976921: Move cart installation to %%posttrans (ironcladlou@gmail.com)
- remove v2 folder from cart install (dmcphers@redhat.com)

* Wed May 08 2013 Krishna Raman <kraman@gmail.com> 0.0.2-1
- new package built with tito


