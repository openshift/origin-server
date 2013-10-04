%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective/
%else
    %global mco_root /usr/libexec/mcollective/mcollective/
%endif

Summary:       Common msg components for OpenShift broker and node
Name:          openshift-origin-msg-common
Version: 1.16.0
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}mcollective-common >= 2.2.3
BuildArch:     noarch

%description
Provides the common dependencies of the msg components
for OpenShift broker and node

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{mco_root}agent
cp -p agent/* %{buildroot}%{mco_root}agent/
chmod 644 %{buildroot}%{mco_root}agent/*

%files
%{mco_root}agent/*

%changelog
* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.2-1
- Merge pull request #3647 from detiber/runtime_card_255
  (dmcphers+openshiftbot@redhat.com)
- Card origin_runtime_255: Publish district uid limits to nodes
  (jdetiber@redhat.com)

* Tue Sep 24 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Creating the app secret token (abhgupta@redhat.com)
- bump_minor_versions for sprint 34 (admiller@redhat.com)

* Thu Sep 05 2013 Adam Miller <admiller@redhat.com> 1.14.2-1
- remove validator, require mcollective-common >= 2.2.3 (#961137)
  (tdawson@redhat.com)

* Thu Aug 29 2013 Adam Miller <admiller@redhat.com> 1.14.1-1
- Merge remote-tracking branch 'origin/master' into propagate_app_id_to_gears
  (ccoleman@redhat.com)
- bump_minor_versions for sprint 33 (admiller@redhat.com)
- Switch OPENSHIFT_APP_UUID to equal the Mongo application '_id' field
  (ccoleman@redhat.com)

* Tue Aug 20 2013 Adam Miller <admiller@redhat.com> 1.13.4-1
- User vars node changes:  - Use 'user-var-add' mcollective call for *add*
  and/or *push* user vars. This will reduce unnecessary additional
  code/complexity.  - Add some more reserved var names: PATH, IFS, USER, SHELL,
  HOSTNAME, LOGNAME  - Do not attempt rsync when .env/user_vars dir is empty  -
  Misc bug fixes (rpenta@redhat.com)
- WIP Node Platform - Add support for settable user variables
  (jhonce@redhat.com)

* Fri Aug 16 2013 Adam Miller <admiller@redhat.com> 1.13.3-1
- Removing has_app mcollective method since its no longer used
  (abhgupta@redhat.com)

* Thu Aug 15 2013 Adam Miller <admiller@redhat.com> 1.13.2-1
- migration helpers and rest interface for port information of gears
  (rchopra@redhat.com)

* Thu Aug 08 2013 Adam Miller <admiller@redhat.com> 1.13.1-1
- Fixing has_app method in mcollective (abhgupta@redhat.com)
- bump_minor_versions for sprint 32 (admiller@redhat.com)

* Wed Jul 24 2013 Adam Miller <admiller@redhat.com> 1.12.2-1
- Merge pull request #3069 from sosiouxme/admin-console-mcollective
  (dmcphers+openshiftbot@redhat.com)
- <container proxy> adjust naming for getting facts (lmeyer@redhat.com)
- <mcollective> adding call to retrieve set of facts for admin-console
  (lmeyer@redhat.com)

* Fri Jul 12 2013 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 31 (admiller@redhat.com)

* Wed Jul 10 2013 Adam Miller <admiller@redhat.com> 1.11.3-1
- mcoll action for getting env vars for a gear (rchopra@redhat.com)

* Tue Jul 02 2013 Adam Miller <admiller@redhat.com> 1.11.2-1
- Handling cleanup of failed pending op using rollbacks (abhgupta@redhat.com)
- Rename migrate to upgrade in code (pmorie@gmail.com)
- Move core migration into origin-server (pmorie@gmail.com)

* Tue Jun 25 2013 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 30 (admiller@redhat.com)

* Tue Jun 18 2013 Adam Miller <admiller@redhat.com> 1.10.3-1
- Bug 972757 (asari.ruby@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- Node timeout handling improvements (ironcladlou@gmail.com)
- Remove any_validator hack. F19 mcollective includes this already.
  (kraman@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Thu May 30 2013 Adam Miller <admiller@redhat.com> 1.8.1-1
- bump_minor_versions for sprint 29 (admiller@redhat.com)

* Thu May 16 2013 Adam Miller <admiller@redhat.com> 1.7.2-1
- Removing code dealing with namespace updates for applications
  (abhgupta@redhat.com)

* Wed May 08 2013 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 28 (admiller@redhat.com)

* Tue Apr 30 2013 Adam Miller <admiller@redhat.com> 1.6.2-1
- Env var WIP. (mrunalp@gmail.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- Splitting configure for cartridges into configure and post-configure
  (abhgupta@redhat.com)
- Creating fixer mechanism for replacing all ssh keys for an app
  (abhgupta@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)
- Adding checks for ssh key matches (abhgupta@redhat.com)

* Mon Apr 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- fixing rebase (tdawson@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1622 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)
- Revert "Merge pull request #1604 from jwhonce/wip/cartridge_repository"
  (dmcphers@redhat.com)
- WIP Cartridge Refactor - Cartridge Repository (jhonce@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Commands and mcollective calls for each FrontendHttpServer API.
  (rmillner@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Fixes for ruby193 (john@ibiblio.org)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.2.2-1
- make Source line uniform among all spec files (tdawson@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.1.2-1
- move chmod to install section instead of files section (tdawson@redhat.com)
- cleanup to fedora standards (tdawson@redhat.com)
- fix source URL (tdawson@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Mon Dec 03 2012 Dan McPherson <dmcphers@redhat.com> 1.0.3-1
- Automatic commit of package [openshift-origin-msg-common] release [1.0.2-1].
  (dmcphers@redhat.com)
- more mco 2.2 changes (dmcphers@redhat.com)
- Automatic commit of package [openshift-origin-msg-common] release [1.0.1-1].
  (dmcphers@redhat.com)
- repacking for mco 2.2 (dmcphers@redhat.com)

* Mon Dec 03 2012 Dan McPherson <dmcphers@redhat.com> 1.0.2-1
- more mco 2.2 changes (dmcphers@redhat.com)
- Automatic commit of package [openshift-origin-msg-common] release [1.0.1-1].
  (dmcphers@redhat.com)
- repacking for mco 2.2 (dmcphers@redhat.com)

* Mon Dec 03 2012 Dan McPherson <dmcphers@redhat.com> 1.0.1-1
- new package built with tito

* Mon Dec 3 2012 Dan McPherson <dmcphers@redhat.com> 1.0.0-1
- Initial commit
