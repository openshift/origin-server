%global cartridgedir %{_libexecdir}/openshift/cartridges/switchyard

Summary:       Provides embedded switchyard support
Name:          openshift-origin-cartridge-switchyard
Version: 1.20.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      switchyard-as7-modules
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Provides:      openshift-origin-cartridge-switchyard-0.6 = 2.0.0
Obsoletes:     openshift-origin-cartridge-switchyard-0.6 <= 1.99.9
BuildArch:     noarch

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
alternatives --install /etc/alternatives/switchyard-0.6 switchyard-0.6 /usr/share/switchyard 100
alternatives --set switchyard-0.6 /usr/share/switchyard

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/metadata
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.18.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.17.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Both env OPENSHIFT_JBOSSEAP_MODULE_PATH and OPENSHIFT_JBOSSAS_MODULE_PATH
  exist in jbosseap/as (bparees@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.17.1-1
- bump spec to fix versioning between branches (admiller@redhat.com)

* Tue Mar 18 2014 Adam Miller <admiller@redhat.com> 1.16.3-1
- bump version number for build after tag fix

* Tue Mar 18 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- get version number in line with tag (admiller@redhat.com)
- Automatic commit of package [openshift-origin-cartridge-switchyard] release
  [1.16.2-1]. (admiller@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- Updating cartridge versions (jhadvig@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.16.1-1
- Bug 1066850 - Fixing urls (dmcphers@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.15.3-1
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.15.2-1
- Cleaning specs (dmcphers@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)
