%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global v8_scl v8314
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-admin-console
%global rubyabi 1.9.1

Summary:       OpenShift plugin adding an administrative console to the broker
Name:          rubygem-%{gem_name}
Version: 1.28.1
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
%{?scl:scl enable %scl %v8_scl - << \EOF}

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
* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 57 (admiller@redhat.com)

* Tue Jan 13 2015 Adam Miller <admiller@redhat.com> 1.27.2-1
- admin-console: allow multiple app search results (lmeyer@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Wed Sep 24 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Expose oo-stats data in an admin-console api (jforrest@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Merge pull request #5715 from detiber/sclbuildfixes
  (dmcphers+openshiftbot@redhat.com)
- scl build fixes (jdetiber@redhat.com)

* Thu Aug 21 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 50 (admiller@redhat.com)

* Mon Aug 11 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- Merge pull request #5696 from detiber/adminConsoleTestPartDeux
  (dmcphers+openshiftbot@redhat.com)
- Delete users plan_id users after admin-console functional tests
  (jdetiber@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.24.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)
- Test improvements that were affecting enterprise test scenarios
  (jdetiber@redhat.com)

* Mon Jul 28 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5633 from jcantrill/190_expose_region_and_zones
  (dmcphers+openshiftbot@redhat.com)
- Origin UI 190 - Expose region for app create and show, region and zone on
  gear page for admin-console (jcantril@redhat.com)
- Bubble up config suggestions compared to other the suggestions of the same
  level of importance (jforrest@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- [stylesheets] - remove unit after 0 length. (pivanov@mozilla.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.21.0-2
- bumpspec to mass fix tags

* Thu Apr 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Merge pull request #5175 from liggitt/teams_ui
  (dmcphers+openshiftbot@redhat.com)
- Update jquery, add typeahead widget (jliggitt@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Allow version of jQuery newer than 2.0 (jliggitt@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.19.2-1
- Added User pending-op-group/pending-op functionality Added pending op groups
  for user add_ssh_keys/remove_ssh_keys (rpenta@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- Add README for admin api, change size param to limit (jforrest@redhat.com)
- Admin search API v1 (jforrest@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.18.3-1
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- Cleaning specs (dmcphers@redhat.com)
- Rename 'server_identities' to 'servers' and 'active_server_identities_size'
  to 'active_servers_size' in district model (rpenta@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Merge remote-tracking branch 'origin/master' into
  origin_broker_193_carts_in_mongo (ccoleman@redhat.com)
- Move cartridges into Mongo (ccoleman@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)
