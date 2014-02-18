%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-console
%global rubyabi 1.9.1

Summary:       OpenShift Origin Management Console
Name:          rubygem-%{gem_name}
Version: 1.21.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           https://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygem(coffee-rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(formtastic)
Requires:      %{?scl:%scl_prefix}rubygem(haml)
Requires:      %{?scl:%scl_prefix}rubygem(jquery-rails)
# Bz1017671
Requires:      %{?scl:%scl_prefix}rubygem(minitest)
Requires:      %{?scl:%scl_prefix}rubygem(net-http-persistent)
Requires:      %{?scl:%scl_prefix}rubygem(rails)
Requires:      %{?scl:%scl_prefix}rubygem(rdiscount)
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(sass-rails)
Requires:      %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)
Requires:      %{?scl:%scl_prefix}rubygem(uglifier)
Requires:      %{?scl:%scl_prefix}rubygem(syslog-logger)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif

BuildRequires: %{?scl:%scl_prefix}rubygem(coffee-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(compass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(formtastic)
BuildRequires: %{?scl:%scl_prefix}rubygem(haml)
BuildRequires: %{?scl:%scl_prefix}rubygem(jquery-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(minitest)
BuildRequires: %{?scl:%scl_prefix}rubygem(net-http-persistent)
BuildRequires: %{?scl:%scl_prefix}rubygem(rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(rdiscount)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-rails)
BuildRequires: %{?scl:%scl_prefix}rubygem(sass-twitter-bootstrap)
BuildRequires: %{?scl:%scl_prefix}rubygem(sprockets)
BuildRequires: %{?scl:%scl_prefix}rubygem(therubyracer)
BuildRequires: %{?scl:%scl_prefix}rubygem(uglifier)
BuildRequires: %{?scl:%scl_prefix}rubygem(syslog-logger)


BuildRequires: %{?scl:%scl_prefix}rubygems-devel
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
This contains the OpenShift Origin Management Console.

%package doc
Summary: OpenShift Origin Management Console docs.

%description doc
OpenShift Origin Management Console ri documentation 

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}

set -e
mkdir -p .%{gem_dir}

%if 0%{?fedora}%{?rhel} <= 6
rm -f Gemfile.lock

# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' Gemfile

bundle install --local

mkdir -p %{buildroot}%{_var}/log/openshift/console/
mkdir -m 770 %{buildroot}%{_var}/log/openshift/console/httpd/
touch %{buildroot}%{_var}/log/openshift/console/production.log
chmod 0666 %{buildroot}%{_var}/log/openshift/console/production.log

pushd test/rails_app/
CONSOLE_CONFIG_FILE=../../conf/console.conf.example \
  RAILS_ENV=production \
  RAILS_LOG_PATH=%{buildroot}%{_var}/log/openshift/console/production.log \
  RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
echo > %{buildroot}%{_var}/log/openshift/console/production.log
popd

find . -name .gitignore -delete
find . -name .gitkeep -delete

rm -rf %{buildroot}%{_var}/log/openshift/*

rm -f Gemfile.lock
%endif

# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

%files
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/LICENSE 
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/COPYRIGHT
%{gem_instdir}
%{gem_cache}
%{gem_spec}

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Thu Feb 13 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4760 from fabianofranz/master
  (dmcphers+openshiftbot@redhat.com)
- Fixes site_extended tests (contact@fabianofranz.com)
- Activate obsolete cartridges in devenv (ccoleman@redhat.com)
- Merge pull request #4674 from fabianofranz/dev/155
  (dmcphers+openshiftbot@redhat.com)
- [origin-ui-155] Improves error and debug messages on the REST API and web
  console (contact@fabianofranz.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4739 from fabianofranz/bugs/1063470
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063470 - handle different encodings in files provided by ssl cert
  issuers (contact@fabianofranz.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4718 from lnader/master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4708 from smarterclayton/bug_1063109_trim_required_carts
  (dmcphers+openshiftbot@redhat.com)
- Obsoleted zend-5.6 cartridge (lnader@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063109 - Required carts should be handled higher in the model
  (ccoleman@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Support changing categorizations (ccoleman@redhat.com)
- UI uses "requires" value from broker (ccoleman@redhat.com)
- Bug 1059858 - Expose requires via REST API (ccoleman@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4649 from ncdc/dev/rails-syslog
  (dmcphers+openshiftbot@redhat.com)
- Add/correct syslog-logger in Gemfiles (andy.goldstein@gmail.com)
- Merge pull request #4602 from jhadvig/mongo_update
  (dmcphers+openshiftbot@redhat.com)
- Add optional syslog support to Rails apps (andy.goldstein@gmail.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- MongoDB version update to 2.4 (jhadvig@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Merge pull request #4594 from smarterclayton/tolerate_custom_carts_in_broker
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Tolerate custom cartridges in the broker in the console (ccoleman@redhat.com)
- Add external cartridge support to model (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.16-1
- Adding back zend-5.6 until bug 1054654 is fixed (lnader@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.15-1
- Merge pull request #4570 from
  liggitt/bug_1055906_downloadable_cartridge_scheme (ccoleman@redhat.com)
- Fix bug 1055906: Add http:// to cartridge url if no scheme provided
  (jliggitt@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.14-1
- bump console Release to test build scripts for chainbuild case
  (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.13-1
- bump console Release to test build scripts for chainbuild case
  (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.12-1
- Merge pull request #4557 from liggitt/bug_1056441_member_error_color
  (dmcphers+openshiftbot@redhat.com)
- Fix bug 1056441: Member add message color (jliggitt@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Bug 1056349 (dmcphers@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Merge pull request #4520 from smarterclayton/update_custom_cart_error
  (dmcphers+openshiftbot@redhat.com)
- Test case for custom cart failure is checking a nonexistent message
  (ccoleman@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Fix bug 1054692: avoid currency symbol wrapping (jliggitt@redhat.com)
- Add an additional failing test for cart output (ccoleman@redhat.com)
- Hide small app type icon in origin Minor haml change Reverting back to use
  usage_rate_indicator Added mixin to adjust $ sign size to match related group
  icon size (sgoodwin@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge pull request #4496 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 1051203 (dmcphers@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4492 from VojtechVitek/obsolete_zend-5.6
  (dmcphers+openshiftbot@redhat.com)
- remove zend-5.6 rest_api tests (vvitek@redhat.com)
- For bug 1045566 Updates to the display of app meta data using icon/text so
  the user knows: if an app is a cartridge or quickstart if it's OpenShift
  maintained and receives automatic security updates or if it's partner,
  community created (sgoodwin@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Bug 1045559 - Show featured apps at the top of their app category
  (jforrest@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.5-1
- Fix bug 1048992: Define remote_request? in console controller
  (jliggitt@redhat.com)
- Bug 1045971 - add alias display overlaps on iphone 4S (jforrest@redhat.com)
- Merge pull request #4398 from bparees/rename_jee
  (dmcphers+openshiftbot@redhat.com)
- Bug 1047920 - application edit route should not be enabled
  (jforrest@redhat.com)
- rename jee to java_ee_6 (bparees@redhat.com)

