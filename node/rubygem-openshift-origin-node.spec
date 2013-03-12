%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-node
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%global apprundir %{_var}/run/openshift
%if 0%{?fedora} >= 18
    %global httxt2dbm /usr/bin/httxt2dbm
%else
    %global httxt2dbm /usr/sbin/httxt2dbm
%endif

Summary:       Cloud Development Node
Name:          rubygem-%{gem_name}
Version: 1.6.1
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
Requires:      %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
Requires:      %{?scl:%scl_prefix}rubygem(mocha)
Requires:      %{?scl:%scl_prefix}rubygem(rspec)
Requires:      rubygem(openshift-origin-common)
Requires:      python
Requires:      libselinux-python
Requires:      mercurial
Requires:      httpd
%if 0%{?fedora}%{?rhel} <= 6
Requires:      libcgroup
%else
Requires:      libcgroup-tools
%endif
%if 0%{?fedora} >= 18
Requires:      httpd-tools
BuildRequires: httpd-tools
%endif
Requires:      libcgroup-pam
Requires:      pam_openshift
Requires:      quota

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
BuildRequires: httpd
%endif
BuildRequires: %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires: %{?scl:%scl_prefix}ruby 
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch
Provides:      rubygem(%{gem_name}) = %version
Obsoletes: 	   rubygem-stickshift-node

%description
This contains the Cloud Development Node packaged as a rubygem.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir .%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/etc/httpd/conf.d
mkdir -p %{buildroot}%{appdir}/.httpd.d
ln -sf %{appdir}/.httpd.d %{buildroot}/etc/httpd/conf.d/openshift

# Create empty route database files
for map in nodes aliases idler sts
do
    mapf="%{buildroot}%{appdir}/.httpd.d/${map}"
    touch "${mapf}.txt"
    %{httxt2dbm} -f DB -i "${mapf}.txt" -o "${mapf}.db"
done

for map in routes
do
    mapf="%{buildroot}%{appdir}/.httpd.d/${map}"
    echo '{}' > "${mapf}.json"
done


