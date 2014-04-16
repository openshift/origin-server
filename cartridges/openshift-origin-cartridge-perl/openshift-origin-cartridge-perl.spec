%global cartridgedir %{_libexecdir}/openshift/cartridges/perl
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/perl

Name:          openshift-origin-cartridge-perl
Version: 1.22.5
Release:       1%{?dist}
Summary:       Perl cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      mod_perl
Requires:      perl-App-cpanminus
Requires:      perl-IO-Socket-SSL
# required for bin/build's usage of /usr/lib/rpm/perl.req
Requires:      rpm-build
Provides:      openshift-origin-cartridge-perl-5.10 = 2.0.0
Obsoletes:     openshift-origin-cartridge-perl-5.10 <= 1.99.9
BuildArch:     noarch

%description
Perl cartridge for OpenShift. (Cartridge Format V2)

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
%{cartridgedir}/logs
%{cartridgedir}/metadata
%{cartridgedir}/run
%{cartridgedir}/usr
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}


%changelog
* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.22.5-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.22.4-1
- Merge pull request #5260 from ironcladlou/cart-log-vars
  (dmcphers+openshiftbot@redhat.com)
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.22.3-1
- Perl cartridge version bump (jhadvig@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Bug 1086609 - Adding $OPENSHIFT_REPO_DIR/libs back into $PERL5LIB for
  backward compatibility (jhadvig@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Force httpd into its own pgroup (ironcladlou@gmail.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.21.7-1
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.21.6-1
- Bug 1080381 - Fixed problem with httpd based carts restart after force-stop
  (mfojtik@redhat.com)
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Replace the client_message with echo (jhadvig@redhat.com)
- Merge pull request #5041 from ironcladlou/logshifter/carts
  (dmcphers+openshiftbot@redhat.com)
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Mon Mar 24 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Changing the deplist.txt to cpan.txt in the module checking message
  (jhadvig@redhat.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Bug 1077501 - Source Bash SDK (jhadvig@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 1.21.2-1
- Remove unused teardowns (dmcphers@redhat.com)
- Make dep handling consistent (dmcphers@redhat.com)
- Merge pull request #4924 from jhadvig/perl_deps
  (dmcphers+openshiftbot@redhat.com)
- cpanfila and Makefile.PL support (jhadvig@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- rpm-build is required for the perl cartridge's build script
  (bleanhar@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Perl repository layout changes (jhadvig@redhat.com)
- Fix Bug 1070059 - Incorrect git command info listed in perl default home page
  added \ before $ (sgoodwin@redhat.com)
- change mirror1.ops to mirror.ops, which is load balanced between servers
  (tdawson@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
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

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4707 from danmcp/master (dmcphers@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 888714 - Remove gitkeep files from rpms (dmcphers@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Cleaning specs (dmcphers@redhat.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.18.7-1
- Bump up cartridge versions (bparees@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.18.6-1
- <perl,python,phpmyadmin carts> bug 1055095 (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.18.5-1
- Merge pull request #4502 from sosiouxme/custom-cart-confs
  (dmcphers+openshiftbot@redhat.com)
- <perl cart> enable providing custom gear server confs (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.18.4-1
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.18.3-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
- Applied fix to other affected cartridges (hripps@redhat.com)
- Bug 1026652 - Skip module checks if module exists in perl deplist.txt
  (mfojtik@redhat.com)
