%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/cron
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/cron

Name: openshift-origin-cartridge-cron
Version: 1.4.0
Release: 1%{?dist}
Summary: Embedded cron support for OpenShift
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      cronie
Requires:      crontabs

BuildArch:     noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Cron cartridge for openshift.


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
mkdir -p %{buildroot}/%{_sysconfdir}/cron.d
mkdir -p %{buildroot}/%{_sysconfdir}/cron.minutely
mkdir -p %{buildroot}/%{_sysconfdir}/cron.hourly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.daily
mkdir -p %{buildroot}/%{_sysconfdir}/cron.weekly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.monthly
cp -p versions/1.4/configuration/jobs/1minutely %{buildroot}/%{_sysconfdir}/cron.d
cp -r * %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/conf/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/versions/1.4/configuration/jobs/openshift-origin-cron-minutely %{buildroot}/%{_sysconfdir}/cron.minutely/
ln -s %{cartridgedir}/versions/1.4/configuration/jobs/openshift-origin-cron-hourly %{buildroot}/%{_sysconfdir}/cron.hourly/
ln -s %{cartridgedir}/versions/1.4/configuration/jobs/openshift-origin-cron-daily %{buildroot}/%{_sysconfdir}/cron.daily/
ln -s %{cartridgedir}/versions/1.4/configuration/jobs/openshift-origin-cron-weekly %{buildroot}/%{_sysconfdir}/cron.weekly/
ln -s %{cartridgedir}/versions/1.4/configuration/jobs/openshift-origin-cron-monthly %{buildroot}/%{_sysconfdir}/cron.monthly/

%post
%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
  systemctl restart  crond.service || :
%else
  service crond restart || :
%endif

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/bin
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/versions/1.4/configuration/jobs/
%attr(0755,-,-) %{frameworkdir}
%dir %{_sysconfdir}/cron.minutely
%config(noreplace) %attr(0644,-,-) %{_sysconfdir}/cron.d/1minutely
%attr(0755,-,-) %{_sysconfdir}/cron.minutely/openshift-origin-cron-minutely
%attr(0755,-,-) %{_sysconfdir}/cron.hourly/openshift-origin-cron-hourly
%attr(0755,-,-) %{_sysconfdir}/cron.daily/openshift-origin-cron-daily
%attr(0755,-,-) %{_sysconfdir}/cron.weekly/openshift-origin-cron-weekly
%attr(0755,-,-) %{_sysconfdir}/cron.monthly/openshift-origin-cron-monthly
%{_sysconfdir}/openshift/cartridges/v2/%{name}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
