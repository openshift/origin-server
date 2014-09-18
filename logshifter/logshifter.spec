%global debug_package   %{nil}
%global __strip /bin/true
%global import_path github.com/openshift

Name:          openshift-origin-logshifter
Version: 1.7.3
Release:       1%{?dist}
Summary:       Log transport for OpenShift gear processes.
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: golang
ExclusiveArch: %{ix86} x86_64 %{arm}

%description
A simple log pipe designed to maintain consistently high input consumption rates, preferring to
drop old messages rather than block the input producer.

%prep
%setup -q

%build
mkdir _build
pushd _build
mkdir -p src/%{import_path}
ln -s $(dirs +1 -l) src/%{import_path}/logshifter
export GOPATH=$(pwd)
go install %{import_path}/logshifter
popd

%install
install -d %{buildroot}%{_bindir}
install -p -m 755 _build/bin/logshifter %{buildroot}%{_bindir}/logshifter
mkdir -p %{buildroot}%{_mandir}/man1/
cp -p man/*.1 %{buildroot}%{_mandir}/man1/


%files
%defattr(-,root,root,-)
%{_bindir}/logshifter
%{_mandir}/man1/*

%changelog
* Tue Sep 09 2014 Adam Miller <admiller@redhat.com> 1.7.3-1
- Merge pull request #5789 from sdodson/logshifter-manpage
  (dmcphers+openshiftbot@redhat.com)
- Add manpage to rpm (sdodson@redhat.com)
- Update README.md and create a man page from that (sdodson@redhat.com)

* Fri Sep 05 2014 Adam Miller <admiller@redhat.com> 1.7.2-1
- Removing the named parameters from Write method. (etsauer@gmail.com)
- Renamed bytes to bufferSize and removed verbose from createSyslogWriter
  (etsauer@gmail.com)
- createSyslogWriter takes int bufferSize instead of entire config
  (etsauer@gmail.com)
- Adding proper commenting to new methods in main (etsauer@gmail.com)
- Added proper commenting to multi writer (etsauer@gmail.com)
- Returning len(b) for Write function (etsauer@gmail.com)
- Changed error handling in various places. (etsauer@gmail.com)
- Close all writers before returning error. Also fixed bug in last commit
  (etsauer@gmail.com)
- Don't want to aggregate bytes here, just returning len(b) for failed writer
  (etsauer@gmail.com)
- Created a multi writer option which logs to both syslog and files
  (etsauer@gmail.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.7.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.6.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.6.0-2
- bumpspec to mass fix tags

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.5.2-1
- BZ1087545 - Fix filename format for rotated logs (agrimm@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.5.1-1
- Redirect streams to /dev/null unless verbose enabled (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.4.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Wed Mar 19 2014 Adam Miller <admiller@redhat.com> 1.4.2-1
- Implement simple log rotation support (ironcladlou@gmail.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.4.1-1
- Append .log to file writer filenames (ironcladlou@gmail.com)
- fix logshifter version number format (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.4-1
- Ignore SIGHUP in logshifter (ironcladlou@gmail.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.3-1
- Add better defaults and documentation (ironcladlou@gmail.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.2-1
- new package built with tito

* Thu Feb 27 2014 Dan Mace <ironcladlou@gmail.com> 1.1-1
- new package built with tito

