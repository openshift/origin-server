# @markup markdown
# @title Building OpenShift Origin RPMS from source

# Building OpenShift Origin RPMS from source


This guide will walk you through retrieving the OpenShift Origin source from GitHub and build local copies of the Origin RPMS.

OpenShift Origin requires a Fedora 18, or RHEL 6.4 compatible system to build these packages. You should start with a minimal installation to perform the build.

##OpenShift Origin Repositories

OpenShift Origin sources are arranged into 5 repositories:

* [origin-dev-tools](http://github.com/openshift/origin-dev-tools): This repository contains all the build tools necessary for building and testing a local or EC2 OpenShift Origin installation.
* [origin-server](http://github.com/openshift/origin-server):This is the main repository that contains the source code for the Broker, Node and various plugins for DNS, Communication and Authentication. It also contains some of the core cartridges used by OpenShift installations.
* [origin-community-cartridges](http://github.com/openshift/origin-community-cartridges): This repository contains additional cartridges used during the Fedora 18 installation.
* [rhc](http://github.com/openshift/rhc): This repository contains command line tools used to access an OpenShift based PaaS.
* [puppet-openshift_origin](http://github.com/openshift/puppet-openshift_origin): This repository contains puppet scripts for configuring OpenShift Origin.

## Build Requirements

1. Install basic dependencies (Requires root to install RPMs)

        yum install -y rubygem-thor git tito yum-plugin-priorities wget vim-enhanced \
          ruby-devel rubygems-devel rubygem-aws-sdk rubygem-parseconfig rubygem-yard rubygem-redcarpet \
          createrepo

2. Clone the openshift-dev-tools repository

        git clone git://github.com/openshift/origin-dev-tools.git
    
3. Clone the OpenShift Origin sources

        # From origin-dev-tools's checkout
        export SKIP_SETUP=1
        ./build/devenv clone_addtl_repos master

4. Install package requirements (Requires root to install RPMs)

        # From origin-dev-tools's checkout
        # This step will install a lot of RPMs and will take a while
        ./build/devenv install_required_packages

5. Build RPMs (Requires root to install RPMs)

        # From origin-dev-tools's checkout
        ./build/devenv local-build --skip-install

    RPMs will be available in `origin-rpms` directory.

6. Create RPM metadata so that the directory can be accessed as a YUM repository

        # From the origin-rpms directory
        createrepo .