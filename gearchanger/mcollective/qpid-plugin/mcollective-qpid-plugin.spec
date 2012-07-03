Summary:        Plugin to enable m-collective communication over amqp 1.0 enabled broker
Name:           mcollective-qpid-plugin
Version:        0.0.2
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
cp src/qpid.rb %{buildroot}/usr/libexec/mcollective/mcollective/connector/

%files
%defattr(-,root,root,-)
/usr/libexec/mcollective/mcollective/connector/qpid.rb

%changelog
* Tue Jul 03 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Automatic commit of package [mcollective-qpid-plugin] release [0.0.1-1].
  (kraman@gmail.com)
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

