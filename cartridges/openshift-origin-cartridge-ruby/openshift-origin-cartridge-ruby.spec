%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/v2/ruby

Name:          openshift-origin-cartridge-ruby
Version: 0.5.1
Release:       1%{?dist}
Summary:       Ruby cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      gcc-c++
Requires:      libev
Requires:      libev-devel
Requires:      libxml2
Requires:      libxml2-devel
Requires:      libxslt
Requires:      libxslt-devel
Requires:      mysql-devel
Requires:      openshift-origin-node-util
Requires:      rubygem(openshift-origin-node)
Requires:      sqlite-devel

# For the ruby 1.8 cartridge
%if 0%{?rhel}
Requires:      js
Requires:      mod_passenger
Requires:      ruby-devel
Requires:      rubygem-bson_ext
Requires:      rubygem-bundler
Requires:      rubygem(openshift-origin-node)
Requires:      rubygem-passenger
Requires:      rubygem-passenger-native
Requires:      rubygem-passenger-native-libs
Requires:      rubygem-rack >= 1.1.0
Requires:      rubygems
Requires:      rubygem-sqlite3
Requires:      rubygem-thread-dump
Requires:      ruby-mysql
Requires:      ruby-sqlite3
Requires:      %{?scl:%scl_prefix}rubygem-fastthread
Requires:      %{?scl:%scl_prefix}runtime
%endif

Requires:      %{?scl:%scl_prefix}js
Requires:      %{?scl:%scl_prefix}js-devel
Requires:      %{?scl:%scl_prefix}libyaml
Requires:      %{?scl:%scl_prefix}libyaml-devel
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}ruby-devel
Requires:      %{?scl:%scl_prefix}rubygem-actionmailer
Requires:      %{?scl:%scl_prefix}rubygem-actionpack
Requires:      %{?scl:%scl_prefix}rubygem-activemodel
Requires:      %{?scl:%scl_prefix}rubygem-activerecord
Requires:      %{?scl:%scl_prefix}rubygem-activeresource
Requires:      %{?scl:%scl_prefix}rubygem-activesupport
Requires:      %{?scl:%scl_prefix}rubygem-arel
Requires:      %{?scl:%scl_prefix}rubygem-bacon
Requires:      %{?scl:%scl_prefix}rubygem-bcrypt-ruby
Requires:      %{?scl:%scl_prefix}rubygem-bigdecimal
Requires:      %{?scl:%scl_prefix}rubygem-bson
Requires:      %{?scl:%scl_prefix}rubygem-bson_ext
Requires:      %{?scl:%scl_prefix}rubygem-builder
Requires:      %{?scl:%scl_prefix}rubygem-bundler
Requires:      %{?scl:%scl_prefix}rubygem-coffee-rails
Requires:      %{?scl:%scl_prefix}rubygem-coffee-script
Requires:      %{?scl:%scl_prefix}rubygem-daemon_controller
Requires:      %{?scl:%scl_prefix}rubygem-diff-lcs
Requires:      %{?scl:%scl_prefix}rubygem-erubis
Requires:      %{?scl:%scl_prefix}rubygem-execjs
Requires:      %{?scl:%scl_prefix}rubygem-fakeweb
Requires:      %{?scl:%scl_prefix}rubygem-fssm
Requires:      %{?scl:%scl_prefix}rubygem-hike
Requires:      %{?scl:%scl_prefix}rubygem-http_connection
Requires:      %{?scl:%scl_prefix}rubygem-i18n
Requires:      %{?scl:%scl_prefix}rubygem-introspection
Requires:      %{?scl:%scl_prefix}rubygem-io-console
Requires:      %{?scl:%scl_prefix}rubygem-journey
Requires:      %{?scl:%scl_prefix}rubygem-jquery-rails
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-json_pure
Requires:      %{?scl:%scl_prefix}rubygem-mail
Requires:      %{?scl:%scl_prefix}rubygem-metaclass
Requires:      %{?scl:%scl_prefix}rubygem-mime-types
Requires:      %{?scl:%scl_prefix}rubygem-minitest
Requires:      %{?scl:%scl_prefix}rubygem-mocha
Requires:      %{?scl:%scl_prefix}rubygem-mongo
Requires:      %{?scl:%scl_prefix}rubygem-multi_json
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-devel
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}rubygem-pg
Requires:      %{?scl:%scl_prefix}rubygem-polyglot
Requires:      %{?scl:%scl_prefix}rubygem-rack
Requires:      %{?scl:%scl_prefix}rubygem-rack-cache
Requires:      %{?scl:%scl_prefix}rubygem-rack-ssl
Requires:      %{?scl:%scl_prefix}rubygem-rack-test
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-railties
Requires:      %{?scl:%scl_prefix}rubygem-rake
Requires:      %{?scl:%scl_prefix}rubygem-rdoc
Requires:      %{?scl:%scl_prefix}rubygem-rspec
Requires:      %{?scl:%scl_prefix}rubygem-ruby2ruby
Requires:      %{?scl:%scl_prefix}rubygem-ruby_parser
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem-sass
Requires:      %{?scl:%scl_prefix}rubygem-sass-rails
Requires:      %{?scl:%scl_prefix}rubygem-sexp_processor
Requires:      %{?scl:%scl_prefix}rubygem-sinatra
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-sqlite3
Requires:      %{?scl:%scl_prefix}rubygem-test_declarative
Requires:      %{?scl:%scl_prefix}rubygem-thor
Requires:      %{?scl:%scl_prefix}rubygem-tilt
Requires:      %{?scl:%scl_prefix}rubygem-treetop
Requires:      %{?scl:%scl_prefix}rubygem-tzinfo
Requires:      %{?scl:%scl_prefix}rubygem-uglifier
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple
Requires:      %{?scl:%scl_prefix}rubygem-ZenTest
Requires:      %{?scl:%scl_prefix}ruby-irb
Requires:      %{?scl:%scl_prefix}ruby-libs
Requires:      %{?scl:%scl_prefix}ruby-mysql
Requires:      %{?scl:%scl_prefix}ruby-tcltk

