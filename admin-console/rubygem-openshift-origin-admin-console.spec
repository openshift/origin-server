%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-admin-console
%global rubyabi 1.9.1

Summary:       OpenShift plugin adding an administrative console to the broker
Name:          rubygem-%{gem_name}
Version: 1.16.0
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-sass-twitter-bootstrap
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-formtastic
Requires:      %{?scl:%scl_prefix}rubygem-net-http-persistent
Requires:      %{?scl:%scl_prefix}rubygem-sass-twitter-bootstrap
Requires:      %{?scl:%scl_prefix}rubygem-haml
Requires:      %{?scl:%scl_prefix}rubygem-jquery-rails
Requires:      %{?scl:%scl_prefix}rubygem-compass-rails
Requires:      %{?scl:%scl_prefix}rubygem-coffee-rails
Requires:      %{?scl:%scl_prefix}rubygem-sass-rails
Requires:      %{?scl:%scl_prefix}rubygem-uglifier
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      rubygem-openshift-origin-common
Requires:      rubygem-openshift-origin-controller
Requires:      %{?scl:%scl_prefix}mcollective-client
Requires:      openshift-origin-broker
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygem-json
BuildRequires: %{?scl:%scl_prefix}rubygem-sass-twitter-bootstrap
BuildRequires: %{?scl:%scl_prefix}rubygem-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-formtastic
BuildRequires: %{?scl:%scl_prefix}rubygem-net-http-persistent
BuildRequires: %{?scl:%scl_prefix}rubygem-sass-twitter-bootstrap
BuildRequires: %{?scl:%scl_prefix}rubygem-haml
BuildRequires: %{?scl:%scl_prefix}rubygem-jquery-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-compass-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-coffee-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-sass-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-uglifier
BuildRequires: %{?scl:%scl_prefix}rubygem-therubyracer
BuildArch:     noarch

%description
OpenShift plugin that adds the administrative console as a Rails Engine for the broker.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}

set -ex
mkdir -p .%{gem_dir}

%if 0%{?fedora}%{?rhel} <= 6
# TODO: get the asset compilation working.
rm -f Gemfile.lock
#bundle install --local

mkdir -p %{buildroot}%{_var}/log/openshift/broker
mkdir -m 770 %{buildroot}%{_var}/log/openshift/broker/httpd/
touch %{buildroot}%{_var}/log/openshift/broker/production.log
chmod 0666 %{buildroot}%{_var}/log/openshift/broker/production.log

pushd test/dummy/
#ADMIN_CONSOLE_CONFIG_FILE=../../conf/openshift-origin-admin-console.conf \
#  RAILS_ENV=production \
#  RAILS_LOG_PATH=%{buildroot}%{_var}/log/openshift/broker/production.log \
#  RAILS_RELATIVE_URL_ROOT=/admin-console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
popd

rm -rf %{buildroot}%{_var}/log/openshift/*
rm -f Gemfile.lock
%endif

# Build and install into the rubygem structure
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift/plugins.d
cp %{buildroot}/%{gem_dir}/gems/%{gem_name}-%{version}/conf/openshift-origin-admin-console.conf %{buildroot}/etc/openshift/plugins.d/openshift-origin-admin-console.conf

%files
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%config(noreplace) /etc/openshift/plugins.d/openshift-origin-admin-console.conf

%defattr(-,root,apache,-)

%changelog
* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.3-1
- Allow for version 4.0.x of haml gem to be used (jforrest@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3622 from brenton/ruby193-mcollective
  (dmcphers+openshiftbot@redhat.com)
- admin-console spec changes for ruby193-mcollective (bleanhar@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-0
- Bump up version to 1.15

* Tue Sep 10 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Admin console design feedback css tweaks (jforrest@redhat.com)
- Bug 1005733 - admin console stats y-label mis-aligned and mobile res x-labels
  wrap badly (jforrest@redhat.com)
- <capacity planning> review comments (jforrest@redhat.com)
- <admin console> edge case on suggestion display (lmeyer@redhat.com)
- <admin-console> tweaks to views (lmeyer@redhat.com)
- <admin console> lower default active%% to 5 (lmeyer@redhat.com)
- Bug 1004160 - admin console stats graphs fail to load with arg error
  (jforrest@redhat.com)
- <admin console> capacity planning (jforrest@redhat.com)
- <admin stats> refactor and mods for admin console (lmeyer@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- fix old mirror url (tdawson@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 31 2013 Adam Miller <admiller@redhat.com> 0.0.6-1
- Consolidated docs for admin/mgmt consoles, cartridges (hripps@redhat.com)
- Admin console test framework and initial functional tests
  (jforrest@redhat.com)

* Mon Jul 29 2013 Adam Miller <admiller@redhat.com> 0.0.5-1
- Merge pull request #3184 from
  jwforres/bug_988740_admin_console_empty_search_query
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3185 from
  jwforres/bug_988733_admin_console_headers_overflow
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #3182 from
  jwforres/bug_988282_admin_console_stats_no_apps_failure
  (dmcphers+openshiftbot@redhat.com)
- Bug 988740 - code review fixes (jforrest@redhat.com)
- Bug 988733 - admin console page headers overflow (jforrest@redhat.com)
- Bug 988740 - admin console routing error on empty search query
  (jforrest@redhat.com)
- Bug 988282 - admin console stats page histograms fail with no apps
  (jforrest@redhat.com)

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.0.4-1
- fix tito tags round 2, someone put the already tagged version in DistGit

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com> 0.0.3-1
- fix tito tags

* Fri Jul 26 2013 Adam Miller <admiller@redhat.com>
- new package built with tito

* Thu Jul 18 2013 Troy Dawson <tdawson@redhat.com> 0.0.1-1
- new package built with tito

