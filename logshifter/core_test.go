package main

import (
	"fmt"
	"testing"
)

func TestSimpleDispatch(t *testing.T) {
	ag := NewStatsAggregator()

	reader := NewDummyReader(1000, 100, 0)
	writer := NewSimpleDummyWriter()
	shifter := &Shifter{
		queueSize:       1000,
		inputBufferSize: 100,
		inputReader:     reader,
		outputWriter:    writer,
		statsChannel:    ag.statsChan,
	}

	shifter.Start()

	ag.Finish()

	ag.AssertStatsEqual(t, map[string]float64{
		"input.read":   1000,
		"input.drop":   0,
		"output.write": 1000,
	})

	fmt.Printf("stats: %v\n", ag.stats)
}

func TestInputOverflow(t *testing.T) {
	ag := NewStatsAggregator()

	reader := NewDummyReader(1000, 200, 0)
	writer := NewSimpleDummyWriter()
	shifter := &Shifter{
		queueSize:       1000,
		inputBufferSize: 100,
		inputReader:     reader,
		outputWriter:    writer,
		statsChannel:    ag.statsChan,
	}

	shifter.Start()

	ag.Finish()

	ag.AssertStatsEqual(t, map[string]float64{
		"input.read":   2000,
		"input.drop":   0,
		"output.write": 2000,
	})

	fmt.Printf("stats: %v\n", ag.stats)
}

func TestDropOnBlockedOutput(t *testing.T) {
	ag := NewStatsAggregator()

	reader := NewDummyReader(1000, 100, 0)

	// set up a writer which won't write anything until the
	// reader has completed producing input- this will force
	// many drops
	writer := &DummyWriter{
		writeFunc: func(b []byte) (written int, err error) {
			reader.bufEmptyWg.Wait()
			return len(b), nil
		},
	}

	shifter := &Shifter{
		queueSize:       1,
		inputBufferSize: 100,
		inputReader:     reader,
		outputWriter:    writer,
		statsChannel:    ag.statsChan,
	}

	shifter.Start()

	ag.Finish()

	// two should be written: the first message read which
	// is immediately consumed by the writer, and the last
	// which sits in the queue (following the eviction of
	// all the intermediate messages) until reading is done
	// and the writer is unblocked.
	ag.AssertStatsEqual(t, map[string]float64{
		"input.read":   1000,
		"input.drop":   998,
		"output.write": 2,
	})

	fmt.Printf("stats: %v\n", ag.stats)
}
