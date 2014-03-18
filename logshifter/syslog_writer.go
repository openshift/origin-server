package main

import (
	"bytes"
	"log/syslog"
)

// SyslogWriter writes messages to Syslog.
// SyslogWriter implements the Writer interface.
//
// All messages are written at the LOG_INFO priority, with a program
// name equal to tag.
type SyslogWriter struct {
	bufferSize int
	tag        string
	logger     *syslog.Writer
}

// Init implements the Writer interface.
func (writer *SyslogWriter) Init() error {
	logger, err := syslog.New(syslog.LOG_INFO, writer.tag)

	if err != nil {
		return err
	}

	writer.logger = logger

	return nil
}

// Close implements the Writer interface.
func (writer *SyslogWriter) Close() error {
	return writer.logger.Close()
}

// Write implements the Writer interface.
//
// If the length of b > bufferSize, the message is broken
// up and its chunks are written sequentially inline within the single
// call to Write.
func (writer *SyslogWriter) Write(b []byte) (n int, err error) {
	if len(b) > writer.bufferSize {
		// Break up messages that exceed the downstream buffer length,
		// using a bytes.Buffer since it's easy. This may result in an
		// undesirable amount of allocations, but the assumption is that
		// bursts of too-long messages are rare.
		buf := bytes.NewBuffer(b)
		for buf.Len() > 0 {
			writer.logger.Write(buf.Next(writer.bufferSize))
		}

		return len(b), nil
	} else {
		return writer.logger.Write(b)
	}
}
