Summary:        Plugin to enable m-collective communication over amqp 1.0 enabled broker
Name:           mcollective-qpid-plugin
Version: 1.1.1
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       mcollective
Requires:       ruby-qpid-qmf
BuildArch:      noarch

%description
m-collective communication plugin for amqp 1.0 enabled qpid broker

%prep
%setup -q

%clean
rm -rf %{buildroot}

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/libexec/mcollective/mcollective/connector/
mkdir -p %{buildroot}/usr/share/doc/mcollective-qpid-plugin
cp src/qpid.rb %{buildroot}/usr/libexec/mcollective/mcollective/connector/
cp COPYRIGHT README.md LICENSE %{buildroot}/usr/share/doc/mcollective-qpid-plugin/

%files
%defattr(-,root,root,-)
/usr/libexec/mcollective/mcollective/connector/qpid.rb
/usr/share/doc/mcollective-qpid-plugin/COPYRIGHT
/usr/share/doc/mcollective-qpid-plugin/README.md
/usr/share/doc/mcollective-qpid-plugin/LICENSE

%changelog
* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- Bumping specs to at least 1.1 (dmcphers@redhat.com)

* Tue Oct 30 2012 Adam Miller <admiller@redhat.com> 1.0.1-1
- bumping specs to at least 1.0.0 (dmcphers@redhat.com)

* Thu Oct 18 2012 Adam Miller <admiller@redhat.com> 0.2.4-1
- Fixed broker/node setup scripts to install cgroup services. Fixed
  mcollective-qpid plugin so it installs during origin package build. Updated
  cgroups init script to work with both systemd and init.d Updated oo-trap-user
  script Renamed oo-cgroups to openshift-cgroups (service and init.d) and
  created oo-admin-ctl-cgroups Pulled in oo-get-mcs-level and abstract/util
  from origin-selinux branch Fixed invalid file path in rubygem-openshift-
  origin-auth-mongo spec Fixed invlaid use fo Mcollective::Config in
  mcollective-qpid-plugin (kraman@gmail.com)

* Mon Oct 15 2012 Adam Miller <admiller@redhat.com> 0.2.3-1
- Centralize plug-in configuration (miciah.masters@gmail.com)

* Fri Oct 05 2012 Krishna Raman <kraman@gmail.com> 0.2.2-1
- Rename pass 3: Manual fixes (kraman@gmail.com)
- Rename pass 2: variables, modules, classes (kraman@gmail.com)
- Rename pass 1: files, directories (kraman@gmail.com)

* Thu Aug 02 2012 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 16 (admiller@redhat.com)

* Mon Jul 30 2012 Dan McPherson <dmcphers@redhat.com> 0.1.3-1
- Adding license files (kraman@gmail.com)

* Thu Jul 19 2012 Adam Miller <admiller@redhat.com> 0.1.2-1
- test case reorg (dmcphers@redhat.com)

* Wed Jul 11 2012 Adam Miller <admiller@redhat.com> 0.1.1-1
- bump_minor_versions for sprint 15 (admiller@redhat.com)

* Mon Jul 09 2012 Dan McPherson <dmcphers@redhat.com> 0.0.3-1
- Fix for BZ 838000. (mpatel@redhat.com)

* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Automatic commit of package [mcollective-qpid-plugin] release [0.0.1-1].
  (kraman@gmail.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  msg-broker plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

