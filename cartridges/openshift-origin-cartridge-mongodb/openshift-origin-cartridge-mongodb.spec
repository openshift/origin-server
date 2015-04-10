%if 0%{?rhel} <= 6
    %global scl mongodb24
    %global scl_prefix mongodb24-
    %global scl_context /usr/bin/scl enable %{scl}
%else
    %global scl_context eval
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/mongodb

Summary:       Embedded mongodb support for OpenShift
Name:          openshift-origin-cartridge-mongodb
Version: 1.26.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}mongodb-server
Requires:      %{?scl:%scl_prefix}mongodb-devel
Requires:      %{?scl:%scl_prefix}libmongodb
Requires:      %{?scl:%scl_prefix}mongodb
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
%{?scl_context} "%{cartridgedir}/bin/mkjournal %{cartridgedir}/usr/journal-cache/journal.tar.gz"


%preun
if [ $1 -eq 0 ]; then
  %__rm -f %{cartridgedir}/usr/journal-cache/journal.tar.gz
fi


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/lib/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/conf
%{cartridgedir}/metadata
%{cartridgedir}/env
%dir %{cartridgedir}/usr/journal-cache/
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Wed Apr 08 2015 Wesley Hearn <whearn@redhat.com> 1.25.3-1
- Bump cartridge versions for 2.0.60 (bparees@redhat.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.25.2-1
- Card devexp_483 - Obsoleting 10gen cartridge (maszulik@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Wed Dec 03 2014 Adam Miller <admiller@redhat.com> 1.24.3-1
- Cart version bump for Sprint 54 (vvitek@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Merge pull request #5949 from VojtechVitek/upgrade_scrips
  (dmcphers+openshiftbot@redhat.com)
- Clean up & unify upgrade scripts (vvitek@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)
- Version bump for the sprint 52 (mfojtik@redhat.com)

* Mon Oct 13 2014 Adam Miller <admiller@redhat.com> 1.23.3-1
- Bug 1151784 - Add user authentication to wait_for_mongod_startup
  (mfojtik@redhat.com)

* Fri Sep 19 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Bump mongodb cartridge version (mfojtik@redhat.com)
- Bug 1144114 - Add compatible upgrade for mongodb to fix missing PATH
  (mfojtik@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Wed Aug 20 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Bump cartridge versions for Sprint 49 (maszulik@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- mongodb cart: clean up `mongodb_context`, `rhcsh` (jolamb@redhat.com)
- mongodb cart: Support non-SCL systems (jolamb@redhat.com)
- mongodb cart: address bugs with scaled carts (jolamb@redhat.com)
- <mongodb cart> adapt to use SCL-provided mongodb (jolamb@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com>
- mongodb cart: clean up `mongodb_context`, `rhcsh` (jolamb@redhat.com)
- mongodb cart: Support non-SCL systems (jolamb@redhat.com)
- mongodb cart: address bugs with scaled carts (jolamb@redhat.com)
- <mongodb cart> adapt to use SCL-provided mongodb (jolamb@redhat.com)

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
