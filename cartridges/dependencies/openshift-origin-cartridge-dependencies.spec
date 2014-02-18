%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

Summary:       User dependencies for OpenShift Cartridges
Name:          openshift-origin-cartridge-dependencies
Version: 1.21.0
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       %{name}-%{version}.tar.gz
BuildArch:     noarch

%description
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

#===================
# All Dependency Packages
#===================
# All Recommended Packages
%package recommended-all
Summary:   All recommended user dependency packages for OpenShift Cartridges
BuildArch: noarch
Requires:  %{name}-recommended-jbossas
Requires:  %{name}-recommended-jbosseap
Requires:  %{name}-recommended-jbossews
Requires:  %{name}-recommended-nodejs
Requires:  %{name}-recommended-perl
Requires:  %{name}-recommended-php
Requires:  %{name}-recommended-python
Requires:  %{name}-recommended-ruby

%description recommended-all
This package pulls in all the recommended OpenShift 
Cartridge dependency packages.

Those packages pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-all

# All Optional Packages
%package optional-all
Summary:   All optional user dependency packages for OpenShift Cartridges
BuildArch: noarch
Requires:  %{name}-optional-jbossas
Requires:  %{name}-optional-jbosseap
Requires:  %{name}-optional-jbossews
Requires:  %{name}-optional-nodejs
Requires:  %{name}-optional-perl
Requires:  %{name}-optional-php
Requires:  %{name}-optional-python
Requires:  %{name}-optional-ruby

%description optional-all
This package pulls in all the optional OpenShift 
Cartridge dependency packages.

Those packages pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-all

#===================
# JBossAS
#===================
# JBossAS Recommended
%package recommended-jbossas
Summary:   Recommended user dependencies for JBossAS OpenShift Cartridges
BuildArch: noarch

%description recommended-jbossas
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-jbossas

# JBossAS Optional
%package optional-jbossas
Summary:   Optional user dependencies for JBossAS OpenShift Cartridges
BuildArch: noarch

%description optional-jbossas
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-jbossas

#===================
# JBossEAP
#===================
# JBossEAP Recommended
%package recommended-jbosseap
Summary:   Recommended user dependencies for JBossEAP OpenShift Cartridges
BuildArch: noarch

%description recommended-jbosseap
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-jbosseap

# JBossEAP Optional
%package optional-jbosseap
Summary:   Optional user dependencies for JBossEAP OpenShift Cartridges
BuildArch: noarch
Requires:  jbossas-appclient
Requires:  jbossas-bundles
Requires:  jbossas-core
Requires:  jbossas-domain
Requires:  jbossas-hornetq-native
Requires:  jbossas-jbossweb-native
Requires:  jbossas-modules-eap
Requires:  jbossas-product-eap
Requires:  jbossas-standalone
Requires:  jbossas-welcome-content-eap
Requires:  jboss-eap6-modules
Requires:  jboss-eap6-index

%description optional-jbosseap
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-jbosseap

#===================
# JBossEWS
#===================
# JBossEWS Recommended
%package recommended-jbossews
Summary:   Recommended user dependencies for JBossEWS OpenShift Cartridges
BuildArch: noarch

%description recommended-jbossews
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-jbossews

# JBossEWS Optional
%package optional-jbossews
Summary:   Optional user dependencies for JBossEWS OpenShift Cartridges
BuildArch: noarch

%description optional-jbossews
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-jbossews

#===================
# Nodejs
#===================
# Nodejs Recommended
%package recommended-nodejs
Summary:   Recommended user dependencies for Nodejs OpenShift Cartridges
BuildArch: noarch

%description recommended-nodejs
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-nodejs

# Nodejs Optional
%package optional-nodejs
Summary:   Optional user dependencies for Nodejs OpenShift Cartridges
BuildArch: noarch

%description optional-nodejs
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-nodejs


#===================
# Perl
#===================
# Perl Recommended
%package recommended-perl
Summary:   Recommended user dependencies for Perl OpenShift Cartridges
BuildArch: noarch
Requires:  db4-devel
Requires:  perl-CPAN
Requires:  perl-CPANPLUS
Requires:  perl-DBD-SQLite
Requires:  perl-DBD-MySQL

%description recommended-perl
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-perl

# Perl Optional
%package optional-perl
Summary:   Optional user dependencies for Perl OpenShift Cartridges
BuildArch: noarch
Requires:  expat-devel
Requires:  gd-devel
Requires:  gdbm-devel
Requires:  ImageMagick-perl
Requires:  perl-MongoDB
Requires:  rpm-build

%description optional-perl
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-perl

