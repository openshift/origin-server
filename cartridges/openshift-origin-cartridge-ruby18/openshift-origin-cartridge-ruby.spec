%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/ruby18
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/ruby18

Name: openshift-origin-cartridge-ruby
Version: 0.1.18
Release: 1%{?dist}
Summary: Ruby cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      mod_bw
Requires:      sqlite-devel
Requires:      rubygems
Requires:      rubygem-rack >= 1.1.0
#Requires:      rubygem-rack < 1.2.0
Requires:      rubygem-passenger
Requires:      rubygem-passenger-native
Requires:      rubygem-passenger-native-libs
Requires:      mod_passenger
Requires:      rubygem-bundler
Requires:      rubygem-mongo
Requires:      rubygem-sqlite3
Requires:      rubygem-thread-dump
Requires:      ruby-sqlite3
Requires:      ruby-mysql
Requires:      rubygem-bson_ext
Requires:      mysql-devel
Requires:      ruby-devel
Requires:      libxml2
Requires:      libxml2-devel
Requires:      libxslt
Requires:      libxslt-devel
Requires:      gcc-c++
Requires:      js
# Deps for users
Requires:      ruby-RMagick
%if 0%{?rhel}
Requires:      ruby-nokogiri
%endif
%if 0%{?fedora}
Requires:      rubygem-nokogiri
%endif
BuildRequires: git
BuildArch:     noarch
Obsoletes:     cartridge-ruby-1.8
Obsoletes:     openshift-origin-cartridge-ruby-1.1


BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

%description
Ruby cartridge for openshift.


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
* Mon Feb 25 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.18-1
- Initial SPEC created
