%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global scl_root /opt/rh/ruby193/root
%endif
%global rubyabi 1.9.1

Summary:       Utility scripts for the OpenShift Origin broker
Name:          openshift-origin-broker-util
Version: 1.20.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: %{?scl:%scl_prefix}ruby-devel
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      openshift-origin-broker
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
Requires:      mongodb
# For oo-register-dns
Requires:      bind-utils
# For oo-admin-broker-auth
Requires:      %{?scl:%scl_prefix}mcollective-client
BuildArch:     noarch

%description
This package contains a set of utility scripts for the openshift broker.  
They must be run on a openshift broker instance.

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_sbindir}
cp -p oo-* %{buildroot}%{_sbindir}/

mkdir -p %{buildroot}%{?scl:%scl_root}%{ruby_libdir}
cp -p lib/*.rb %{buildroot}%{?scl:%scl_root}%{ruby_libdir}

mkdir -p %{buildroot}%{_mandir}/man8/
cp -p man/*.8 %{buildroot}%{_mandir}/man8/

%files
%doc LICENSE
%attr(0750,-,-) %{_sbindir}/oo-accept-broker
%attr(0750,-,-) %{_sbindir}/oo-accept-systems
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-auth
%attr(0750,-,-) %{_sbindir}/oo-admin-broker-cache
%attr(0750,-,-) %{_sbindir}/oo-admin-chk
%attr(0750,-,-) %{_sbindir}/oo-admin-clear-pending-ops
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-app
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-authorization
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-cartridge
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-district
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-region
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-domain
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-usage
%attr(0750,-,-) %{_sbindir}/oo-admin-ctl-user
%attr(0750,-,-) %{_sbindir}/oo-admin-move
%attr(0750,-,-) %{_sbindir}/oo-admin-repair
%attr(0750,-,-) %{_sbindir}/oo-admin-upgrade
%attr(0750,-,-) %{_sbindir}/oo-admin-usage
%attr(0750,-,-) %{_sbindir}/oo-analytics-export
%attr(0750,-,-) %{_sbindir}/oo-analytics-import
%attr(0750,-,-) %{_sbindir}/oo-app-info
%attr(0750,-,-) %{_sbindir}/oo-quarantine
%attr(0750,-,-) %{_sbindir}/oo-register-dns
%attr(0750,-,-) %{_sbindir}/oo-stats

%{?scl:%scl_root}%{ruby_libdir}/app_info.rb

%{_mandir}/man8/oo-accept-broker.8.gz
%{_mandir}/man8/oo-accept-systems.8.gz
%{_mandir}/man8/oo-admin-broker-auth.8.gz
%{_mandir}/man8/oo-admin-broker-cache.8.gz
%{_mandir}/man8/oo-admin-chk.8.gz
%{_mandir}/man8/oo-admin-clear-pending-ops.8.gz
%{_mandir}/man8/oo-admin-ctl-app.8.gz
%{_mandir}/man8/oo-admin-ctl-authorization.8.gz
%{_mandir}/man8/oo-admin-ctl-cartridge.8.gz
%{_mandir}/man8/oo-admin-ctl-district.8.gz
%{_mandir}/man8/oo-admin-ctl-region.8.gz
%{_mandir}/man8/oo-admin-ctl-domain.8.gz
%{_mandir}/man8/oo-admin-ctl-usage.8.gz
%{_mandir}/man8/oo-admin-ctl-user.8.gz
%{_mandir}/man8/oo-admin-move.8.gz
%{_mandir}/man8/oo-admin-repair.8.gz
%{_mandir}/man8/oo-admin-usage.8.gz
%{_mandir}/man8/oo-app-info.8.gz
%{_mandir}/man8/oo-register-dns.8.gz
%{_mandir}/man8/oo-stats.8.gz
%{_mandir}/man8/oo-analytics-export.8.gz
%{_mandir}/man8/oo-analytics-import.8.gz
%{_mandir}/man8/oo-quarantine.8.gz

%changelog
* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Bug 1058181 - Fix query filter in oo-admin-usage (rpenta@redhat.com)
- Make it possible to run oo-admin-* scripts from source (ccoleman@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Fri Jan 24 2014 Adam Miller <admiller@redhat.com> 1.19.11-1
- Updating op state using set_state method (abhgupta@redhat.com)
- oo-admin-repair: Print info related to usage errors for paid users in usage-
  refund.log (rpenta@redhat.com)

* Wed Jan 22 2014 Adam Miller <admiller@redhat.com> 1.19.10-1
- Bug 1056178 - Add useful error message during node removal from district
  (rpenta@redhat.com)

* Tue Jan 21 2014 Adam Miller <admiller@redhat.com> 1.19.9-1
- Bug 1040113: Handling edge cases in cleaning up downloaded cart map Also,
  fixing a couple of minor issues (abhgupta@redhat.com)
- Bug 1054574 - clear cache when removing cartridge (contact@fabianofranz.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Merge remote-tracking branch 'origin/master' into add_cartridge_mongo_type
  (ccoleman@redhat.com)
- Bug 1054574 - Clear cache on (de)activation Bug 1052829 - Fix example text in
  oo-admin-ctl-cartridge man (ccoleman@redhat.com)
- Allow downloadable cartridges to appear in rhc cartridge list
  (ccoleman@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- Bug 1049064: The helper methods needed to be defined before their use
  (abhgupta@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Fix for bug 1049064 (abhgupta@redhat.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- oo-admin-repair typo fix (rpenta@redhat.com)
- Merge pull request #4429 from pravisankar/dev/ravi/usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-repair refactor Added repair for usage inconsistencies
  (rpenta@redhat.com)
- Use mongoid 'save\!' instead of 'save' to raise an exception in case of
  failures (rpenta@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.19.4-1
- Merge pull request #4415 from pravisankar/dev/ravi/admin-usage-changes
  (dmcphers+openshiftbot@redhat.com)
- oo-admin-usage: Add a note 'Aggregated usage excludes monthly plan discounts'
  in the end when user plan exists (rpenta@redhat.com)
- Add --quiet, --create, and --logins-file to oo-admin-ctl-user
  (jliggitt@redhat.com)
- oo-admin-usage enhancements: Show aggregated usage data for the given
  timeframe. (rpenta@redhat.com)

