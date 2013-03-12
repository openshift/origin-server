%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/perl
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/perl

Name: openshift-origin-cartridge-perl
Version: 0.1.1
Release: 1%{?dist}
Summary: Perl cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      mod_perl
Requires:      mod_bw
Requires:      perl-DBD-SQLite
Requires:      perl-DBD-MySQL
Requires:      perl-MongoDB
Requires:      ImageMagick-perl
Requires:      perl-App-cpanminus
Requires:      perl-CPAN
Requires:      perl-CPANPLUS
Requires:      rpm-build
Requires:      expat-devel
Requires:      perl-IO-Socket-SSL
Requires:      gdbm-devel
Requires:      httpd < 2.4
BuildRequires: git
BuildArch:     noarch
Obsoletes:     cartridge-perl-5.10

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Perl cartridge for openshift.


%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -r * %{buildroot}%{cartridgedir}/


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
%attr(0755,-,-) %{frameworkdir}
%{cartridgedir}/metadata/manifest.yml
%doc %{cartridgedir}/README.md


%changelog
* Fri Mar 08 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.1-1
- new package built with tito

* Wed Feb 20 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.0-1
- Initial SPEC created
