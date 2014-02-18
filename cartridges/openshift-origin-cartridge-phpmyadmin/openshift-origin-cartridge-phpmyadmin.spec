%global cartridgedir %{_libexecdir}/openshift/cartridges/phpmyadmin
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/phpmyadmin

Summary:       phpMyAdmin support for OpenShift
Name:          openshift-origin-cartridge-phpmyadmin
Version: 1.19.0
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
%if 0%{?fedora}%{?rhel} <= 6
rm -rf %{buildroot}%{cartridgedir}/versions/3.5
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
rm -rf %{buildroot}%{cartridgedir}/versions/3.4
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%post
test -f %{_sysconfdir}/phpMyAdmin/config.inc.php && mv %{_sysconfdir}/phpMyAdmin/config.inc.php{,.orig.$(date +%F)} || rm -f %{_sysconfdir}/phpMyAdmin/config.inc.php
ln -sf %{cartridgedir}/versions/shared/phpMyAdmin/config.inc.php %{_sysconfdir}/phpMyAdmin/config.inc.php

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}

%changelog
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