# Deps for users
Requires:      ImageMagick-devel
Requires:      ruby-RMagick
%if 0%{?rhel}
Requires:      ruby-nokogiri
%endif
%if 0%{?fedora}
Requires:      rubygem-nokogiri
%endif

BuildArch:     noarch

%description
Ruby cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

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

%post
%{_sbindir}/oo-admin-cartridge --action install --source %{cartridgedir}


%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 0.4.8-1
- Bug 968882 - Fix MIMEMagicFile (jhonce@redhat.com)

* Wed May 29 2013 Adam Miller <admiller@redhat.com> 0.4.7-1
- Bug 966465 (dmcphers@redhat.com)
- Bug 962657 (dmcphers@redhat.com)

* Tue May 28 2013 Adam Miller <admiller@redhat.com> 0.4.6-1
- Replace pre-receive cart control action with pre-repo-archive
  (ironcladlou@gmail.com)

* Thu May 23 2013 Adam Miller <admiller@redhat.com> 0.4.5-1
- Bug 966255: Remove OPENSHIFT_INTERNAL_* references from v2 carts
  (ironcladlou@gmail.com)

* Wed May 22 2013 Adam Miller <admiller@redhat.com> 0.4.4-1
- Bug 962662 (dmcphers@redhat.com)
- Bug 965537 - Dynamically build PassEnv httpd configuration
  (jhonce@redhat.com)
- Bug 965322 - Use expected version of ruby to start httpd (jhonce@redhat.com)
- Bug 965322 - Ruby always building 1.9.3 environment (jhonce@redhat.com)
- Fix bug 964348 (pmorie@gmail.com)

