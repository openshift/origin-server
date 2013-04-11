# How To Write An Application To Host on OpenShift 2.0

OpenShift applications are tightly integrated with Git. The application's Git
repository contains not only the code and configuration for the application, but
also special files which help integrate the application OpenShift itself.

## Action Hooks

OpenShift provides application developers entry points into various application
and platform lifecycle operations. These entry points are referred to as
"action hooks", and have a special location within the application's Git
repository:

`<repository>/.openshift/action_hooks`

During any OpenShift process which supports an action hook, the application 
action hook directory will be checked for an executable file matching the
specified name. If such a file is present, it will be executed before returning
control to the process.

### Cartridge Control Action Hooks

Cartridges implement a standard set of named control actions which allow them to
function within OpenShift. Each time OpenShift invokes one of these cartridge
actions, a standard set of application action hooks are executed to give the
application developer an opportunity to integrate more closely with specific
cartridges.

The following is a list of all possible action hooks executed in association
with a single cartridge control action. For each control action, a set of `pre`
and `post` action hooks surround the control action.

- `start` control action:
  - `pre_start`
  - `pre_start_{cartridge}`
  - `post_start`
  - `post_start_{cartridge}`

- `stop` control action:
  - `pre_stop`
  - `pre_stop_{cartridge}`
  - `post_stop`
  - `post_stop_{cartridge}`

- `reload` control action:
  - `pre_reload`
  - `pre_reload_{cartridge}`
  - `post_reload`
  - `post_reload_{cartridge}`

- `restart` control action:
  - `pre_restart`
  - `pre_restart_{cartridge}`
  - `post_restart`
  - `post_restart_{cartridge}`

- `tidy` control action:
  - `pre_tidy`
  - `pre_tidy_{cartridge}`
  - `post_tidy`
  - `post_tidy_{cartridge}`

For details about the control actions (including what they represent and when
they are called), refer to the [control script documentation](README.writing_cartridges.md#bincontrol)
in the [Writing Cartridges](README.writing_cartridges.md) guide.

### Build Action Hooks

During a Git push, applications using the default OpenShift build lifecycle 
are given an opportunity to participate in the build/deploy workflow via another
set of action hooks. The workflow and sequence of actions for the build lifecycle
is described in detail in the [OpenShift Builds](README.writing_cartridges.md#openshift-builds)
section of the [Writing Cartridges](README.writing_cartridges.md) guide.

The list of action hooks supported during the default build lifecycle are:

- `pre-build`
- `build`
- `deploy`
- `post-deploy`

Refer to the [OpenShift Builds](README.writing_cartridges.md#openshift-builds)
guide for details about when these action hooks are invoked.

### Custom Cartridge Action Hooks

Cartridges may support custom action hooks available to application developers.
Consult the documentation for individual cartridges to learn which hooks are
supported and how to correctly implement them.
