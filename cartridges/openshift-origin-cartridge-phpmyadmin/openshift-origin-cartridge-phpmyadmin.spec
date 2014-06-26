%global cartridgedir %{_libexecdir}/openshift/cartridges/phpmyadmin
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/phpmyadmin

Summary:       phpMyAdmin support for OpenShift
Name:          openshift-origin-cartridge-phpmyadmin
Version: 1.23.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      phpMyAdmin < 5.0
Provides:      openshift-origin-cartridge-phpmyadmin-3.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-phpmyadmin-3.4 <= 1.99.9
BuildArch:     noarch

%description
Provides phpMyAdmin cartridge support. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{httpdconfdir}

%post
test -f %{_sysconfdir}/phpMyAdmin/config.inc.php && mv %{_sysconfdir}/phpMyAdmin/config.inc.php{,.orig.$(date +%F)} || rm -f %{_sysconfdir}/phpMyAdmin/config.inc.php
ln -sf %{cartridgedir}/versions/shared/phpMyAdmin/config.inc.php %{_sysconfdir}/phpMyAdmin/config.inc.php

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/versions
%{cartridgedir}/env
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}

%changelog
* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Revert "Bug 1112522: Getting rid of OPENSHIFT_PHPMYADMIN_LOG_DIR.erb in the
  gear env/ directory" (jhadvig@redhat.com)
- Bug 1112522: Getting rid of OPENSHIFT_PHPMYADMIN_LOG_DIR.erb in the gear env/
  directory (jhadvig@redhat.com)
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)
- Making apache server-status optional with a marker (jhadvig@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.21.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.20.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.20.2-1
- Merge pull request #5260 from ironcladlou/cart-log-vars
  (dmcphers+openshiftbot@redhat.com)
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)
- fix phpmyadmin PHP_INI_SCAN_DIR bug (vvitek@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Force httpd into its own pgroup (ironcladlou@gmail.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- Make restarts resilient to missing/corrupt pidfiles (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Ensure modified confs are replaced during upgrades (ironcladlou@gmail.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Removing f19 logic (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- Bug 1065264 - Better error handling on status (dmcphers@redhat.com)
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.18.5-1
- Merge pull request #4753 from
  smarterclayton/make_configure_order_define_requires
  (dmcphers+openshiftbot@redhat.com)
- Configure-Order should influence API requires (ccoleman@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Merge pull request #4729 from tdawson/2014-02/tdawson/fix-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4372 from maxamillion/admiller/no_defaulttype_apache24
  (dmcphers+openshiftbot@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)
- This directive throws a deprecation warning in apache 2.4
  (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4708 from smarterclayton/bug_1063109_trim_required_carts
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Bug 1063109 - Required carts should be handled higher in the model
  (ccoleman@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.17.5-1
- <perl,python,phpmyadmin carts> bug 1055095 (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.17.4-1
- <phpmyadmin cart> enable providing custom gear server confs
  (lmeyer@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.17.3-1
- Applied fix to other affected cartridges (hripps@redhat.com)
