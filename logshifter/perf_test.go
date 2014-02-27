package main

import (
	"testing"
)

func benchmarkShifter(queueSize int, msgLength int, messageCount int64, b *testing.B) {
	for n := 0; n < b.N; n++ {
		reader := NewDummyReader(messageCount, msgLength, 0)
		writer := NewSimpleDummyWriter()

		shifter := &Shifter{queueSize: queueSize, inputBufferSize: msgLength, inputReader: reader, outputWriter: writer}

		shifter.Start()
	}
}

func BenchmarkShifter(b *testing.B) { benchmarkShifter(1000, 100, 10000, b) }
