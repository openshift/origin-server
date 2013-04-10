# OpenShift Ruby Cartridge
This cartridge allows creation of a bare metal
[Rack](http://rack.github.io) application Ruby.

## Environment Variables
The Ruby cartridge defines the following environment variables in
addition to those described in _DOC_:

1. `OPENSHIFT_RUBY_LOGDIR`: Log files go here.
1. `OPENSHIFT_RUBY_VERSION`: The Ruby language version. The valid values are `1.8` and `1.9`.