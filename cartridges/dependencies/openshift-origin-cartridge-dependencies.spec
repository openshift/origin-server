Summary:       User dependencies for OpenShift Cartridges
Name:          openshift-origin-cartridge-dependencies
Version: 1.20.0
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
# All Dependancy Packages
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

%description recommended-php
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-php

# PHP Optional
%package optional-php
Summary:   Optional user dependencies for Ruby OpenShift Cartridges
BuildArch: noarch

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

%description optional-ruby
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-ruby

%changelog
* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- add libicu-devel to optional-ruby (tdawson@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- adding dependencies for jbossaes, perl, and python (tdawson@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Adding recommended-all and optional-all packages (tdawson@redhat.com)
- Add dependancy packages for all supported languages. (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Adding source to spec file (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.1-1
- new package built with tito

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> - 1.19.0-1
- Initial package

