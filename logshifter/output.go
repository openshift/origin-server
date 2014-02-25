package main

import (
	"sync"
	"time"
)

// Output consumes byte arrays from queue and sends them to Writer.
//
// If statsChannel is supplied to the Output, the following Stats will
// be placed on the channel:
//
//   output.write => number of messages written during the call to Write
//   output.write.duration => time taken to call writer.Write (micros)
type Output struct {
	writer       Writer
	queue        <-chan []byte
	statsChannel chan Stat
}

// Write asynchronously consumes from queue, sending each byte array to writer until
// the channel is closed.
//
// If writer initialization succeeds, a WaitGroup is returned which will receive a call
// to Done upon closure of the queue channel. Otherwise, the error is returned.
func (output *Output) Write() (wg *sync.WaitGroup, err error) {
	err = output.writer.Init()

	if err != nil {
		return nil, err
	}

	wg = &sync.WaitGroup{}
	wg.Add(1)

	go func(wg *sync.WaitGroup) {
		output.write()
		wg.Done()
	}(wg)

	return wg, nil
}

// Private synchronous portion of Write.
func (output *Output) write() {
	for line := range output.queue {
		var start time.Time

		if output.statsChannel != nil {
			start = time.Now()
		}

		output.writer.Write(line)

		if output.statsChannel != nil {
			output.statsChannel <- Stat{name: "output.write", value: 1.0}
			output.statsChannel <- Stat{name: "output.write.duration", value: float64(time.Now().Sub(start).Nanoseconds()) / float64(1000)}
		}
	}

	output.writer.Close()
}
