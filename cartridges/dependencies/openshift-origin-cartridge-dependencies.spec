Summary:       User dependencies for OpenShift Cartridges
Name:          openshift-origin-cartridge-dependencies
Version:       1.19.2
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
# General
#===================
# General Recommended
%package recommended
Summary:   Recommended user dependencies for all OpenShift Cartridges
BuildArch: noarch
Requires:  freetype-devel
Requires:  gd-devel 
Requires:  libcurl
Requires:  libcurl-devel
Requires:  libjpeg
Requires:  libjpeg-devel
Requires:  redhat-lsb-core
Requires:  symlinks

%description recommended
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended

# General Optional
%package optional
Summary:   Optional user dependencies for all OpenShift Cartridges
BuildArch: noarch
Requires:  atlas-devel
Requires:  expat-devel
Requires:  lapack-devel
Requires:  libffi-devel
Requires:  rpm-build
Requires:  ta-lib-devel

%description optional
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional

#===================
# JBoss
#===================
# JBoss Recommended
%package recommended-jboss
Summary:   Recommended user dependencies for JBoss OpenShift Cartridges
BuildArch: noarch

%description recommended-jboss
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-jboss

# JBoss Optional
%package optional-jboss
Summary:   Optional user dependencies for JBoss OpenShift Cartridges
BuildArch: noarch

%description optional-jboss
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-jboss

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
Requires:  perl-DBD-MySQL
Requires:  perl-DBD-SQLite
Requires:  perl-MongoDB

%description recommended-perl
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-perl

# Perl Optional
%package optional-perl
Summary:   Optional user dependencies for Perl OpenShift Cartridges
BuildArch: noarch
Requires:  ImageMagick-perl
Requires:  perl-CPAN
Requires:  perl-CPANPLUS

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
Requires:  MySQL-python
Requires:  pymongo
Requires:  pymongo-gridfs
Requires:  python-psycopg2
%if 0%{?fedora}%{?rhel} <= 6
Requires:  python27-MySQL-python
Requires:  python27-python-psycopg2
Requires:  python33-python-pymongo
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
Requires:  gcc-gfortran
Requires:  numpy
Requires:  numpy-f2py
Requires:  python-virtualenv
Requires:  python-magic
%if 0%{?fedora}%{?rhel} <= 6
Requires:  python27-python-pip-virtualenv
Requires:  python27-numpy
Requires:  python33-python-virtualenv
Requires:  python33-numpy
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

%description optional-ruby
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files optional-ruby


%changelog
* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Adding source to spec file (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.1-1
- new package built with tito

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> - 1.19.0-1
- Initial package

