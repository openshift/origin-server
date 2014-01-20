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

%description recommended-perl
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-perl

# Perl Optional
%package optional-perl
Summary:   Optional user dependencies for Perl OpenShift Cartridges
BuildArch: noarch

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

%description recommended-python
This package pulls in other packages that a user
might need when building common applications using
an OpenShift cartrige.

%files recommended-python

# Python Optional
%package optional-python
Summary:   Optional user dependencies for Python OpenShift Cartridges
BuildArch: noarch

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

