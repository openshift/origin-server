Summary:        Plugin to enable m-collective communication over amqp 1.0 enabled broker
Name:           mcollective-qpid-plugin
Version: 0.2.2
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

