%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/php
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/php

Name: openshift-origin-cartridge-php
Version: 0.2.1
Release: 1%{?dist}
Summary: Php cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
%if 0%{?fedora}%{?rhel} <= 6
Requires:      php >= 5.3.2
Requires:      php < 5.4
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 18
Requires:      php >= 5.4
Requires:      php < 5.5
Requires:      httpd < 2.5
%endif
Requires:      php
Requires:      mod_bw
Requires:      rubygem-builder
Requires:      php-devel
Requires:      php-pdo
Requires:      php-gd
Requires:      php-xml
Requires:      php-mysql
Requires:      php-pecl-mongo
Requires:      php-pgsql
Requires:      php-mbstring
Requires:      php-pear
Requires:      php-imap
Requires:      php-pecl-apc
Requires:      php-mcrypt
Requires:      php-soap
Requires:      php-bcmath
Requires:      php-process
Requires:      php-pecl-imagick
Requires:      php-pecl-xdebug
Requires:      openshift-origin-node-util

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
PHP cartridge for openshift.


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
cp -r * %{buildroot}%{cartridgedir}/
%if 0%{?fedora}%{?rhel} <= 6
mv %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-2.2/* %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/
rm -rf %{buildroot}%{cartridgedir}/versions/5.4
sed -i 's/PHPVERSION/5.3/g' %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} >= 18
mv %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-2.4/* %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf/
rm -rf %{buildroot}%{cartridgedir}/versions/5.3
sed -i 's/PHPVERSION/5.4/g' %{buildroot}%{cartridgedir}/metadata/manifest.yml
sed -i 's/#DefaultRuntimeDir/DefaultRuntimeDir/g' %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf.d/openshift.conf.erb
%endif
rm -rf %{buildroot}%{cartridgedir}/versions/shared/configuration/etc/conf-httpd-*

%clean
rm -rf %{buildroot}

%post
/sbin/oo-admin-cartridge --action install --offline --source /usr/libexec/openshift/cartridges/v2/php

%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/hooks
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Wed Mar 27 2013 Adam Miller <admiller@redhat.com> 0.1.7-1
- Merge pull request #1821 from jwhonce/wip/threaddump
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Roll out old threaddump support (jhonce@redhat.com)
- Merge pull request #1817 from jwhonce/wip/threaddump (dmcphers@redhat.com)
- Merge pull request #1818 from mrunalp/dev/haproxy_wip (dmcphers@redhat.com)
- WIP Cartridge Refactor - Add PHP support for threaddump (jhonce@redhat.com)
- Merge pull request #1801 from VojtechVitek/php5_standard
  (dmcphers+openshiftbot@redhat.com)
- HAProxy WIP. (mrunalp@gmail.com)
- Fix health_check.php to conform PHP 5 standards (vvitek@redhat.com)

* Tue Mar 26 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- getting jenkins working (dmcphers@redhat.com)
- Getting jenkins working (dmcphers@redhat.com)

* Fri Mar 22 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- adding openshift node util (dmcphers@redhat.com)
- implementing builder_cartridge based on cart categories (dmcphers@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Merge pull request #1741 from mrunalp/dev/php_build_wip
  (dmcphers+openshiftbot@redhat.com)
- adding jenkins teardown (dmcphers@redhat.com)
- PHP build wip. (mrunalp@gmail.com)
- Merge pull request #1718 from mrunalp/bugs/php_cleanup
  (dmcphers+openshiftbot@redhat.com)
- Cleanup setup script and remove unused file. (mrunalp@gmail.com)
- jenkins WIP (dmcphers@redhat.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- Merge pull request #1690 from danmcp/master (dmcphers@redhat.com)
- Getting jenkins building (dmcphers@redhat.com)
- Fix php cart to work with cart repo changes. (mrunalp@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Fix issue in copying over template. (mrunalp@gmail.com)
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- PHP cart manifest fixup and other cleanup. (mrunalp@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- Fixing tito tags on master

* Wed Mar 13 2013 Mrunal Patel <mrunalp@gmail.com> 0.1.1-1
- new package built with tito

* Wed Feb 13 2013 Mrunal Patel
- new package built with tito
