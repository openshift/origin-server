%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/haproxy

Summary:       Provides HA Proxy
Name:          openshift-origin-cartridge-haproxy
Version: 1.24.2
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      haproxy
Requires:      socat
Requires:      %{?scl:%scl_prefix}rubygem-daemons
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
Provides:      openshift-origin-cartridge-haproxy-1.4 = 2.0.0
Obsoletes:     openshift-origin-cartridge-haproxy-1.4 <= 1.99.9
BuildArch:     noarch

%description
HAProxy cartridge for OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}/env
%{cartridgedir}/metadata
%{cartridgedir}/usr
%{cartridgedir}/versions
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.5-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Merge pull request #5260 from ironcladlou/cart-log-vars
  (dmcphers+openshiftbot@redhat.com)
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- Merge pull request #5237 from ironcladlou/haproxyctld-stop-fix
  (dmcphers+openshiftbot@redhat.com)
- Check haproxyctld pid when trying to stop it (ironcladlou@gmail.com)
- Merge pull request #5236 from bparees/haproxy_tidy
  (dmcphers+openshiftbot@redhat.com)
- haproxy_ctld.log not tidy after run the command rhc tidy-app app_name
  (bparees@redhat.com)

* Fri Apr 11 2014 Adam Miller <admiller@redhat.com> 1.23.2-1
- Merge pull request #5208 from bparees/haproxy_scale
  (dmcphers+openshiftbot@redhat.com)
- Add the ability to adjust when haproxy shutsdown the app cart in the lead
  gear (bparees@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- Bug 1081954 - Prevent killing non-existent haproxy process when force-stopped
  (mfojtik@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Merge pull request #5086 from VojtechVitek/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)
- Merge pull request #5074 from bparees/add_tidy
  (dmcphers+openshiftbot@redhat.com)
- cron/mongo logs does not get cleaned via rhc app-tidy (bparees@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- remove old usage reference to haproxy_ctld_daemon (bparees@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Fixing typos (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Bug 1065133: Add websocket option to haproxy manifest and sanitize uri
  returned from mod_rewrite. (mrunalp@gmail.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- Update haproxy_ctld.rb (etsauer@gmail.com)
- Ignore failures if haproxy_ctld isn't running (bleanhar@redhat.com)
- Bug 1057558 - reload the haproxy_ctld.rb action hook on git push
  (bleanhar@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bug 1044927 (dmcphers@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Merge pull request #4558 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Bump up cartridge versions (bparees@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Bug 1056483 - Better error messaging with direct usage of haproxy_ctld
  (dmcphers@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Merge pull request #4456 from caruccio/proxy-gear-ttl
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4463 from danmcp/master
  (dmcphers+openshiftbot@redhat.com)
- Bisect the scale up/down threshold more evenly for lower scale numbers
  (dmcphers@redhat.com)
- Proxy gear ttl from env var (mateus.caruccio@getupcloud.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Bug 1051446 (dmcphers@redhat.com)
- Fixing typos (dmcphers@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.3-1
- Make sessions per gear configurable and use moving average for num sessions
  (dmcphers@redhat.com)

