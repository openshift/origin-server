package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"sync"
	"time"
)

// A CLI interface to a Shifter.
//
// If statsfilename is supplied, a stats aggregator goroutine is created which collects
// statistics on statsinterval and writes the totals since the last interval in JSON
// format to statsfilename.
func main() {
	// arg parsing
	var configFile, statsFileName, tag string
	var verbose bool
	var statsInterval time.Duration

	flag.StringVar(&configFile, "config", DefaultConfigFile, "config file location")
	flag.BoolVar(&verbose, "verbose", false, "enables verbose output (e.g. stats reporting)")
	flag.StringVar(&statsFileName, "statsfilename", "", "enabled period stat reporting to the specified file")
	flag.DurationVar(&statsInterval, "statsinterval", (time.Duration(5) * time.Second), "stats reporting interval")
	flag.StringVar(&tag, "tag", "logshifter", "tag used by outputs for extra message context (e.g. program name)")
	flag.Parse()

	// load the config
	config, configErr := ParseConfig(configFile)
	if configErr != nil {
		fmt.Printf("Error loading config from %s: %s", configFile, configErr)
		os.Exit(1)
	}

	// override output type from environment if allowed by config
	if config.outputTypeFromEnviron {
		switch os.Getenv("LOGSHIFTER_OUTPUT_TYPE") {
		case "syslog":
			config.outputType = Syslog
		case "file":
			config.outputType = File
		}
	}

	if verbose {
		fmt.Printf("config: %+v\n", config)
	}

	// set up stats collection if a stats file was supplied
	var statsGroup *sync.WaitGroup
	var statsShutdownChan chan int
	var statsChannel chan Stat
	if len(statsFileName) > 0 {
		statsChannel = make(chan Stat)
		statsGroup, statsShutdownChan = readStats(statsChannel, statsInterval, statsFileName)
	}

	// set up the writer
	writer, err := createWriter(config, tag)
	if err != nil {
		fmt.Printf("error creating writer: %s", err)
		os.Exit(1)
	}

	shifter := &Shifter{
		queueSize:       config.queueSize,
		inputBufferSize: config.inputBufferSize,
		inputReader:     os.Stdin,
		outputWriter:    writer,
		statsChannel:    statsChannel,
	}

	// start the log pipe
	startErr := shifter.Start()

	// shut down the stats reporter
	if statsChannel != nil {
		close(statsChannel)
		statsShutdownChan <- 0
		statsGroup.Wait()
	}

	if startErr != nil {
		fmt.Printf("Failed to start logshifter: %s", err)
		os.Exit(1)
	}
}

// Create writer instances based on config.
func createWriter(config *Config, tag string) (Writer, error) {
	switch config.outputType {
	case Syslog:
		return &SyslogWriter{config: config, tag: tag}, nil
	case File:
		return &FileWriter{config: config, tag: tag}, nil
	default:
		return nil, errors.New("unsupported output type")
	}
}

// Read stats from statsChannel asynchronously. Collect them on interval, accumulate totals,
// and write them in JSON format to file, resetting the totals each interval.
//
// Stops reading when shutdownChan receives a value.
func readStats(statsChannel chan Stat, interval time.Duration, file string) (wg *sync.WaitGroup, shutdownChan chan int) {
	wg = &sync.WaitGroup{}
	wg.Add(1)

	shutdownChan = make(chan int)

	go func(file string, wg *sync.WaitGroup) {
		defer wg.Done()

		f, err := os.OpenFile(file, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.ModePerm)
		if err != nil {
			return
		}

		defer f.Close()

		ticker := time.Tick(interval)
		stats := make(map[string]float64)

		for running := true; running; {
			select {
			case s := <-statsChannel:
				stats[s.name] = stats[s.name] + s.value
			case <-ticker:
				if jsonBytes, err := json.Marshal(stats); err == nil {
					f.Write(jsonBytes)
					f.WriteString("\n")
				}
				stats = make(map[string]float64)
			case <-shutdownChan:
				running = false
			}
		}
	}(file, wg)

	return wg, shutdownChan
}
