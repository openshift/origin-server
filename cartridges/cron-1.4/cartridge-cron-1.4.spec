%define cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/cron-1.4

Name: cartridge-cron-1.4
Version: 0.5.5
Release: 1%{?dist}
Summary: Embedded cron support for express

Group: Network/Daemons
License: ASL 2.0
URL: https://engineering.redhat.com/trac/Libra
Source0: %{name}-%{version}.tar.gz
BuildRoot:    %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch: noarch

Obsoletes: rhc-cartridge-cron-1.4

Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: cronie
Requires: crontabs


%description
Provides rhc cron cartridge support

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
mkdir -p %{buildroot}/%{_sysconfdir}/cron.d
mkdir -p %{buildroot}/%{_sysconfdir}/cron.minutely
mkdir -p %{buildroot}/%{_sysconfdir}/cron.hourly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.daily
mkdir -p %{buildroot}/%{_sysconfdir}/cron.weekly
mkdir -p %{buildroot}/%{_sysconfdir}/cron.monthly
cp jobs/1minutely %{buildroot}/%{_sysconfdir}/cron.d
cp -r info %{buildroot}%{cartridgedir}/
cp -r jobs %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir}/jobs/stickshift-cron-minutely %{buildroot}/%{_sysconfdir}/cron.minutely/
ln -s %{cartridgedir}/jobs/stickshift-cron-hourly %{buildroot}/%{_sysconfdir}/cron.hourly/
ln -s %{cartridgedir}/jobs/stickshift-cron-daily %{buildroot}/%{_sysconfdir}/cron.daily/
ln -s %{cartridgedir}/jobs/stickshift-cron-weekly %{buildroot}/%{_sysconfdir}/cron.weekly/
ln -s %{cartridgedir}/jobs/stickshift-cron-monthly %{buildroot}/%{_sysconfdir}/cron.monthly/

%post
service crond restart || :


%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/jobs/
%attr(0644,-,-) %{_sysconfdir}/cron.d/1minutely
%attr(0755,-,-) %{_sysconfdir}/cron.minutely/stickshift-cron-minutely
%attr(0755,-,-) %{_sysconfdir}/cron.hourly/stickshift-cron-hourly
%attr(0755,-,-) %{_sysconfdir}/cron.daily/stickshift-cron-daily
%attr(0755,-,-) %{_sysconfdir}/cron.weekly/stickshift-cron-weekly
%attr(0755,-,-) %{_sysconfdir}/cron.monthly/stickshift-cron-monthly
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.5.5-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.5.4-1
- new package built with tito
