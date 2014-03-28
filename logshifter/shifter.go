package main

import (
	"errors"
	"fmt"
	"io"
)

// Shifter represents a buffered log pipe.
//
// Shifter will coordinate the configuration, startup and shutdown of an
// Input and Output which pass log message byte arrays over a channel.
//
// Input is backed by inputReader, and Output is backed by outputWriter.
type Shifter struct {
	queueSize       int
	inputBufferSize int // used to configure inputReader
	inputReader     io.Reader
	outputWriter    Writer
	statsChannel    chan Stat // passed to Input and Output
	input           *Input
	output          *Output
}

// Writer is an interface used by Shifter.
// Writer extends io.Writer to add Init and Close functions.
type Writer interface {
	io.Writer

	// Init sets up the writer and should be called prior to any calls to Write.
	Init() error

	// Close shuts down the writer.
	// After calling Close on a Writer, Init must be called again prior to any
	// further calls to Write.
	Close() error
}

// Stat represents a key-value pair holding a Shifter statistic name and value.
type Stat struct {
	name  string
	value float64
}

// Start starts the log pipe and blocks until both the Input and Output are
// finished according their respective WaitGroups.
//
// An error will be returned if input or output initialization fails.
func (shifter *Shifter) Start() error {
	queue := make(chan []byte, shifter.queueSize)

	shifter.input = &Input{
		bufferSize:   shifter.inputBufferSize,
		reader:       shifter.inputReader,
		queue:        queue,
		statsChannel: shifter.statsChannel,
	}

	shifter.output = &Output{
		writer:       shifter.outputWriter,
		queue:        queue,
		statsChannel: shifter.statsChannel,
	}

	// start writing before reading: there's still a race here, not worth bothering with yet
	writeGroup, err := shifter.output.Write()

	if err != nil {
		return errors.New(fmt.Sprintf("Failed to initialize output writer: %v", err))
	}

	readGroup := shifter.input.Read()

	// wait for the the reader to complete
	readGroup.Wait()

	// shut down the writer by closing the queue
	close(queue)
	writeGroup.Wait()

	shifter.outputWriter.Close()

	return nil
}
