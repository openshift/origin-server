%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global mco_root /opt/rh/ruby193/root/usr/libexec/mcollective/mcollective/
%else
    %global mco_root /usr/libexec/mcollective/mcollective/
%endif

Summary:       Common dependencies of the msg components for OpenShift server and node
Name:          openshift-origin-msg-common
Version:       1.3.2
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}mcollective-common
BuildArch:     noarch

%description
Provides the common dependencies of the msg components for OpenShift server and node

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{mco_root}agent
mkdir -p %{buildroot}%{mco_root}validator
cp -p agent/* %{buildroot}%{mco_root}agent/
cp -p validator/* %{buildroot}%{mco_root}validator/
chmod 644 %{buildroot}%{mco_root}agent/*
chmod 644 %{buildroot}%{mco_root}validator/*

%files
%{mco_root}agent/*
%{mco_root}validator/*

%changelog
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
