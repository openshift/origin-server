package main

import (
	"os"
	"path/filepath"
	"time"
)

type RmRoller struct {
	maxFiles int
}

func (r *RmRoller) Roll(file *os.File) {
	now := time.Now()

	files, _ := filepath.Glob(file.Name() + "*")

	// if there are more files than we're configured to keep,
	// remove the oldest file
	if len(files) >= r.maxFiles {
		oldestTime := now
		var oldestName string
		for _, fn := range files {
			fi, _ := os.Stat(fn)
			modTime := fi.ModTime()
			if modTime.Before(oldestTime) {
				oldestTime = modTime
				oldestName = fn
			}
		}

		os.Remove(oldestName)
	}

	// close and rename the file
	file.Close()
	newFileName := file.Name() + "-" + now.Format("20060102030405")
	os.Rename(file.Name(), newFileName)
}