* Mon May 20 2013 Dan McPherson <dmcphers@redhat.com> 0.4.3-1
- spec file cleanup (tdawson@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Bug 963634 - Need to create all 1.9.3 env vars in setup (jhonce@redhat.com)
- process-version -> update-configuration (dmcphers@redhat.com)
- Bug 963156 (dmcphers@redhat.com)
- Implement status function for ruby v2 cart based on simple curl.
  (asari.ruby@gmail.com)
- locking fixes and adjustments (dmcphers@redhat.com)
- Add erb processing to managed_files.yml Also fixed and added some test cases
  (fotios@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- WIP Cartridge Refactor -- Cleanup spec files (jhonce@redhat.com)
- Card online_runtime_297 - Allow cartridges to use more resources
  (jhonce@redhat.com)
- Bug 957247 (asari.ruby@gmail.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Mon May 06 2013 Adam Miller <admiller@redhat.com> 0.3.6-1
- moving templates to usr (dmcphers@redhat.com)

* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.3.5-1
- fix tests (dmcphers@redhat.com)
- Special file processing (fotios@redhat.com)

* Wed May 01 2013 Adam Miller <admiller@redhat.com> 0.3.4-1
- Card online_runtime_266 - Fixed missing source in control script
  (jhonce@redhat.com)
- Bug 956552: Fix error handling in stop action (ironcladlou@gmail.com)
- Card online_runtime_266 - Support for LD_LIBRARY_PATH (jhonce@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 0.3.3-1
- Env var WIP. (mrunalp@gmail.com)
- Merge pull request #2201 from BanzaiMan/dev/hasari/c276
  (dmcphers+openshiftbot@redhat.com)
- Card 276 (asari.ruby@gmail.com)

* Mon Apr 29 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Add health urls to each v2 cartridge. (rmillner@redhat.com)
- Bug 957073 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- Split v2 configure into configure/post-configure (ironcladlou@gmail.com)
- more install/post-install scripts (dmcphers@redhat.com)
- Implement hot deployment for V2 cartridges (ironcladlou@gmail.com)
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- WIP Cartridge Refactor - Change environment variable files to contain just
  value (jhonce@redhat.com)
- Adding V2 Format to all v2 cartridges (calfonso@redhat.com)
- The v2 cartridge needs to pull in the ruby-1.8 dependencies as well
  (bleanhar@redhat.com)
- Merge pull request #2136 from BanzaiMan/dev/hasari/bz949844
  (dmcphers+openshiftbot@redhat.com)
- <v2 carts> remove abstract cartridge from v2 requires (lmeyer@redhat.com)
- Bug 949844 (asari.ruby@gmail.com)
- Fix Ruby README symlinks (ironcladlou@gmail.com)
- V2 documentation refactoring (ironcladlou@gmail.com)
- V2 cartridge documentation updates (ironcladlou@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Tue Apr 16 2013 Troy Dawson <tdawson@redhat.com> 0.2.9-1
- Merge pull request #2071 from BanzaiMan/dev/hasari/bz952097
  (dmcphers@redhat.com)
- Merge pull request #2074 from BanzaiMan/ruby_v2_threaddump
  (dmcphers+openshiftbot@redhat.com)
- Setting mongodb connection hooks to use the generic nosqldb name
  (calfonso@redhat.com)
- No need to test state file in the cartridge. (asari.ruby@gmail.com)
- Combine bin/threaddump into bin/control. (asari.ruby@gmail.com)
- Bug 949844: Add support for threaddump command in v2 Ruby cartridge.
  (asari.ruby@gmail.com)
- Set up $OPENSHIFT_HOMEDIR/.gem for v2 Ruby apps (asari.ruby@gmail.com)

* Mon Apr 15 2013 Adam Miller <admiller@redhat.com> 0.2.8-1
- V2 action hook cleanup (ironcladlou@gmail.com)

* Sun Apr 14 2013 Krishna Raman <kraman@gmail.com> 0.2.7-1
- Merge pull request #2065 from jwhonce/wip/manifest_scrub
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2053 from calfonso/master
  (dmcphers+openshiftbot@redhat.com)
- WIP Cartridge Refactor - Scrub manifests (jhonce@redhat.com)
- Merge pull request #2046 from BanzaiMan/dev/hasari/bz949439
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #2045 from BanzaiMan/dev/hasari/bz951389
  (dmcphers+openshiftbot@redhat.com)
- Adding connection hook for mongodb There are three leading params we don't
  care about, so the hooks are using shift to discard. (calfonso@redhat.com)
- Remove unrelated files from ruby cartridge and put ones for Ruby.
  (asari.ruby@gmail.com)
- Provide overrides based on Ruby version so that a Ruby-1.8 app can scale.
  (asari.ruby@gmail.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.2.6-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Thu Apr 11 2013 Adam Miller <admiller@redhat.com> 0.2.5-1
- Bug 950823 (asari.ruby@gmail.com)
- Merge pull request #2001 from brenton/misc2 (dmcphers@redhat.com)
- Merge pull request #1752 from BanzaiMan/ruby_v2_work (dmcphers@redhat.com)
- Calling oo-admin-cartridge from a few more v2 cartridges
  (bleanhar@redhat.com)
- Correct the log directory to clean up during tidy in Ruby v2 cartridge
  (asari.ruby@gmail.com)
- Postpone implementing pre-build, post-deploy and threaddump in Ruby v2.
  (asari.ruby@gmail.com)
- Roll 'build' logic into 'control' script in Ruby cartridge.
  (asari.ruby@gmail.com)
- Ruby v2 cartridge work (asari.ruby@gmail.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Anchor locked_files.txt entries at the cart directory (ironcladlou@gmail.com)

* Tue Apr 09 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Merge pull request #1962 from danmcp/master (dmcphers@redhat.com)
- jenkins WIP (dmcphers@redhat.com)
- Rename cideploy to geardeploy. (mrunalp@gmail.com)
- Merge pull request #1942 from ironcladlou/dev/v2carts/vendor-changes
  (dmcphers+openshiftbot@redhat.com)
- Remove vendor name from installed V2 cartridge path (ironcladlou@gmail.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- Merge pull request #1930 from mrunalp/dev/cart_hooks (dmcphers@redhat.com)
- Add hooks for other carts. (mrunalp@gmail.com)
- Fix Jenkins deploy cycle (ironcladlou@gmail.com)
- adding all the jenkins jobs (dmcphers@redhat.com)
- Adding jenkins templates to carts (dmcphers@redhat.com)
- Merge pull request #1847 from BanzaiMan/dev/hasari/bz928675
  (dmcphers@redhat.com)
- Update OpenShift web site URL on the Rack template. (asari.ruby@gmail.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- BZ928282: Copy over hidden files under template. (mrunalp@gmail.com)

* Mon Mar 25 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- corrected some 1.8/1.9 issues, cucumber tests now work (mmcgrath@redhat.com)
- fixed for vendor-ruby bits (mmcgrath@redhat.com)
- removing 18 reference (mmcgrath@redhat.com)
- moving argument parsing to util (mmcgrath@redhat.com)
- Force follow reference (mmcgrath@redhat.com)
- Adding actual 1.8 and 1.9 support (mmcgrath@redhat.com)
- make sleep more efficient (mmcgrath@redhat.com)
- Added setup parsing (mmcgrath@redhat.com)

* Thu Mar 21 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- No need to set OPENSHIFT_RUBY_DIR in setup. (asari.ruby@gmail.com)
- Remove debug outputs (asari.ruby@gmail.com)
- Use a better defined ENV variable. (asari.ruby@gmail.com)
- Enough to get a Ruby 1.9 app bootable. (asari.ruby@gmail.com)
- Change V2 manifest Version elements to strings (pmorie@gmail.com)
- Fix cart names to exclude versions. (mrunalp@gmail.com)

* Mon Mar 18 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- add cart vendor and version (dmcphers@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- Make packages build/install on F19+ (tdawson@redhat.com)
- remove old obsoletes (tdawson@redhat.com)

* Tue Mar 12 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- Fixing tags on master

* Mon Mar 11 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.2-1
- 

* Fri Mar 08 2013 Mike McGrath <mmcgrath@redhat.com> 0.1.1-1
- new package built with tito

* Wed Feb 20 2013 Mike McGrath <mmcgrath@redhat.com> - 0.1.0-1
- Initial SPEC created
