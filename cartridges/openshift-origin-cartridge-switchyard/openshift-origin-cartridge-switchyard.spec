%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/switchyard

Summary:       Provides embedded switchyard support
Name:          openshift-origin-cartridge-switchyard
Version: 0.3.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      switchyard-as7-modules
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-switchyard-0.6

%description
Provides switchyard cartridge support to OpenShift


%prep
%setup -q


%build
%__rm %{name}.spec


%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%post

alternatives --remove switchyard-0 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0 switchyard-0 /usr/share/switchyard 102
alternatives --set switchyard-0 /usr/share/switchyard

alternatives --remove switchyard-0.6 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0.6 switchyard-0 /usr/share/switchyard 102
alternatives --set switchyard-0.6 /usr/share/switchyard

%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Mon Jun 17 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Merge pull request #2864 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 974479 (bdecoste@gmail.com)
- First pass at removing v1 cartridges (dmcphers@redhat.com)
- Bug 974479 (bdecoste@gmail.com)
- Use -z with quotes (dmcphers@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- Fix bug 965490 (pmorie@gmail.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Bug 967118 - Remove redundant entries from managed_files.yml
  (jhonce@redhat.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Bug 962662 (dmcphers@redhat.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.2.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- move SY envs to erbs (bdecoste@gmail.com)
- move SY envs to erbs (bdecoste@gmail.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- fix module path (bdecoste@gmail.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.1.7-1
- Bug 960378 (bdecoste@gmail.com)

* Tue May 07 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- Bug 960378 960458 (bdecoste@gmail.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Special file processing (fotios@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Merge pull request #2304 from bdecoste/master
  (dmcphers+openshiftbot@redhat.com)
- update switchyard (bdecoste@gmail.com)

* Tue Apr 30 2013 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- 

* Tue Apr 30 2013 Dan McPherson <dmcphers@redhat.com> 0.1.2-1
- new package built with tito

* Mon Apr 29 2013 Unknown name <bdecoste@gmail.com> 0.1.1-1
- new package built with tito

