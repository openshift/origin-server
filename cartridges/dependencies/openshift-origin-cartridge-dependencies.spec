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

%changelog
* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Adding source to spec file (tdawson@redhat.com)

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.1-1
- new package built with tito

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> - 1.19.0-1
- Initial package