#===================
# PHP
#===================
# PHP Recommended
%package recommended-php
Summary:   Recommended user dependencies for PHP OpenShift Cartridges
BuildArch: noarch
Requires:  php-mysql
Requires:  php-pecl-mongo
Requires:  php-pgsql
%if 0%{?fedora}%{?rhel} <= 6
Requires:  php54-php-mysqlnd
Requires:  php54-php-pecl-mongo
Requires:  php54-php-pgsql
%endif

%description recommended-php
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-php

# PHP Optional
%package optional-php
Summary:   Optional user dependencies for Ruby OpenShift Cartridges
BuildArch: noarch
Requires:  php-bcmath
Requires:  php-devel
Requires:  php-fpm
Requires:  php-gd
Requires:  php-imap
Requires:  php-intl
Requires:  php-mbstring
Requires:  php-mcrypt
Requires:  php-pdo
Requires:  php-pecl-apc
Requires:  php-pecl-imagick
Requires:  php-pecl-xdebug
Requires:  php-process
Requires:  php-soap
Requires:  php-xml
%if 0%{?fedora}%{?rhel} <= 6
Requires:  php54-php-bcmath
Requires:  php54-php-devel
Requires:  php54-php-fpm
Requires:  php54-php-gd
Requires:  php54-php-intl
Requires:  php54-php-ldap
Requires:  php54-php-mbstring
Requires:  php54-php-pdo
Requires:  php54-php-pecl-apc
Requires:  php54-php-pecl-imagick
Requires:  php54-php-process
Requires:  php54-php-soap
Requires:  php54-php-xml
%endif

%description optional-php
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-php

#===================
# Python
#===================
# Python Recommended
%package recommended-python
Summary:   Recommended user dependencies for Python OpenShift Cartridges
BuildArch: noarch
Requires:  libcurl
Requires:  libjpeg
Requires:  MySQL-python
Requires:  python-magic
Requires:  python-psycopg2
Requires:  redhat-lsb-core
Requires:  symlinks
%if 0%{?fedora}%{?rhel} <= 6
Requires:  python27-mod_wsgi
Requires:  python27-MySQL-python
Requires:  python27-python-psycopg2
Requires:  python33-mod_wsgi
Requires:  python33-python-psycopg2
%endif

%description recommended-python
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-python

# Python Optional
%package optional-python
Summary:   Optional user dependencies for Python OpenShift Cartridges
BuildArch: noarch
Requires:  atlas-devel
Requires:  freetype-devel
Requires:  gcc-gfortran
Requires:  lapack-devel
Requires:  libcurl-devel
Requires:  libffi-devel
Requires:  libjpeg-devel
Requires:  numpy
Requires:  numpy-f2py
Requires:  pymongo
Requires:  pymongo-gridfs
Requires:  python-virtualenv
Requires:  ta-lib-devel
%if 0%{?fedora}%{?rhel} <= 6
Requires:  python27-numpy
Requires:  python27-python-pip-virtualenv
Requires:  python33-numpy
Requires:  python33-python-virtualenv
Requires:  python33-python-pymongo
%endif

%description optional-python
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-python

#===================
# Ruby
#===================
# Ruby Recommended
%package recommended-ruby
Summary:   Recommended user dependencies for Ruby OpenShift Cartridges
BuildArch: noarch
Requires:  mysql-devel
Requires:  sqlite-devel
Requires:  %{?scl_prefix}ruby-devel
Requires:  %{?scl_prefix}ruby-irb
Requires:  %{?scl_prefix}ruby-mysql
Requires:  %{?scl_prefix}rubygem-sqlite3
%if 0%{?fedora}%{?rhel} <= 6
Requires:  ruby-devel
Requires:  ruby-mysql
Requires:  ruby-sqlite3
Requires:  rubygem-sqlite3
%endif

%description recommended-ruby
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-ruby

