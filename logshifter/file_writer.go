package main

import (
	"bytes"
	"os"
	"os/user"
	"path"
	"strings"
)

const (
	NL = "\n"
)

// FileWriter writes messages to file named tag.
// FileWriter implements the Writer interface.
// FileWriter is configured using a Config instance.
type FileWriter struct {
	config *Config
	file   *os.File
	tag    string
}

// Init implements the Writer interface.
//
// The destination filename is constructed by joining config.fileWriterDir
// with tag and appending a '.log' suffix.
//
// A leading `~/` in config.fileWriterDir will be replaced by the
// current user's home directory path.
//
// An error is returned if the destination file can't be opened.
func (writer *FileWriter) Init() error {
	basedir := writer.config.fileWriterDir

	usr, _ := user.Current()
	dir := usr.HomeDir
	if basedir[:2] == "~/" {
		basedir = strings.Replace(basedir, "~/", (dir + "/"), 1)
	}

	filename := path.Join(basedir, writer.tag+".log")

	f, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return err
	}

	writer.file = f
	return nil
}

// Close implements the Writer interface.
func (writer *FileWriter) Close() error {
	return writer.file.Close()
}

// Write implements the Writer interface.
//
// If the length of b > config.fileBufferSize, the message is broken
// up and its chunks are written sequentially inline within the single
// call to Write.
func (writer *FileWriter) Write(b []byte) (n int, err error) {
	if len(b) > writer.config.fileBufferSize {
		// Break up messages that exceed the downstream buffer length,
		// using a bytes.Buffer since it's easy. This may result in an
		// undesirable amount of allocations, but the assumption is that
		// bursts of too-long messages are rare.
		buf := bytes.NewBuffer(b)
		for buf.Len() > 0 {
			writer.file.Write(buf.Next(writer.config.fileBufferSize))
			writer.file.Write([]byte(NL))
		}
	} else {
		writer.file.Write(b)
		writer.file.Write([]byte(NL))
	}

	return len(b), nil
}
