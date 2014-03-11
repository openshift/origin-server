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
type FileWriter struct {
	tag          string
	baseDir      string
	bufferSize   int
	rollDetector RollDetector
	roller       Roller

	file *os.File
}

// RollDetector determines whether it's time to roll a file.
type RollDetector interface {
	// Track gives a RollDetector the opportunity to statefully
	// manage file in order to make roll determinations.
	Track(file *os.File)

	// ShouldRoll only returns true if it's time to roll a file.
	ShouldRoll() bool

	// NotifyWrite is given the number of bytesToWrite prior to
	// an actual Write call to give the RollDetector an opportunity
	// to update any state it may have.
	NotifyWrite(bytesToWrite int)
}

// Roller performs an arbitrary roll action on a file.
type Roller interface {
	// Roll rolls file in some way.
	Roll(file *os.File)
}

// Init implements the Writer interface.
//
// The destination filename is constructed by joining baseDir with
// tag and appending a '.log' suffix.
//
// A leading `~/` in baseDir will be replaced by the current user's
// home directory path.
//
// An error is returned if the destination file can't be opened.
func (writer *FileWriter) Init() error {
	basedir := writer.baseDir

	usr, _ := user.Current()
	dir := usr.HomeDir
	if basedir[:2] == "~/" {
		basedir = strings.Replace(basedir, "~/", (dir + "/"), 1)
	}

	filename := path.Join(basedir, writer.tag+".log")

	// try to open the file
	f, err := os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return err
	}

	writer.file = f

	writer.rollDetector.Track(writer.file)

	return nil
}

// Close implements the Writer interface.
func (writer *FileWriter) Close() error {
	return writer.file.Close()
}

// Write implements the Writer interface.
//
// If the length of b > bufferSize, the message is broken up and its chunks
// are written sequentially inline within the single call to Write.
//
// Rolls are detected and handled prior to the actual write.
func (writer *FileWriter) Write(b []byte) (n int, err error) {
	byteLen := len(b)

	// notify the detector before actually writing to prevent overrunning
	// any implementation specific thresholds which may be set
	writer.rollDetector.NotifyWrite(byteLen)

	if writer.rollDetector.ShouldRoll() {
		writer.roller.Roll(writer.file)
		writer.Init()
	}

	if byteLen > writer.bufferSize {
		// Break up messages that exceed the downstream buffer length,
		// using a bytes.Buffer since it's easy. This may result in an
		// undesirable amount of allocations, but the assumption is that
		// bursts of too-long messages are rare.
		buf := bytes.NewBuffer(b)
		for buf.Len() > 0 {
			writer.file.Write(buf.Next(writer.bufferSize))
			writer.file.Write([]byte(NL))
		}
	} else {
		writer.file.Write(b)
		writer.file.Write([]byte(NL))
	}

	return byteLen, nil
}
