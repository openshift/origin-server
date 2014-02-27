package main

import (
	"bufio"
	"io"
	"sync"
	"time"
)

// Input consumes newline delimited byte arrays from reader (buffering up
// to bufferSize) and places the bytes on queue in a nonblocking fashion.
//
// If statsChannel is supplied to the Input, the following Stats will
// be placed on the channel:
//
//   input.read => number of messages processed during a Read call
//   input.drop => number of messages dropped from queue during a Read call
//   input.read.duration => time taken to process a line from reader (micros)
type Input struct {
	bufferSize   int
	reader       io.Reader
	queue        chan []byte
	statsChannel chan Stat
}

// Read consumes lines from reader and writes to queue. If queue is unavailable for
// writing (i.e. the channel is full), Read pops and drops an entry from queue to make
// room in order to maintain stable consumption rate from reader.
//
// Signals to a WaitGroup when there's nothing left to read from reader.
func (input *Input) Read() *sync.WaitGroup {
	wg := &sync.WaitGroup{}
	wg.Add(1)

	go func(wg *sync.WaitGroup) {
		input.read()
		wg.Done()
	}(wg)

	return wg
}

// Private synchronous portion of Read.
func (input *Input) read() {
	reader := bufio.NewReaderSize(input.reader, input.bufferSize)

	for {
		line, _, err := reader.ReadLine()

		var start time.Time
		if input.statsChannel != nil {
			start = time.Now()
		}

		if err != nil {
			break
		}

		if len(line) == 0 {
			continue
		}

		cp := make([]byte, len(line))

		copy(cp, line)

		if input.statsChannel != nil {
			input.statsChannel <- Stat{name: "input.read", value: 1.0}
		}

		select {
		case input.queue <- cp:
			// queued
		default:
			// evict the oldest entry to make room
			<-input.queue
			if input.statsChannel != nil {
				input.statsChannel <- Stat{name: "input.drop", value: 1.0}
			}
			input.queue <- cp
		}

		if input.statsChannel != nil {
			input.statsChannel <- Stat{name: "input.read.duration", value: float64(time.Now().Sub(start).Nanoseconds()) / float64(1000)}
		}
	}
}