# Ruby Optional
%package optional-ruby
Summary:   Optional user dependencies for Ruby OpenShift Cartridges
BuildArch: noarch
Requires:  libicu-devel
Requires:  gcc-c++
Requires:  gmp-devel
Requires:  ImageMagick-devel
Requires:  libev-devel
Requires:  libicu-devel
Requires:  libxml2-devel
Requires:  libxslt-devel
Requires:  ruby-RMagick
%if 0%{?fedora}%{?rhel} <= 6
Requires:  js
Requires:  ruby-nokogiri
Requires:  rubygem-bson_ext
Requires:  rubygem-rack >= 1.1.0
%else
Requires:  rubygem-nokogiri
%endif
Requires:  %{?scl_prefix}js-devel
Requires:  %{?scl_prefix}libyaml-devel
Requires:  %{?scl_prefix}ruby-tcltk
Requires:  %{?scl_prefix}rubygem-actionmailer
Requires:  %{?scl_prefix}rubygem-actionpack
Requires:  %{?scl_prefix}rubygem-activemodel
Requires:  %{?scl_prefix}rubygem-activerecord
Requires:  %{?scl_prefix}rubygem-activeresource
Requires:  %{?scl_prefix}rubygem-activesupport
Requires:  %{?scl_prefix}rubygem-arel
Requires:  %{?scl_prefix}rubygem-bacon
Requires:  %{?scl_prefix}rubygem-bcrypt-ruby
Requires:  %{?scl_prefix}rubygem-bigdecimal
Requires:  %{?scl_prefix}rubygem-bson
Requires:  %{?scl_prefix}rubygem-bson_ext
Requires:  %{?scl_prefix}rubygem-builder
Requires:  %{?scl_prefix}rubygem-bundler
Requires:  %{?scl_prefix}rubygem-coffee-rails
Requires:  %{?scl_prefix}rubygem-coffee-script
Requires:  %{?scl_prefix}rubygem-daemon_controller
Requires:  %{?scl_prefix}rubygem-diff-lcs
Requires:  %{?scl_prefix}rubygem-erubis
Requires:  %{?scl_prefix}rubygem-execjs
Requires:  %{?scl_prefix}rubygem-fakeweb
Requires:  %{?scl_prefix}rubygem-fssm
Requires:  %{?scl_prefix}rubygem-hike
Requires:  %{?scl_prefix}rubygem-http_connection
Requires:  %{?scl_prefix}rubygem-i18n
Requires:  %{?scl_prefix}rubygem-introspection
Requires:  %{?scl_prefix}rubygem-io-console
Requires:  %{?scl_prefix}rubygem-journey
Requires:  %{?scl_prefix}rubygem-jquery-rails
Requires:  %{?scl_prefix}rubygem-json
Requires:  %{?scl_prefix}rubygem-json_pure
Requires:  %{?scl_prefix}rubygem-mail
Requires:  %{?scl_prefix}rubygem-metaclass
Requires:  %{?scl_prefix}rubygem-mime-types
Requires:  %{?scl_prefix}rubygem-minitest
Requires:  %{?scl_prefix}rubygem-mocha
Requires:  %{?scl_prefix}rubygem-mongo
Requires:  %{?scl_prefix}rubygem-multi_json
Requires:  %{?scl_prefix}rubygem-open4
Requires:  %{?scl_prefix}rubygem-pg
Requires:  %{?scl_prefix}rubygem-polyglot
Requires:  %{?scl_prefix}rubygem-rack
Requires:  %{?scl_prefix}rubygem-rack-cache
Requires:  %{?scl_prefix}rubygem-rack-ssl
Requires:  %{?scl_prefix}rubygem-rack-test
Requires:  %{?scl_prefix}rubygem-rails
Requires:  %{?scl_prefix}rubygem-railties
Requires:  %{?scl_prefix}rubygem-rake
Requires:  %{?scl_prefix}rubygem-rdoc
Requires:  %{?scl_prefix}rubygem-rspec
Requires:  %{?scl_prefix}rubygem-ruby2ruby
Requires:  %{?scl_prefix}rubygem-ruby_parser
Requires:  %{?scl_prefix}rubygem-sass
Requires:  %{?scl_prefix}rubygem-sass-rails
Requires:  %{?scl_prefix}rubygem-sexp_processor
Requires:  %{?scl_prefix}rubygem-sinatra
Requires:  %{?scl_prefix}rubygem-sprockets
Requires:  %{?scl_prefix}rubygem-test_declarative
Requires:  %{?scl_prefix}rubygem-thor
Requires:  %{?scl_prefix}rubygem-tilt
Requires:  %{?scl_prefix}rubygem-treetop
Requires:  %{?scl_prefix}rubygem-tzinfo
Requires:  %{?scl_prefix}rubygem-uglifier
Requires:  %{?scl_prefix}rubygem-xml-simple
Requires:  %{?scl_prefix}rubygem-ZenTest

%description optional-ruby
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-ruby

%changelog
* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- PHP 5.4 - add mongo and imagick dependencies (vvitek@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Fix typo (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- add libicu-devel to optional-ruby (tdawson@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- adding dependencies for jbossaes, perl, and python (tdawson@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Adding recommended-all and optional-all packages (tdawson@redhat.com)
- Add dependency packages for all supported languages. (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Adding source to spec file (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.1-1
- new package built with tito

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> - 1.19.0-1
- Initial package

