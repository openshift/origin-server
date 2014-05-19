%global cartridgedir %{_libexecdir}/openshift/cartridges/mongodb

Summary:       Embedded mongodb support for OpenShift
Name:          openshift-origin-cartridge-mongodb
Version: 1.21.1
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
Provides:      openshift-origin-cartridge-mongodb-2.2 = 2.0.0
Obsoletes:     openshift-origin-cartridge-mongodb-2.2 <= 1.99.9
BuildArch:     noarch

%description
Provides mongodb cartridge support to OpenShift

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%__mkdir -p %{buildroot}%{cartridgedir}/usr/journal-cache


%post
%{cartridgedir}/bin/mkjournal %{cartridgedir}/usr/journal-cache/journal.tar.gz


%preun
if [ $1 -eq 0 ]; then
  %__rm -f %{cartridgedir}/usr/journal-cache/journal.tar.gz
fi


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/conf
%{cartridgedir}/metadata
%{cartridgedir}/env
%dir %{cartridgedir}/usr/journal-cache/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Tue Apr 29 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Add journal cache dir to %%files (ironcladlou@gmail.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.20.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.19.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Revert "Revert "Card origin_cartridge_133 - Maintain application state across
  snapshot/restore"" (bparees@redhat.com)
- Revert "Updated cartridges to stop after post_restore" (bparees@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.18.5-1
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Bug 1079132 - Prevent users installing mongodb to apps that starts with
  number (mfojtik@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Bug 1077052 - Make sure mongodb preserve the state after snapshot
  (mfojtik@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.18.2-1
- Remove unused teardowns (dmcphers@redhat.com)
- Updated cartridges to stop after post_restore (mfojtik@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.17.3-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Cleaning specs (dmcphers@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)

* Thu Nov 07 2013 Adam Miller <admiller@redhat.com> 1.17.1-1
- bump_minor_versions for sprint 36 (admiller@redhat.com)
