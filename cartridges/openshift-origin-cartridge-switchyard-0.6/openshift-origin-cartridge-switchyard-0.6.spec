%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/embedded/switchyard-0.6
%global frameworkdir %{_libexecdir}/openshift/cartridges/switchyard-0.6

Summary:       Embedded SwitchYard modules for JBoss
Name:          openshift-origin-cartridge-switchyard-0.6
Version:       1.4.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           https://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      mysql-devel
Requires:      wget
Requires:      java-1.6.0-openjdk
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      switchyard-as7-modules
BuildArch:     noarch

%description
Provides embedded switchyard support for JBoss cartridges


%prep
%setup -q


%build


%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}

%post

alternatives --remove switchyard-0.6 /usr/share/switchyard
alternatives --install /etc/alternatives/switchyard-0.6 switchyard-0.6 /usr/share/switchyard 102
alternatives --set switchyard-0.6 /usr/share/switchyard

%files
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0750,-,-) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- remove BuildRoot: (tdawson@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1194 from Miciah/bug-887353-removing-a-cartridge-leaves-
  its-info-directory (dmcphers+openshiftbot@redhat.com)
- Bug 889940 part 1 (dmcphers@redhat.com)
- Manifest file fixes (kraman@gmail.com)
- Moving model refactor work - Updated cartridge manifest files - Simplified
  descriptor - Switched from mongo gem to use mongoid (kraman@gmail.com)
- Bug 887353: removing a cartridge leaves info/ dir (miciah.masters@gmail.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- BZ886431 (bdecoste@gmail.com)

* Tue Dec 11 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- added deconfigure xsl (bdecoste@gmail.com)
- removed ews2.0 and sy xslt (bdecoste@gmail.com)
- ews2 and bugs (bdecoste@gmail.com)
- BZ883948 (bdecoste@gmail.com)

* Thu Dec 6 2012 William DeCoste <wdecoste@redhat.com> 1.2.2-1
- configuration dir now contains files

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- BZ875675 (bdecoste@gmail.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- BZ875662 (bdecoste@gmail.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- added configuration dir (bdecoste@gmail.com)
- BZ875812 (bdecoste@gmail.com)

* Mon Nov 12 2012 William DeCoste <wdecoste@redhat.com> 1.1.3-1
- added configuration dir

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #855 from bdecoste/master (openshift+bot@redhat.com)
- US3064 - switchyard (bdecoste@gmail.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- new package built with tito

* Wed Nov 07 2012 Unknown name <bdecoste@gmail.com> 1.0.1-1
- new package built with tito

* Tue Nov 06 2012 William DeCoste <wdecoste@redhat.com> 
- initial
