%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%global cartridgedir %{_libexecdir}/openshift/cartridges/haproxy

Summary:       Provides HA Proxy
Name:          openshift-origin-cartridge-haproxy
Version: 1.21.0
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
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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

