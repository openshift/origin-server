%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-container-selinux
%global rubyabi 1.9.1

Summary:       OpenShift plugin for SELinux based containers
Name:          rubygem-%{gem_name}
Version: 0.11.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      rubygem(openshift-origin-node)
Requires:      selinux-policy-targeted
Requires:      policycoreutils-python
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version

%description
Provides a SELinux based container plugin

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p ./%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec
export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift/node-plugins.d
cp %{buildroot}/%{gem_instdir}/conf/openshift-origin-container-selinux.conf.example %{buildroot}/etc/openshift/node-plugins.d/

%files
%doc %{gem_docdir}
%{gem_instdir}
%{gem_spec}
%{gem_cache}
/etc/openshift/node-plugins.d/

%changelog
* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 0.11.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 0.10.2-1
- Bug 1136425 Bug link https://bugzilla.redhat.com/show_bug.cgi?id=1136425
  Disable password aging for gear users (tiwillia@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 0.10.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Fri Jun 13 2014 Adam Miller <admiller@redhat.com> 0.9.3-1
- Merge pull request #5503 from a13m/bz1103849
  (dmcphers+openshiftbot@redhat.com)
- Bug 1103849 - Remove quota for deleted gear by uid (agrimm@redhat.com)

* Mon Jun 09 2014 Adam Miller <admiller@redhat.com> 0.9.2-1
- Merge pull request #5470 from brenton/BZ1064631
  (dmcphers+openshiftbot@redhat.com)
- Bug 1064631 - Wrap UID-based ip addresses and netclasses calculations
  (bleanhar@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 0.9.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 0.8.2-1
- Bug 1101156 - Always initialize container_plugin (jhonce@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 0.8.1-1
- Bug 1075760 - Allow traffic control to be disabled (bleanhar@redhat.com)
- Bug 1081249 - Refactor SELinux module to be SelinuxContext singleton
  (jhonce@redhat.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Mon Mar 17 2014 Troy Dawson <tdawson@redhat.com> 0.7.3-1
- Bug 1067008 - Delete gear when missing a Cartridge Ident (jhonce@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 0.7.2-1
- Bug 1053485 - Changing GID_MIN in login.defs prevents app creation
  (bleanhar@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 0.7.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 0.6.3-1
- Bug 1056426 - last-access info not deleted when gear deleted
  (jhonce@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 0.6.2-1
- Cleaning specs (dmcphers@redhat.com)
- Merge pull request #4616 from brenton/deployment_dir1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4149 from mfojtik/fixes/bundler
  (dmcphers+openshiftbot@redhat.com)
- Bug 1049089 - Speed up selinux labeling usage (jhonce@redhat.com)
- First pass at avoiding deployment dir create on app moves
  (bleanhar@redhat.com)
- Switch to use https in Gemfile to get rid of bundler warning.
  (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 0.6.1-1
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bug 1051833 - PathUtils.flock() not removing lock file (jhonce@redhat.com)

