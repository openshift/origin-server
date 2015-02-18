logshifter 1 "September 2014" OpenShift "User Manuals"
=====

NAME
---
logshifter - Log transport for OpenShift gear processes.

SYNOPSIS
---
`logshifter` **-tag** *tagname*

`logshifter` [ **-config** */etc/openshift/logshifter.conf* ] [ **-statsfilename** */tmp/logshifter.stats* ] [ **-statsinterval** *2s*] [ **-verbose** ] **-tag** *tagname*

DESCRIPTION
---
A simple log pipe designed to maintain consistently high input consumption rates, preferring to
drop old messages rather than block the input producer.

The primary design goals are:

* Minimal blocking of the input producer
* Asynchronous dispatch of log events to an output
* Sacrifice delivery rate for input processing consistency
* Fixed maximum memory use as a factor of configurable buffer sizes
* Pluggable and configurable outputs

logshifter is useful for capturing and redirecting output of heterogenous applications which
emit logs to stdout rather than to a downstream aggregator (e.g. syslog) directly.

OPTIONS
---
`-config` *config-file*
  Specify configuration file path, default /etc/openshift/logshifter.conf

`-statsfilename` *stats-file*
  Filename for periodic stats output

`-statsinterval` *2s*
  Interval at which to write stats

`-verbose`
  Enable verbose output

EXAMPLE
---
Here are some small examples to verify logshifter is writing events, using the default configuration
(which writes to syslog):

    # single shot
    echo hello world | logshifter -tag myapp

    # 10 messages @ 1 message/second
    for i in {1..10}; do echo logshifter message ${i}; sleep 1; done | /tmp/logshifter -tag myapp

    # 30 messages @ 1 message/second with stats reporting every 2 seconds
    for i in {1..30}; do echo logshifter message ${i}; sleep 1; done | /tmp/logshifter -tag myapp -statsfilename /tmp/logshifter.stats -statsinterval 2s

CONFIGURATION
---
An optional configuration file can be supplied to logshifter with the `-config` flag. The file
is a list of key value pairs in the format `k = v`, one per line. Keys are case insensitive.

Configuration keys and their default values

   queueSize = 1000             # int    // size of the internal log message queue
   inputBufferSize = 2048       # int    // input up to \n or this number of bytes is considered a line
   outputType = syslog          # string // one of syslog, file, multi (syslog + file)
   syslogBufferSize = 2048      # int    // lines bound for syslog lines are split at this size
   fileBufferSize = 2048        # int    // lines bound for a file are split at this size
   outputTypeFromEnviron = true # bool   // allows outputtype to be overridden via LOGSHIFTER\_OUTPUT\_TYPE

If no `-config` flag is specified, logshifter will attempt to load a global config file from
`/etc/openshift/logshifter.conf`. If no `-config` is specified, and the global config file doesn't
exist, a default syslog-based configuration will be used.

NOTES
---

Rolling Files
----
When using the `file` writer, a simple file rolling behavior is enabled by default. The rolling
mechanism will roll files if the file size exceeds a threshold, and will retain a configurable
number of rolled files before removing the oldest prior to the next roll.

Rolling is configured by the `LOGSHIFTER_$TAG_MAX_FILESIZE` and `LOGSHIFTER_$TAG_MAX_FILES`
environment variables, where `$TAG` is replaced by an uppercase string equal to the value of
the `-tag` argument.

The `LOGSHIFTER_$TAG_MAX_FILESIZE` variable expects a case-insensitive string representing the
maximum size of the file which triggers a roll event. Example values:

    LOGSHIFTER_$TAG_MAX_FILESIZE=500K   # kilobytes
    LOGSHIFTER_$TAG_MAX_FILESIZE=10M    # megabytes
    LOGSHIFTER_$TAG_MAX_FILESIZE=2G     # gigabytes
    LOGSHIFTER_$TAG_MAX_FILESIZE=1T     # terabytes

The default value is `10M`. If a zero size is specified (regardless of the unit), rolling will be
effectively disabled.

The `LOGSHIFTER_$TAG_MAX_FILES` variable is an integer representing the maximum number of log
files to retain. The default is 10.


Statistics
----
Periodic stats can be emitted to a file using the `-statsfilename` argument.  The stats are written
in JSON format on an interval specified by `-statsinterval` (which is a string in a format expected
by the golang [time.ParseDuration](http://golang.org/pkg/time/#ParseDuration) function).

Note that enabling statistics will introduce extra processing overhead.

Building
----
Since logshifter lives inside the origin-server repository, use the `go` tools with a relative
directory. Change your working directory to `origin-server/logshifter`. To test:

    go test -v .

And to build:

    go build -o /tmp/logshifter .

SEE ALSO
----
http://golang.org/pkg/time/#ParseDuration
