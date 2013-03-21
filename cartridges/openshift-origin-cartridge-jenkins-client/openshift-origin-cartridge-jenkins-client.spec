%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/jenkins-client

Summary:       Embedded jenkins client support for OpenShift 
Name:          openshift-origin-cartridge-jenkins-client
Version: 1.5.4
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           https://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      mysql-devel
Requires:      wget
%if 0%{?fedora}%{?rhel} <= 6
Requires:      java-1.6.0-openjdk
%else
Requires:      java-1.7.0-openjdk
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-json
BuildArch:     noarch

%description
Provides plugin jenkins client support


%prep
%setup -q


%build


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
cp -r * %{buildroot}%{cartridgedir}/
#mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2
#ln -s %{cartridgedir}/versions/1.4/configuration %{buildroot}/%{_sysconfdir}/openshift/cartridges/v2/%{name}-1.4

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%dir %{cartridgedir}
%dir %{cartridgedir}/env
%dir %{cartridgedir}/metadata
%dir %{cartridgedir}/versions
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}
#%{_sysconfdir}/openshift/cartridges/v2/%{name}-1.4
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE



%changelog
* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.5.4-1
- new package built with tito

* Mon Mar 18 2013 Dan McPherson <dmcphers@redhat.com> 1.5.3-1
- new package built with tito


