%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/haproxy

Name:          openshift-origin-cartridge-haproxy
Version: 0.4.1
Release:       1%{?dist}
Summary:       Provides HA Proxy
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      haproxy
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
BuildArch:     noarch

%description
HAProxy cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__rm -rf %{buildroot}
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%clean
%__rm -rf %{buildroot}

%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- Special file processing (fotios@redhat.com)

* Thu May 02 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- Add init option to remote deploy. (mrunalp@gmail.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Merge pull request #2275 from jwhonce/wip/cartridge_path
  (dmcphers+openshiftbot@redhat.com)
- Card online_runtime_266 - Renamed OPENSHIFT_<short name>_PATH to
  OPENSHIFT_<short name>_PATH_ELEMENT (jhonce@redhat.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2248 from mrunalp/bug/haproxy_fixes
  (dmcphers+openshiftbot@redhat.com)
- Move haproxy shared scripts into /usr/bin. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Card online_runtime_266 - Build PATH from
  CARTRIDGE_<CARTRIDGE_SHORT_NAME>_PATH (jhonce@redhat.com)
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Merge pull request #2194 from mrunalp/dev/haproxy_cleanup
  (dmcphers+openshiftbot@redhat.com)
- HAProxy cleanup. (mrunalp@gmail.com)
- implementing install and post-install (dmcphers@redhat.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-haproxy] release
  [0.2.10-1]. (tdawson@redhat.com)
- Fix bug 927850 (pmorie@gmail.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.10-1
- Fix bug 927850 (pmorie@gmail.com)

* Sun Apr 14 2013 Dan McPherson <dmcphers@redhat.com> 0.2.9-1
- 

* Sun Apr 14 2013 Dan McPherson <dmcphers@redhat.com> 0.2.8-1
- 

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- Merge pull request #2068 from jwhonce/wip/path
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Move PATH to /etc/openshift/env (jhonce@redhat.com)

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 0.2.6-1
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)
- Generate ssh key for web proxy cartridges (pmorie@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)
- Merge pull request #1974 from brenton/v2_post2 (dmcphers@redhat.com)
- Registering/installing the cartridges in the rpm %%post (bleanhar@redhat.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Fix haproxy v2 path construction (ironcladlou@gmail.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- HAProxy deploy wip. (mrunalp@gmail.com)
- Refactor v2 cartridge SDK location and accessibility (ironcladlou@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- new package built with tito

* Tue Mar 26 2013 Dan McPherson <dmcphers@redhat.com>
- new package built with tito

* Tue Mar 26 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

