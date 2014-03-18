package main

import "testing"

func TestValidStringParsing(t *testing.T) {
	scenarios := map[string]ByteSize{
		"2B": ByteSize(2 * float64(B)),
		"4K": ByteSize(4 * float64(KB)),
		"5M": ByteSize(5 * float64(MB)),
		"6G": ByteSize(6 * float64(GB)),
		"7T": ByteSize(7 * float64(TB)),
		"8P": ByteSize(8 * float64(PB)),
		"9E": ByteSize(9 * float64(EB)),
		"1Z": ByteSize(1 * float64(ZB)),
		"2Y": ByteSize(2 * float64(YB)),
	}

	for str, val := range scenarios {
		bs, err := ParseByteSize([]byte(str))
		if err != nil {
			t.Fatal(err)
		}

		if bs != val {
			t.Fatalf("expected bs=%.0f, got %.0f", bs, val)
		}
	}
}
