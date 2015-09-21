package main

import (
	"bufio"
	"io"
	"os"
	"strconv"
	"strings"
)

// Config represents the global configuration for logshifter.
type Config struct {
	queueSize             int    // size of the internal log message queue
	inputBufferSize       int    // input up to \n or this number of bytes is considered a line
	outputType            string // one of syslog, file, multi (syslog + file)
	syslogBufferSize      int    // lines bound for syslog lines are split at this size
	fileBufferSize        int    // lines bound for a file are split at this size
	fileWriterDir         string // base dir for the file writer output's file
	outputTypeFromEnviron bool   // allows outputtype to be overridden via LOGSHIFTER_OUTPUT_TYPE
}

// DefaultConfig returns a Config with some sane defaults.
func DefaultConfig() *Config {
	return &Config{
		queueSize:             1000,
		inputBufferSize:       2048,
		outputType:            "syslog",
		syslogBufferSize:      2048,
		fileBufferSize:        2048,
		outputTypeFromEnviron: true,
	}
}

const (
	// output types
	Syslog = "syslog"
	File   = "file"
	Multi  = "multi"

	DefaultConfigFile = "/etc/openshift/logshifter.conf"
)

// ParseConfig reads file and constructs a Config from the contents.
//
// The config file format is a simple newline-delimited key=value pair format.
// Config keys within the file correspond to the fields of Config, and the keys
// are case-insensitive.
//
// The values assigned by DefaultConfig are used for any missing config keys.
//
// An error is returned if file is not a valid config file.
func ParseConfig(file string) (*Config, error) {
	config := DefaultConfig()

	f, err := os.Open(file)
	defer f.Close()

	if err != nil {
		return nil, err
	}

	reader := bufio.NewReader(f)

	for {
		line, err := reader.ReadString('\n')
		if (err != nil && err != io.EOF) || len(line) == 0 {
			break
		}

		if line == "\n" {
			continue
		}

		c := strings.SplitN(line, "=", 2)

		if len(c) != 2 {
			break
		}

		k := strings.Trim(c[0], "\n ")
		v := strings.Trim(c[1], "\n ")

		switch strings.ToLower(k) {
		case "queuesize":
			config.queueSize, _ = strconv.Atoi(v)
		case "inputbuffersize":
			config.inputBufferSize, _ = strconv.Atoi(v)
		case "outputtype":
			switch v {
			case "syslog":
				config.outputType = Syslog
			case "file":
				config.outputType = File
			case "multi":
				config.outputType = Multi
			}
		case "syslogbuffersize":
			config.syslogBufferSize, _ = strconv.Atoi(v)
		case "filebuffersize":
			config.fileBufferSize, _ = strconv.Atoi(v)
		case "outputtypefromenviron":
			config.outputTypeFromEnviron, _ = strconv.ParseBool(v)
		case "filewriterdir":
			config.fileWriterDir = v
		}
	}

	return config, nil
}
