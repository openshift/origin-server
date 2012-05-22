%define cartdir %{_libexecdir}/stickshift/cartridges

Summary:   StickShift common cartridge components
Name:      stickshift-abstract
Version: 0.11.3
Release:   1%{?dist}
Group:     Network/Daemons
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0:   stickshift-abstract-%{version}.tar.gz

BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildArch: noarch
Requires: git

%description
This contains the common function used while building cartridges.

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartdir}
cp -rv abstract %{buildroot}%{cartdir}/
cp -rv abstract-httpd %{buildroot}%{cartdir}/
cp -rv LICENSE %{buildroot}%{cartdir}/abstract
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract
cp -rv LICENSE %{buildroot}%{cartdir}/abstract-httpd
cp -rv COPYRIGHT %{buildroot}%{cartdir}/abstract-httpd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract-httpd/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract-httpd/info/bin/
#%{_libexecdir}/stickshift/cartridges/abstract-httpd/info
%dir %attr(0755,root,root) %{_libexecdir}/stickshift/cartridges/abstract/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/hooks/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/bin/
%attr(0755,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/lib/
%attr(0750,-,-) %{_libexecdir}/stickshift/cartridges/abstract/info/connection-hooks/
%{_libexecdir}/stickshift/cartridges/abstract/info
%doc %{_libexecdir}/stickshift/cartridges/abstract/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract/LICENSE
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/COPYRIGHT
%doc %{_libexecdir}/stickshift/cartridges/abstract-httpd/LICENSE


%post

%changelog
* Tue May 22 2012 Adam Miller <admiller@redhat.com> 0.11.3-1
- Merge pull request #41 from mrunalp/master (smitram@gmail.com)
- missing status=I from several carts (dmcphers@redhat.com)
- Changes to make mongodb run in standalone gear. (mpatel@redhat.com)

* Thu May 17 2012 Adam Miller <admiller@redhat.com> 0.11.2-1
- Add update namespace support for scalable apps. (ramr@redhat.com)
- remove preconfigure and more work making tests faster (dmcphers@redhat.com)
- silence the overlaping alias issues (mmcgrath@redhat.com)

* Thu May 10 2012 Adam Miller <admiller@redhat.com> 0.11.1-1
- bumping spec versions (admiller@redhat.com)

* Tue May 08 2012 Adam Miller <admiller@redhat.com> 0.10.5-1
- Fixing bugs related to user hooks. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.4-1
- Add support for pre/post start/stop hooks to both web application service and
  embedded cartridges.   Include the cartridge name in the calling hook to
  avoid conflicts when typeless gears are implemented. (rmillner@redhat.com)

* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.10.3-1
- code cleanup at the bash level (mmcgrath@redhat.com)
- general style cleanup (mmcgrath@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.2-1
- 

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.10.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.9.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.9.5-1
- new package built with tito
