%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/ruby
%global frameworkdir %{_libexecdir}/openshift/cartridges/v2/ruby

Name: openshift-origin-cartridge-ruby
Version: 0.1.1
Release: 1%{?dist}
Summary: Ruby cartridge
Group: Development/Languages
License: ASL 2.0
URL: https://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      sqlite-devel
Requires:      libev
Requires:      libev-devel
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}js
Requires:      %{?scl:%scl_prefix}js-devel
Requires:      %{?scl:%scl_prefix}libyaml
Requires:      %{?scl:%scl_prefix}libyaml-devel
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}ruby-devel
Requires:      %{?scl:%scl_prefix}ruby-irb
Requires:      %{?scl:%scl_prefix}ruby-libs
Requires:      %{?scl:%scl_prefix}ruby-tcltk
Requires:      %{?scl:%scl_prefix}rubygem-ZenTest
Requires:      %{?scl:%scl_prefix}rubygem-actionmailer
Requires:      %{?scl:%scl_prefix}rubygem-actionpack
Requires:      %{?scl:%scl_prefix}rubygem-activemodel
Requires:      %{?scl:%scl_prefix}rubygem-activerecord
Requires:      %{?scl:%scl_prefix}rubygem-activeresource
Requires:      %{?scl:%scl_prefix}rubygem-activesupport
Requires:      %{?scl:%scl_prefix}rubygem-arel
Requires:      %{?scl:%scl_prefix}rubygem-bacon
Requires:      %{?scl:%scl_prefix}rubygem-bcrypt-ruby
Requires:      %{?scl:%scl_prefix}rubygem-bigdecimal
Requires:      %{?scl:%scl_prefix}rubygem-bson
Requires:      %{?scl:%scl_prefix}rubygem-bson_ext
Requires:      %{?scl:%scl_prefix}rubygem-builder
Requires:      %{?scl:%scl_prefix}rubygem-bundler
Requires:      %{?scl:%scl_prefix}rubygem-coffee-rails
Requires:      %{?scl:%scl_prefix}rubygem-coffee-script
Requires:      %{?scl:%scl_prefix}rubygem-diff-lcs
Requires:      %{?scl:%scl_prefix}rubygem-erubis
Requires:      %{?scl:%scl_prefix}rubygem-execjs
Requires:      %{?scl:%scl_prefix}rubygem-fakeweb
Requires:      %{?scl:%scl_prefix}rubygem-fssm
Requires:      %{?scl:%scl_prefix}rubygem-hike
Requires:      %{?scl:%scl_prefix}rubygem-http_connection
Requires:      %{?scl:%scl_prefix}rubygem-i18n
Requires:      %{?scl:%scl_prefix}rubygem-introspection
Requires:      %{?scl:%scl_prefix}rubygem-io-console
Requires:      %{?scl:%scl_prefix}rubygem-journey
Requires:      %{?scl:%scl_prefix}rubygem-jquery-rails
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-json_pure
Requires:      %{?scl:%scl_prefix}rubygem-mail
Requires:      %{?scl:%scl_prefix}rubygem-metaclass
Requires:      %{?scl:%scl_prefix}rubygem-mime-types
Requires:      %{?scl:%scl_prefix}rubygem-minitest
Requires:      %{?scl:%scl_prefix}rubygem-mocha
Requires:      %{?scl:%scl_prefix}rubygem-mongo
Requires:      %{?scl:%scl_prefix}rubygem-multi_json
Requires:      %{?scl:%scl_prefix}rubygem-polyglot
Requires:      %{?scl:%scl_prefix}rubygem-rack
Requires:      %{?scl:%scl_prefix}rubygem-rack-cache
Requires:      %{?scl:%scl_prefix}rubygem-rack-ssl
Requires:      %{?scl:%scl_prefix}rubygem-rack-test
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-railties
Requires:      %{?scl:%scl_prefix}rubygem-rake
Requires:      %{?scl:%scl_prefix}rubygem-rdoc
Requires:      %{?scl:%scl_prefix}rubygem-rspec
Requires:      %{?scl:%scl_prefix}rubygem-ruby2ruby
Requires:      %{?scl:%scl_prefix}rubygem-ruby_parser
Requires:      %{?scl:%scl_prefix}rubygem-sass
Requires:      %{?scl:%scl_prefix}rubygem-sass-rails
Requires:      %{?scl:%scl_prefix}rubygem-sexp_processor
Requires:      %{?scl:%scl_prefix}rubygem-sinatra
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-sqlite3
Requires:      %{?scl:%scl_prefix}rubygem-test_declarative
Requires:      %{?scl:%scl_prefix}rubygem-thor
Requires:      %{?scl:%scl_prefix}rubygem-tilt
Requires:      %{?scl:%scl_prefix}rubygem-treetop
Requires:      %{?scl:%scl_prefix}rubygem-tzinfo
Requires:      %{?scl:%scl_prefix}rubygem-uglifier
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple
Requires:      %{?scl:%scl_prefix}runtime
Requires:      %{?scl:%scl_prefix}rubygem-daemon_controller
Requires:      %{?scl:%scl_prefix}rubygem-fastthread
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-devel
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}ruby-mysql
Requires:      %{?scl:%scl_prefix}rubygem-pg
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      mysql-devel
Requires:      libxml2
Requires:      libxml2-devel
Requires:      libxslt
Requires:      libxslt-devel
Requires:      gcc-c++
Requires:      js
# Deps for users
Requires:      ImageMagick-devel
Requires:      ruby-RMagick
BuildRequires: git
BuildArch:     noarch
Obsoletes:     cartridge-ruby-1.9


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
* Fri Mar 08 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.1-1
- new package built with tito

* Wed Feb 20 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.0-1
- Initial SPEC created
