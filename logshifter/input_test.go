package main

import (
	"bytes"
	"strings"
	"sync"
	"testing"
)

// TestInputBlocking ensures that Input never blocks, regardless of the queue
// consumption rate.
func TestInputBlocking(t *testing.T) {
	messageCount := int64(10000)
	messageSize := 1024

	// Use a small queue to help ensure an input backup.
	queue := make(chan []byte, 1)

	// Set up a fast output sink to help ensure an input backup.
	go func() {
		for {
			<-queue
		}
	}()

	// Collect stats.
	stats := make(map[string]float64)
	statsCh := make(chan Stat)
	stop := make(chan struct{})
	statsWg := sync.WaitGroup{}
	statsWg.Add(1)
	go func() {
		for {
			select {
			case <-stop:
				statsWg.Done()
				return
			case s := <-statsCh:
				stats[s.name] = stats[s.name] + s.value
			}
		}
	}()

	// Create an input Reader.
	var data string
	var i int64 = 0
	for ; i < messageCount; i++ {
		data += strings.Repeat("0", messageSize-1) + "\n"
	}
	buffer := bytes.NewBufferString(data)
	t.Logf("created %d byte test input (%d lines @ %d bytes each)\n", buffer.Len(), messageCount, messageSize)

	// Read until the test reader closes.
	input := &Input{
		reader:       buffer,
		queue:        queue,
		bufferSize:   messageSize,
		statsChannel: statsCh,
	}
	input.read()

	// If execution reaches this point, the Input hasn't wedged and the test is
	// successful.

	// Shut down the stats collector.
	close(stop)
	statsWg.Wait()
	t.Logf("stats: %#v", stats)
}
