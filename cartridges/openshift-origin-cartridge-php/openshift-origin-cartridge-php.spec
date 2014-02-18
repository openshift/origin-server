%global cartridgedir %{_libexecdir}/openshift/cartridges/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/php
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/php

Name:          openshift-origin-cartridge-php
Version: 1.21.0
Release:       1%{?dist}
Summary:       Php cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
%if 0%{?fedora}%{?rhel} <= 6
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      php54
Requires:      php54-php
Requires:      php54-php-pear
%endif
%if 0%{?fedora} >= 19
Requires:      php >= 5.5
Requires:      php < 5.6
%endif
Requires:      php
Requires:      php-pear
Provides:      openshift-origin-cartridge-php-5.3 = 2.0.0
Obsoletes:     openshift-origin-cartridge-php-5.3 <= 1.99.9
BuildArch:     noarch


%description
PHP cartridge for openshift. (Cartridge Format V2)

%prep
%setup -q

%build

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/
%__mkdir -p %{buildroot}%{httpdconfdir}

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel6 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/usr/lib/php_context.rhel6 %{buildroot}%{cartridgedir}/usr/lib/php_context
%__mv %{buildroot}%{cartridgedir}/versions/5.4-scl %{buildroot}%{cartridgedir}/versions/5.4
%endif
%if 0%{?fedora} >= 18
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/usr/lib/php_context.fedora %{buildroot}%{cartridgedir}/usr/lib/php_context
%endif
%__rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.* || :
%__rm %{buildroot}%{cartridgedir}/usr/lib/php_context.* || :

%files
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}


%changelog
* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
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

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4502 from sosiouxme/custom-cart-confs
  (dmcphers+openshiftbot@redhat.com)
- <php cart> enable providing custom gear server confs (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- fix php-cli include_path; config cleanup (vvitek@redhat.com)
- fix php cart PEAR builds (vvitek@redhat.com)
- php control script cleanup (vvitek@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- Modify PHP stop() to skip httpd stop when the process is already dead
  (hripps@redhat.com)
