%global cartridgedir %{_libexecdir}/openshift/cartridges/phpmyadmin
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/phpmyadmin

Summary:       phpMyAdmin support for OpenShift
Name:          openshift-origin-cartridge-phpmyadmin
Version: 1.18.1
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      phpMyAdmin < 5.0
Requires:      httpd
BuildArch:     noarch

Obsoletes: openshift-origin-cartridge-phpmyadmin-3.4

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
* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.17.5-1
- <perl,python,phpmyadmin carts> bug 1055095 (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.17.4-1
- <phpmyadmin cart> enable providing custom gear server confs
  (lmeyer@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.17.3-1
- Applied fix to other affected cartridges (hripps@redhat.com)