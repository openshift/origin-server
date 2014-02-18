%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/ruby
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/ruby

Name:          openshift-origin-cartridge-ruby
Version: 1.21.0
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

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/versions/1.9-scl %{buildroot}%{cartridgedir}/versions/1.9
%__mv %{buildroot}%{cartridgedir}/lib/ruby_context.rhel %{buildroot}%{cartridgedir}/lib/ruby_context
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
%__rm -rf %{buildroot}%{cartridgedir}/versions/1.9-scl
%__rm -rf %{buildroot}%{cartridgedir}/versions/1.8
%__mv %{buildroot}%{cartridgedir}/lib/ruby_context.f19 %{buildroot}%{cartridgedir}/lib/ruby_context
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%__rm -f %{buildroot}%{cartridgedir}/lib/ruby_context.*
%__rm -f %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}

%changelog
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
