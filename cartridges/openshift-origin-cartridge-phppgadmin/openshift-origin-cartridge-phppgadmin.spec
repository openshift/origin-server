%global cartridgedir %{_libexecdir}/openshift/cartridges/phppgadmin

Summary:       phpPgAdmin support for OpenShift
Name:          openshift-origin-cartridge-phppgadmin
Version: 0.1.0
Release:       1%{?dist}
Group:         Applications/Internet
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      phpPgAdmin >= 5.0
Requires:      phpPgAdmin < 5.1
%if 0%{?fedora}%{?rhel} <= 6
Requires:      httpd < 2.4
%endif
%if 0%{?fedora} >= 19
Requires:      httpd > 2.3
Requires:      httpd < 2.5
%endif
BuildArch:     noarch

%description
Provides phpPgAdmin cartridge support.

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%if 0%{?fedora}%{?rhel} <= 6
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
rm %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%post
test -f %{_sysconfdir}/phpPgAdmin/config.inc.php && mv %{_sysconfdir}/phpPgAdmin/config.inc.php{,.orig.$(date +%F)} || rm -f %{_sysconfdir}/phpPgAdmin/config.inc.php
ln -sf %{cartridgedir}/versions/5.0/phpPgAdmin/config.inc.php %{_sysconfdir}/phpPgAdmin/config.inc.php

%posttrans
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
