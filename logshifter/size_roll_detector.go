package main

import (
	"errors"
	"os"
	"regexp"
	"strconv"
	"strings"
)

type ByteSize float64

var ByteSizePattern = regexp.MustCompile(`^(\d+)([BKMGTPEZY])$`)

const (
	B ByteSize = 1 << (10 * iota)
	KB
	MB
	GB
	TB
	PB
	EB
	ZB
	YB
)

func ParseByteSize(sizeText []byte) (ByteSize, error) {
	if !ByteSizePattern.Match(sizeText) {
		return 0, errors.New("invalid size string")
	}

	subs := ByteSizePattern.FindSubmatch(sizeText)

	if len(subs) != 3 {
		return 0, errors.New("invalid size string")
	}

	size, _ := strconv.ParseFloat(string(subs[1]), 64)
	unit := strings.ToUpper(string(subs[2]))
	switch unit {
	case "B":
		size = size * float64(B)
	case "K":
		size = size * float64(KB)
	case "M":
		size = size * float64(MB)
	case "G":
		size = size * float64(GB)
	case "T":
		size = size * float64(TB)
	case "P":
		size = size * float64(PB)
	case "E":
		size = size * float64(EB)
	case "Z":
		size = size * float64(ZB)
	case "Y":
		size = size * float64(YB)
	}

	return ByteSize(size), nil
}

type SizeRollDetector struct {
	maxSize ByteSize

	fileSize float64
}

func (t *SizeRollDetector) Track(file *os.File) {
	fi, _ := file.Stat()
	t.fileSize = float64(fi.Size())
}

func (t *SizeRollDetector) ShouldRoll() bool {
	return t.maxSize > 0 && (t.fileSize > float64(t.maxSize))
}

func (t *SizeRollDetector) NotifyWrite(bytesToWrite int) {
	t.fileSize += float64(bytesToWrite)
}
