%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/ruby
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/ruby

Name:          openshift-origin-cartridge-ruby
Version: 1.23.3
Release:       1%{?dist}
Summary:       Ruby cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-node-util
Requires:      rubygem(openshift-origin-node)
# For the ruby 1.8 cartridge
%if 0%{?rhel}
Requires:      mod_passenger
Requires:      rubygem-bundler
Requires:      rubygem(openshift-origin-node)
Requires:      rubygem-passenger
Requires:      rubygem-passenger-native
Requires:      rubygem-passenger-native-libs
Requires:      rubygems
# BZ1066246 - Older versions rubygems required ruby-rdoc, but now we
# need to declare the dependency here
Requires:      ruby-rdoc
Requires:      rubygem-thread-dump
Requires:      %{?scl:%scl_prefix}rubygem-fastthread
Requires:      %{?scl:%scl_prefix}runtime
%endif
Requires:      %{?scl:%scl_prefix}js
Requires:      %{?scl:%scl_prefix}libyaml
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}ruby-libs
Requires:      %{?scl:%scl_prefix}rubygem-bundler
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-devel
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}rubygems
Provides:      openshift-origin-cartridge-ruby-1.8 = 2.0.0
Provides:      openshift-origin-cartridge-ruby-1.9-scl = 2.0.0
Obsoletes:     openshift-origin-cartridge-ruby-1.8 <= 1.99.9
Obsoletes:     openshift-origin-cartridge-ruby-1.9-scl <= 1.99.9
BuildArch:     noarch

%description
Ruby cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec
%__rm logs/.gitkeep
%__rm run/.gitkeep

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{httpdconfdir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}/env
%{cartridgedir}/lib
%{cartridgedir}/logs
%{cartridgedir}/metadata
%{cartridgedir}/run
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}

%changelog
* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Force httpd into its own pgroup (ironcladlou@gmail.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- Make restarts resilient to missing/corrupt pidfiles (ironcladlou@gmail.com)
- Merge pull request #5097 from dobbymoodge/BZ1066246
  (dmcphers+openshiftbot@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)
- ruby cart: Explicitly req. ruby-rdoc dep for rhel (jolamb@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- util: add nodejs context for bundle exec call (jolamb@redhat.com)
- Merge pull request #5077 from mfojtik/bugzilla/1080789
  (dmcphers+openshiftbot@redhat.com)
- Bug 1080789 - Add PASSENGER_TEMP_DIR to ruby cartridge (mfojtik@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bug 1080381 - Fixed problem with httpd based carts restart after force-stop
  (mfojtik@redhat.com)
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)
- Merge pull request #5055 from ironcladlou/ruby-umask
  (dmcphers+openshiftbot@redhat.com)
- Set umask when starting Passenger/httpd (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)
- Bug 1030873 - Fix the there is no system NodeJS installed which is required
  for assets compilation (mfojtik@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.22.2-1
- Remove unused teardowns (dmcphers@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Refactor the way how we check if compilation of assets is necessary (ruby)
  (mfojtik@redhat.com)
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Update ruby cartridge to support LD_LIBRARY_PATH_ELEMENT (mfojtik@redhat.com)
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Merge pull request #4729 from tdawson/2014-02/tdawson/fix-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4372 from maxamillion/admiller/no_defaulttype_apache24
  (dmcphers+openshiftbot@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)
- This directive throws a deprecation warning in apache 2.4
  (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4707 from danmcp/master (dmcphers@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 888714 - Remove gitkeep files from rpms (dmcphers@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

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
