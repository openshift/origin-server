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
//   input.queue => number of messages queued during a Read call
//   input.drop => number of new messages dropped during a Read call
//   input.evict => number of old messages evicted from the queue during a Read call
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

func (input *Input) record(name string, val float64) {
	if input.statsChannel != nil {
		input.statsChannel <- Stat{name: name, value: val}
	}
}

// Private synchronous portion of Read.
func (input *Input) read() {
	reader := bufio.NewReaderSize(input.reader, input.bufferSize)

	for {
		line, _, err := reader.ReadLine()

		start := time.Now()

		if err != nil {
			break
		}

		if len(line) == 0 {
			continue
		}

		cp := make([]byte, len(line))

		copy(cp, line)

		input.record("input.read", 1.0)

		select {
		case input.queue <- cp:
			// queued
			input.record("input.queue", 1.0)
		default:
			// try to evict the oldest entry to make room
			select {
			case <-input.queue:
				input.record("input.evict", 1.0)
				// try again to queue
				select {
				case input.queue <- cp:
					// queued
					input.record("input.queue", 1.0)
				default:
					// no room, drop it
					input.record("input.drop", 1.0)
				}
			default:
				// queue is already empty, try to queue
				select {
				case input.queue <- cp:
					// queued
					input.record("input.queue", 1.0)
				default:
					// no room, drop it
					input.record("input.drop", 1.0)
				}
			}
		}

		input.record("input.read.duration", float64(time.Now().Sub(start).Nanoseconds())/float64(1000))
	}
}
