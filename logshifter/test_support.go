package main

import (
	"bytes"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

// Simulates an upstream reader of a producer such as stdin
type DummyReader struct {
	buffer      *bytes.Buffer
	readerDelay time.Duration
	bufEmptyWg  *sync.WaitGroup
}

func NewDummyReader(msgCount int64, msgLength int, readerDelay time.Duration) *DummyReader {
	var data string

	var i int64 = 0
	for ; i < msgCount; i++ {
		data += strings.Repeat("0", msgLength-1) + "\n"
	}

	buffer := bytes.NewBufferString(data)

	fmt.Printf("created %d byte test input (%d lines @ %d bytes each)\n", buffer.Len(), msgCount, msgLength)

	wg := sync.WaitGroup{}
	wg.Add(1)

	return &DummyReader{buffer: buffer, readerDelay: readerDelay, bufEmptyWg: &wg}
}

func (reader *DummyReader) Read(b []byte) (written int, err error) {
	if reader.readerDelay > 0 {
		time.Sleep(reader.readerDelay)
	}

	written, err = reader.buffer.Read(b)

	if err != nil {
		reader.bufEmptyWg.Done()
	}

	return
}

// Simulates a downstream log writer such as syslog. The underlying
// write behavior must be implemented by the test user.
type DummyWriter struct {
	writeFunc func(b []byte) (written int, err error)
}

func (writer *DummyWriter) Init() error  { return nil }
func (writer *DummyWriter) Close() error { return nil }

func (writer *DummyWriter) Write(b []byte) (written int, err error) {
	return writer.writeFunc(b)
}

func NewSimpleDummyWriter() *DummyWriter {
	w := &DummyWriter{
		writeFunc: func(b []byte) (written int, err error) {
			return len(b), nil
		},
	}

	return w
}

// A simple stats aggregator that collects stats from a channel
// and adds the value of like keys in a map. Use this in tests
// by feeding the aggregator's channel to a Shifter instance, and
// using Finish() to shut down the collector.
type StatsAggregator struct {
	statsChan chan Stat
	wg        sync.WaitGroup
	stats     map[string]float64
}

func NewStatsAggregator() *StatsAggregator {
	a := &StatsAggregator{
		statsChan: make(chan Stat),
		wg:        sync.WaitGroup{},
		stats:     make(map[string]float64),
	}

	go func() {
		a.wg.Add(1)
		for s := range a.statsChan {
			a.stats[s.name] = a.stats[s.name] + s.value
		}
		a.wg.Done()
	}()

	return a
}

func (a *StatsAggregator) Finish() map[string]float64 {
	close(a.statsChan)
	a.wg.Wait()
	return a.stats
}

func (a *StatsAggregator) AssertStatsEqual(t *testing.T, expectations map[string]float64) {
	for k, v := range expectations {
		if a.stats[k] != v {
			t.Fatalf("expected %s to be %.1f, got %.1f\n", k, v, a.stats[k])
		}
	}
}
