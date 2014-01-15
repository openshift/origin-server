Summary:       User dependencies for OpenShift Cartridges
Name:          openshift-origin-cartridge-dependencies
Version:       1.19.1
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
BuildArch:     noarch

%description
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

# General Recommended
%package recommended
Summary:   Recommended user dependencies for all OpenShift Cartridges
BuildArch: noarch
Requires:  gd-devel 

%description recommended
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended

# General Optional
%package optional
Summary:   Optional user dependencies for all OpenShift Cartridges
BuildArch: noarch
Requires:  expat-devel
Requires:  rpm-build

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

%changelog
* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> 1.19.1-1
- new package built with tito

* Wed Jan 15 2014 Troy Dawson <tdawson@redhat.com> - 1.19.0-1
- Initial package

