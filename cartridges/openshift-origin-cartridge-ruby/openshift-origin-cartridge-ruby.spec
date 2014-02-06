%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/ruby
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/ruby

Name:          openshift-origin-cartridge-ruby
Version: 1.20.1
Release:       1%{?dist}
Summary:       Ruby cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      facter
Requires:      gcc-c++
Requires:      gmp-devel
Requires:      libev
Requires:      libev-devel
Requires:      libxml2
Requires:      libxml2-devel
Requires:      libxslt
Requires:      libxslt-devel
Requires:      mysql-devel
Requires:      openshift-origin-node-util
Requires:      rubygem(openshift-origin-node)
Requires:      sqlite-devel

# For the ruby 1.8 cartridge
%if 0%{?rhel}
Requires:      js
Requires:      mod_passenger
Requires:      ruby-devel
Requires:      rubygem-bson_ext
Requires:      rubygem-bundler
Requires:      rubygem(openshift-origin-node)
Requires:      rubygem-passenger
Requires:      rubygem-passenger-native
Requires:      rubygem-passenger-native-libs
Requires:      rubygem-rack >= 1.1.0
Requires:      rubygems
Requires:      rubygem-sqlite3
Requires:      rubygem-thread-dump
Requires:      ruby-mysql
Requires:      ruby-sqlite3
Requires:      %{?scl:%scl_prefix}rubygem-fastthread
Requires:      %{?scl:%scl_prefix}runtime
%endif

Requires:      %{?scl:%scl_prefix}js
Requires:      %{?scl:%scl_prefix}js-devel
Requires:      %{?scl:%scl_prefix}libyaml
Requires:      %{?scl:%scl_prefix}libyaml-devel
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}ruby-devel
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
Requires:      %{?scl:%scl_prefix}rubygem-daemon_controller
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
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-devel
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}rubygem-pg
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
Requires:      %{?scl:%scl_prefix}rubygems
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
Requires:      %{?scl:%scl_prefix}rubygem-ZenTest
Requires:      %{?scl:%scl_prefix}ruby-irb
Requires:      %{?scl:%scl_prefix}ruby-libs
Requires:      %{?scl:%scl_prefix}ruby-mysql
Requires:      %{?scl:%scl_prefix}ruby-tcltk

# Deps for users
Requires:      ImageMagick-devel
Requires:      ruby-RMagick
%if 0%{?rhel}
Requires:      ruby-nokogiri
%endif
%if 0%{?fedora}
Requires:      rubygem-nokogiri
%endif

Obsoletes: openshift-origin-cartridge-ruby-1.8
Obsoletes: openshift-origin-cartridge-ruby-1.9-scl

BuildArch:     noarch

%description
Ruby cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{httpdconfdir}

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/versions/1.9-scl %{buildroot}%{cartridgedir}/versions/1.9
%__mv %{buildroot}%{cartridgedir}/lib/ruby_context.rhel %{buildroot}%{cartridgedir}/lib/ruby_context
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
%__rm -rf %{buildroot}%{cartridgedir}/versions/1.9-scl
%__rm -rf %{buildroot}%{cartridgedir}/versions/1.8
%__mv %{buildroot}%{cartridgedir}/lib/ruby_context.f19 %{buildroot}%{cartridgedir}/lib/ruby_context
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%__rm -f %{buildroot}%{cartridgedir}/lib/ruby_context.*
%__rm -f %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

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
* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Merge pull request #4572 from ncdc/bugs/1005123-ruby-jenkins-force-clean-
  build-broken (dmcphers+openshiftbot@redhat.com)
- Bug 1005123 (andy.goldstein@gmail.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Bump up cartridge versions (bparees@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Added groups_in_gemfile function to Ruby cart SDK (mfojtik@redhat.com)
- Be less verbose when not needed in Ruby cartridge (mfojtik@redhat.com)
- Unified notice messages and wrapped long lines. (mfojtik@redhat.com)
- Skip bundle install if Gemfile/Gemfile.lock is not modified
  (mfojtik@redhat.com)
- Fixed wrong return value from gemfile_is_modified() (mfojtik@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4502 from sosiouxme/custom-cart-confs
  (dmcphers+openshiftbot@redhat.com)
- <ruby cart> enable providing custom gear server confs (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Bug 1053648 (dmcphers@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Bug 1052276 - Check if tmp/ directory exists before ruby restart
  (mfojtik@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4439 from jhadvig/disable_assets_compilation
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4440 from mfojtik/bugzilla/984867
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4426 from mfojtik/card_21
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_21 - Enable BUNDLE_WITHOUT env variable for Ruby
  (mfojtik@redhat.com)
- Bug 984867 - Hardcode port 80 for PassengerPreStart (mfojtik@redhat.com)
- disable_assets_compilation (jhadvig@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.3-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- Applied fix to other affected cartridges (hripps@redhat.com)