# Move the gem configs to the standard filesystem location
mkdir -p %{buildroot}/etc/openshift
mv %{buildroot}%{gem_instdir}/conf/* %{buildroot}/etc/openshift

#move pam limit binaries to proper location
mkdir -p %{buildroot}/usr/libexec/openshift/lib
mv %{buildroot}%{gem_instdir}/misc/lib/teardown_pam_fs_limits.sh %{buildroot}/usr/libexec/openshift/lib
mv %{buildroot}%{gem_instdir}/misc/lib/setup_pam_fs_limits.sh %{buildroot}/usr/libexec/openshift/lib

#move the shell binaries into proper location
mv %{buildroot}%{gem_instdir}/misc/bin/* %{buildroot}/usr/bin/
mv %{buildroot}%{gem_instdir}/misc/sbin/* %{buildroot}/usr/sbin/

# Create run dir for openshift "services"
%if 0%{?fedora} >= 15
mkdir -p %{buildroot}/etc/tmpfiles.d
mv %{buildroot}%{gem_instdir}/misc/etc/openshift-run.conf %{buildroot}/etc/tmpfiles.d
%endif
mkdir -p %{buildroot}%{apprundir}

# place an example file
mkdir -p %{buildroot}%{_docdir}/%{name}-%{version}/
mv %{buildroot}%{gem_instdir}/misc/doc/cgconfig.conf %{buildroot}%{_docdir}/%{name}-%{version}/cgconfig.conf

%if 0%{?fedora} >= 18
  #patch for apache 2.4
  sed -i 's/include /IncludeOptional /g' httpd/000001_openshift_origin_node.conf
  sed -i 's/^RewriteLog/#RewriteLog/g' httpd/openshift_route.include
  sed -i 's/^RewriteLogLevel/#RewriteLogLevel/g' httpd/openshift_route.include
  sed -i 's/^#LogLevel/LogLevel/g' httpd/openshift_route.include
%endif
mv httpd/000001_openshift_origin_node.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/000001_openshift_origin_node_servername.conf %{buildroot}/etc/httpd/conf.d/
mv httpd/openshift_route.include %{buildroot}/etc/httpd/conf.d/

#%if 0%{?fedora}%{?rhel} <= 6
mkdir -p %{buildroot}/etc/rc.d/init.d/
cp %{buildroot}%{gem_instdir}/misc/init/openshift-cgroups %{buildroot}/etc/rc.d/init.d/
#%else
#mkdir -p %{buildroot}/etc/systemd/system
#mv %{buildroot}%{gem_instdir}/misc/services/openshift-cgroups.service %{buildroot}/etc/systemd/system/openshift-cgroups.service
#%endif

# Don't install or package what's left in the misc directory
rm -rf %{buildroot}%{gem_instdir}/misc

%files
%doc LICENSE COPYRIGHT
%doc %{gem_docdir}
%{gem_instdir}
%{gem_cache}
%{gem_spec}
%attr(0750,-,-) /usr/sbin/*
%attr(0755,-,-) /usr/bin/*
/etc/openshift
/usr/libexec/openshift/lib/setup_pam_fs_limits.sh
/usr/libexec/openshift/lib/teardown_pam_fs_limits.sh
%config(noreplace) /etc/openshift/node.conf
%attr(0750,-,-) /etc/httpd/conf.d/openshift
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node.conf
%config(noreplace) /etc/httpd/conf.d/000001_openshift_origin_node_servername.conf
%config(noreplace) /etc/httpd/conf.d/openshift_route.include
%attr(0755,-,-) %{appdir}
%attr(0750,root,apache) %{appdir}/.httpd.d
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/routes.json
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/nodes.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/aliases.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/idler.txt
%attr(0640,root,apache) %config(noreplace) %{appdir}/.httpd.d/sts.txt
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/nodes.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/aliases.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/idler.db
%attr(0750,root,apache) %config(noreplace) %{appdir}/.httpd.d/sts.db

#%if 0%{?fedora}%{?rhel} <= 6
%attr(0755,-,-)	/etc/rc.d/init.d/openshift-cgroups
#%else
#%attr(0750,-,-) /etc/systemd/system
#%endif

%if 0%{?fedora} >= 15
/etc/tmpfiles.d/openshift-run.conf
%endif
# upstart files
%attr(0755,-,-) %{_var}/run/openshift

%post
echo "/usr/bin/oo-trap-user" >> /etc/shells

# Enable cgroups on ssh logins
if [ -f /etc/pam.d/sshd ] ; then
   if ! grep pam_cgroup.so /etc/pam.d/sshd > /dev/null ; then
     echo "session    optional     pam_cgroup.so" >> /etc/pam.d/sshd
   else
     logger -t rpm-post "pam_cgroup.so is already enabled for sshd"
   fi
else
   logger -t rpm-post "cannot add pam_cgroup.so to /etc/pamd./sshd: file not found"
fi

# copying this file in the post hook so that this file can be replaced by rhc-node
# copy this file only if it doesn't already exist
if ! [ -f /etc/openshift/resource_limits.conf ]; then
  cp -f /etc/openshift/resource_limits.template /etc/openshift/resource_limits.conf
fi


%preun
# disable cgroups on sshd logins
sed -i -e '/pam_cgroup/d' /etc/pam.d/sshd

%changelog
* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.6.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 1.5.15-1
- Merge pull request #1578 from ironcladlou/endpoint_ex_handling
  (dmcphers+openshiftbot@redhat.com)
- Bug 919161: Fix Python 3.3 Endpoint entry (ironcladlou@gmail.com)
- Bug 918888 - Had the wrong exit status. (rmillner@redhat.com)
- Merge pull request #1575 from pmorie/dev/uu
  (dmcphers+openshiftbot@redhat.com)
- Fix destroyed gear check in UnixUser#destroy (pmorie@gmail.com)
- Merge pull request #1570 from rmillner/post_stage
  (dmcphers+openshiftbot@redhat.com)
- Bug 901866 - Put training wheels on the rm command. (rmillner@redhat.com)

* Wed Mar 06 2013 Adam Miller <admiller@redhat.com> 1.5.14-1
- BZ873896 - [ORIGIN] 000001_openshift_origin_node.conf not included in
  gemspec, but is in tar.gz (calfonso@redhat.com)
- be sure you dont cache an empty list (dmcphers@redhat.com)
- Bug 918480 (dmcphers@redhat.com)
- Bug 917990 - Multiple fixes. (rmillner@redhat.com)
- Merge pull request #1548 from markllama/dev/cgroup_freezethaw
  (dmcphers+openshiftbot@redhat.com)
- fixed missing case end and cgset syntax (mlamouri@redhat.com)
- added cgset freeze|thaw user (markllama@gmail.com)

* Tue Mar 05 2013 Adam Miller <admiller@redhat.com> 1.5.13-1
- Merge pull request #1545 from pmorie/dev/v2_get_cart (dmcphers@redhat.com)
- Bug 917163 (dmcphers@redhat.com)
- Make v2 get_cartridge use instance dir instead of system path
  (pmorie@gmail.com)
- Merge pull request #1531 from jwhonce/bug/916958 (dmcphers@redhat.com)
- Bug 916958, Bug 917513 - V1 Model not honoring Broker contract
  (jhonce@redhat.com)

* Mon Mar 04 2013 Adam Miller <admiller@redhat.com> 1.5.12-1
- WIP Cartridge Refactor - improve robustness of oo_spawn (jhonce@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.11-1
- remove chown/chmod, errors in mock with Operation Not Permitted, %%files
  section should satisfy this (admiller@redhat.com)
- fixing BuildRequires (admiller@redhat.com)

* Fri Mar 01 2013 Adam Miller <admiller@redhat.com> 1.5.10-1
- Bug 912215 - Workaround broken SELinux policy. (rmillner@redhat.com)
- Bug 916839 - The apache user cannot read through /etc/httpd/conf.d on
  STG/INT/PROD for security reasons. (rmillner@redhat.com)
- Merge pull request #1506 from pmorie/dev/cartridge_refactor
  (dmcphers+openshiftbot@redhat.com)
- Add simple v2 app builds (pmorie@gmail.com)
- WIP Cartridge Refactor - Add OPENSHIFT_{CartridgeShortName}_DIR
  (jhonce@redhat.com)
- Remove parsing version from cartridge-name (pmorie@gmail.com)
- Bug 916917 - uninitialized constant ApplicationState (jhonce@redhat.com)
- Merge pull request #1497 from jwhonce/wip/master_unix_user
  (dmcphers@redhat.com)
- Strip out malformed entries. (rmillner@redhat.com)
- Move the blank route files out of %%post. (rmillner@redhat.com)
- WIP Cartridge Refactor - Remove oo_spawn use from v1 path (jhonce@redhat.com)
- Use sync IO for the logger file (ironcladlou@gmail.com)

* Thu Feb 28 2013 Adam Miller <admiller@redhat.com> 1.5.9-1
- Merge pull request #1486 from lnader/revert_pull_request_1
  (dmcphers@redhat.com)
- reverted US2448 (lnader@redhat.com)
- Bug 901424 - Hide the mco command. (rmillner@redhat.com)
- Bug 901743 - Add the various other commonly used TMP variables.
  (rmillner@redhat.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.8-1
- Merge pull request #1477 from ironcladlou/dev/cartridge_refactor
  (dmcphers@redhat.com)
- WIP Cartridge Refactor (pmorie@gmail.com)
- WIP Cartridge Refactor (pmorie@gmail.com)

* Wed Feb 27 2013 Adam Miller <admiller@redhat.com> 1.5.7-1
- US2448 (lnader@redhat.com)
- Merge pull request #1465 from rmillner/BZ912238
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1462 from rmillner/BZ915471
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1459 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Bug 912238 - The last rescue was catching exit. (rmillner@redhat.com)
- Bug 915471 - The set_selinux_context function was being used in the wrong
  place. (rmillner@redhat.com)
- WIP Cartridge Refactor - Update cartridge author's guide (jhonce@redhat.com)
- Use an openshift specific log for last_access. (rmillner@redhat.com)
- Fix X-Client-IP. (rmillner@redhat.com)

* Tue Feb 26 2013 Adam Miller <admiller@redhat.com> 1.5.6-1
- Turn route logging off. (rmillner@redhat.com)
- Fetch returns KeyError. (rmillner@redhat.com)
- Bug 913351 - Cannot create application successfully when district is added
  (jhonce@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.5-2
- bump Release for fixed build target rebuild (admiller@redhat.com)

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.5.5-1
- fix typo (dmcphers@redhat.com)
- Bug 913423 - Incorrect syntax for ReverseCookiePath, and the way the node
  table lookup works we do not have the information broken out in a way that
  supports the correct syntax. (rmillner@redhat.com)
- Use File.chown/chmod. (rmillner@redhat.com)
- Merge pull request #1429 from jwhonce/dev/wip_master
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1420 from kraman/master
  (dmcphers+openshiftbot@redhat.com)
- Bug 913288 - Numeric login effected additional commands (jhonce@redhat.com)
- Removing references to cgconfig/all (kraman@gmail.com)

* Wed Feb 20 2013 Adam Miller <admiller@redhat.com> 1.5.4-1
- Merge pull request #1417 from jwhonce/dev/wip_master
  (dmcphers+openshiftbot@redhat.com)
- Bug 912899 - mcollective changing all numeric mongoid to BigInt
  (jhonce@redhat.com)
- Allow for a __default__ target which matches hosts not otherwise matched.
  (rmillner@redhat.com)
- Fix permissions for db files. (rmillner@redhat.com)
- Merge pull request #1409 from tdawson/tdawson/fix_rubygem_sources
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1408 from jwhonce/format_markers
  (dmcphers+openshiftbot@redhat.com)
- fix rubygem sources (tdawson@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Fixing sed script for F18 config updates (kraman@gmail.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 1.5.3-1
- Merge pull request #1405 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1379 from markllama/bugs/cgroup-start
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1376 from markllama/bug/oo-cgroup-read
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1404 from kraman/master
  (dmcphers+openshiftbot@redhat.com)
- Fedora 18 moved the httxt2dbm command. (rmillner@redhat.com)
- Fixing sed expression which transforms 000001_openshift_origin_node.conf for
  Apache 2.4 Revert "Adding path to resolve useradd"   This reverts commit
  31d41d77df658b1bb134a9d2cba7cd8ee28cfe64. (kraman@gmail.com)
- Commands and mcollective calls for each FrontendHttpServer API.
  (rmillner@redhat.com)
- Bug 912215: Use oo-ruby for interpreter (ironcladlou@gmail.com)
- Merge pull request #1391 from rmillner/US3143
  (dmcphers+openshiftbot@redhat.com)
- Switch from VirtualHosts to mod_rewrite based routing to support high
  density. (rmillner@redhat.com)
- Add existing community carts to v1 cart list (kraman@gmail.com)
- Adding path to resolve useradd (kraman@gmail.com)
- add check for systemd based os (markllama@gmail.com)
- Merge pull request #1387 from jwhonce/dev/threaddump
  (dmcphers+openshiftbot@redhat.com)
- Bug 911956 - Fixed miss-spelled method name (jhonce@redhat.com)
- Bug 906740 - Update error message (jhonce@redhat.com)
- Fixes to get builds and tests running on RHEL: (kraman@gmail.com)
- Fixes for ruby193 (john@ibiblio.org)
- Bug 868427: Fix tidy for v1 carts (ironcladlou@gmail.com)
- open4 is a rubygem (mlamouri@redhat.com)
- remove community pod (dmcphers@redhat.com)
- minor cleanup (dmcphers@redhat.com)
- Patch node coverage file permissions to work with oo_spawn tests
  (jhonce@redhat.com)
- Fix embed.feature (pmorie@gmail.com)
- Initial write-up of pub/sub hooks (mrunal@me.com)
- Refactor agent and proxy, move all v1 code to v1 model
  (ironcladlou@gmail.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- WIP Cartridge Refactor (jhonce@redhat.com)
- Bug [906687] - Lacking usage info of oo-cgroup-read command
  (mlamouri@redhat.com)
- remove use of filesystem cgroup countrol (mlamouri@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 1.5.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 1.5.1-1
- Merge pull request #1334 from kraman/f18_fixes
  (dmcphers+openshiftbot@redhat.com)
- Reading hostname from node.conf file instead of relying on localhost
  Splitting test features into common, rhel only and fedora only sections
  (kraman@gmail.com)
- bump_minor_versions for sprint 24 (admiller@redhat.com)
- Fixing init-quota to allow for tabs in fstab file Added entries in abstract
  for php-5.4, perl-5.16 Updated python-2.6,php-5.3,perl-5.10 cart so that it
  wont build on F18 Fixed mongo broker auth Relaxed version requirements for
  acegi-security and commons-codec when generating hashed password for jenkins
  Added Apache 2.4 configs for console on F18 Added httpd 2.4 specific restart
  helper (kraman@gmail.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 1.4.5-1
- remove BuildRoot: (tdawson@redhat.com)
- move rest api tests to functionals (dmcphers@redhat.com)
- make Source line uniform among all spec files (tdawson@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 1.4.4-1
- working on testing coverage (dmcphers@redhat.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 1.4.3-1
- Merge pull request #1255 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> active_capacity/max_active_apps/etc switched to
  gear-based accounting (lmeyer@redhat.com)
- Merge pull request #1238 from sosiouxme/newfacts
  (dmcphers+openshiftbot@redhat.com)
- <facter,resource_limits> reckon by gears (as opposed to git repos), add gear
  status facts (lmeyer@redhat.com)

* Tue Jan 29 2013 Adam Miller <admiller@redhat.com> 1.4.2-1
- Bug 905568: Skip endpoint deletion if no Endpoints in manifest
  (ironcladlou@gmail.com)
- Merge pull request #1231 from ironcladlou/expose-port-fix
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1235 from danmcp/master (dmcphers@redhat.com)
- Merge pull request #1117 from mscherer/fix_better_cgroup_listing
  (dmcphers+openshiftbot@redhat.com)
- Bug 874594 Bug 888550 (dmcphers@redhat.com)
- Bug 904100: Tolerate missing Endpoint cart manifest entries
  (ironcladlou@gmail.com)
- BZ896406 - warning message when installing rubygem-openshift-origin-node
  (bleanhar@redhat.com)
- BZ876324 resolve ServerName/NameVirtualHost situation for
  node/broker/ssl.conf (lmeyer@redhat.com)
- Switch calling convention to match US3143 (rmillner@redhat.com)
- adding a dash in the authorized key entry comment to make it more readable
  (abhgupta@redhat.com)
- fix for bug 894948 (abhgupta@redhat.com)
- fix and factorise the function for the list of users as openshift_users do
  not match on the same exact list of people than valid_user ( due to code
  duplication and subtle difference between the copies ) (misc@zarb.org)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.4.1-1
- bump_minor_versions for sprint 23 (admiller@redhat.com)

* Wed Jan 23 2013 Adam Miller <admiller@redhat.com> 1.3.6-1
- Bug 903152: Execute git tidy ops as gear user (ironcladlou@gmail.com)

* Mon Jan 21 2013 Adam Miller <admiller@redhat.com> 1.3.5-1
- BZ 901449: An SELinux issue prevents forces this script to use system ruby
  and not the SCL version. (rmillner@redhat.com)

* Fri Jan 18 2013 Dan McPherson <dmcphers@redhat.com> 1.3.4-1
- Bug 901444 (dmcphers@redhat.com)
- SSL support for custom domains. (mpatel@redhat.com)
- Replace expose/show/conceal-port hooks with Endpoints (ironcladlou@gmail.com)

* Mon Jan 14 2013 Adam Miller <admiller@redhat.com> 1.3.3-1
- Fix BZ875200: Add statements to rhcsh ctl_all (pmorie@gmail.com)
- Merge pull request #1141 from pmorie/bugs/877306
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1140 from pmorie/bugs/877305
  (dmcphers+openshiftbot@redhat.com)
- Fix usage for oo-admin-ctl-cgroups (pmorie@gmail.com)
- Add newline to each user for oo-admin-ctl-cgroups stopall (pmorie@gmail.com)

* Thu Jan 10 2013 Adam Miller <admiller@redhat.com> 1.3.2-1
- Merge pull request #1120 from sosiouxme/BZ876324
  (dmcphers+openshiftbot@redhat.com)
- BZ876324 resolve ServerName/NameVirtualHost situation for
  node/broker/ssl.conf (lmeyer@redhat.com)
- Update rhc command usage. Addresses BZ889018. (asari.ruby@gmail.com)
- Typo. (rmillner@redhat.com)
- BZ 888410: The reader sequence can block if there is too much stderr
  (rmillner@redhat.com)

* Wed Dec 12 2012 Adam Miller <admiller@redhat.com> 1.3.1-1
- bump_minor_versions for sprint 22 (admiller@redhat.com)

* Mon Dec 10 2012 Adam Miller <admiller@redhat.com> 1.2.6-1
- Merge pull request #1007 from sosiouxme/US3036-origin
  (openshift+bot@redhat.com)
- Adding oo-accept-systems script for verifying all node hosts from the broker.
  - also verifies cartridge consistency and checks for stale cartridge cache.
  oo-accept-node sanity checks public_ip and public_hostname. Minor edits to
  make node.conf easier to understand. (lmeyer@redhat.com)
- Fix tests.  The file mock was not working. (rmillner@redhat.com)
- Post rebase code cleanup. (rmillner@redhat.com)
- Proper host name validation. (rmillner@redhat.com)

* Thu Dec 06 2012 Adam Miller <admiller@redhat.com> 1.2.5-1
- bug 884409 (dmcphers@redhat.com)
- Merge pull request #1023 from ramr/dev/websockets (openshift+bot@redhat.com)
- Fix frontend httpd tests. (ramr@redhat.com)
- Node web sockets and http(s) proxy support with spec file and package.
  (ramr@redhat.com)

* Wed Dec 05 2012 Adam Miller <admiller@redhat.com> 1.2.4-1
- Fix for Bug 883605 (jhonce@redhat.com)
- updated gemspecs so they work with scl rpm spec files. (tdawson@redhat.com)

* Tue Dec 04 2012 Adam Miller <admiller@redhat.com> 1.2.3-1
- Merge pull request #1005 from ironcladlou/US2770 (openshift+bot@redhat.com)
- Refactor tidy into the node library (ironcladlou@gmail.com)
- Bug Fixes. (rmillner@redhat.com)
- Move add/remove alias to the node API. (rmillner@redhat.com)

* Thu Nov 29 2012 Adam Miller <admiller@redhat.com> 1.2.2-1
- Move force-stop into the the node library (ironcladlou@gmail.com)
- exit code and usage cleanup (dmcphers@redhat.com)
- Merge pull request #962 from danmcp/master (openshift+bot@redhat.com)
- Merge pull request #905 from kraman/ruby19 (openshift+bot@redhat.com)
- add oo-ruby (dmcphers@redhat.com)
- F18 compatibility fixes   - apache 2.4   - mongo journaling   - JDK 7   -
  parseconfig gem update Bugfix for Bind DNS plugin (kraman@gmail.com)

* Sat Nov 17 2012 Adam Miller <admiller@redhat.com> 1.2.1-1
- bump_minor_versions for sprint 21 (admiller@redhat.com)

* Thu Nov 15 2012 Adam Miller <admiller@redhat.com> 1.1.7-1
- BZ877125 - File attributes on open shift-cgroups init script are incorrect,
  should be -rwxr-x--- (calfonso@redhat.com)
- more ruby1.9 changes (dmcphers@redhat.com)

* Wed Nov 14 2012 Adam Miller <admiller@redhat.com> 1.1.6-1
- Ruby 1.9 compatibility fixes (ironcladlou@gmail.com)
- getting specs up to 1.9 sclized (dmcphers@redhat.com)
- Merge pull request #886 from rmillner/inhibitidler (dmcphers@redhat.com)
- One of the SELinux denials was accessing the locale file via whois which is
  unnecessary if accessing /etc directly. (rmillner@redhat.com)
- specifying rake gem version range (abhgupta@redhat.com)

* Tue Nov 13 2012 Adam Miller <admiller@redhat.com> 1.1.5-1
- Merge remote-tracking branch 'origin-server/master' into BZ874587-origin
  (bleanhar@redhat.com)
- Merge pull request #881 from rmillner/wrongmcs (openshift+bot@redhat.com)
- SS -> OPENSHIFT (dmcphers@redhat.com)
- Was setting mcs label in the wrong place. (rmillner@redhat.com)
- Fix for Bug 875949 (jhonce@redhat.com)
- Bug 874587 - CLOUD_NAME in /etc/openshift/node.conf does not work
  (bleanhar@redhat.com)

* Mon Nov 12 2012 Adam Miller <admiller@redhat.com> 1.1.4-1
- BZ 872379: Dead code cleanup to fix mount parsing problem.
  (rmillner@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.3-1
- Merge pull request #857 from jwhonce/dev/bz874712_master
  (openshift+bot@redhat.com)
- Fix for Bug 874712 (jhonce@redhat.com)

* Thu Nov 08 2012 Adam Miller <admiller@redhat.com> 1.1.2-1
- Merge pull request #851 from brenton/no_trace (openshift+bot@redhat.com)
- BZ873970, BZ873966 - disabling HTTP TRACE for the Broker, Nodes and Console
  (bleanhar@redhat.com)
- Increase the table sizes to cover 15000 nodes in dev and prod.
  (rmillner@redhat.com)
- BZ872523 - set quota for gear failed if the device name is too long
  (bleanhar@redhat.com)
- Merge pull request #698 from mscherer/fix_doc_node_bin
  (openshift+bot@redhat.com)
- do not use old name in the script help message (mscherer@redhat.com)

* Thu Nov 01 2012 Adam Miller <admiller@redhat.com> 1.1.1-1
- bump_minor_versions for sprint 20 (admiller@redhat.com)
