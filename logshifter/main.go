package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

// A CLI interface to a Shifter.
//
// If statsfilename is supplied, a stats aggregator goroutine is created which collects
// statistics on statsinterval and writes the totals since the last interval in JSON
// format to statsfilename.
func main() {
	// set up signal handling
	sigChan := make(chan os.Signal, 1)
	go func() {
		signal.Notify(sigChan, syscall.SIGHUP)
		for {
			<-sigChan
			// ignore SIGHUP for now
		}
	}()

	// arg parsing
	var configFile, statsFileName, tag string
	var verbose bool
	var statsInterval time.Duration

	flag.StringVar(&configFile, "config", "", "config file location")
	flag.BoolVar(&verbose, "verbose", false, "enables verbose output (e.g. stats reporting)")
	flag.StringVar(&statsFileName, "statsfilename", "", "enabled period stat reporting to the specified file")
	flag.DurationVar(&statsInterval, "statsinterval", (time.Duration(5) * time.Second), "stats reporting interval")
	flag.StringVar(&tag, "tag", "", "tag used by outputs for extra message context (e.g. program name)")
	flag.Parse()

	// Unless verbose mode is enabled, redirect stdout/stderr to /dev/null. This
	// prevents readers of a pipeline including logshifter from blocking awaiting
	// output which is never coming.
	if !verbose {
		if devnull, err := os.OpenFile(os.DevNull, os.O_RDWR, 0); err == nil {
			syscall.Dup2(int(devnull.Fd()), int(os.Stdout.Fd()))
			syscall.Dup2(int(devnull.Fd()), int(os.Stderr.Fd()))
		}
	}

	if len(tag) == 0 {
		fmt.Println("Error: the `tag` argument is required")
		os.Exit(1)
	}

	// If no config option is given and if a config file exists at the known global
	// location, use the global config. If a config file is explicitly specified,
	// use it. Otherwise, fall back to internal defaults.
	config := DefaultConfig()

	if _, err := os.Stat(DefaultConfigFile); err == nil && len(configFile) == 0 {
		configFile = DefaultConfigFile
	}

	if len(configFile) != 0 {
		if _, err := os.Stat(configFile); err != nil {
			fmt.Printf("Error: config file %s not found", configFile)
			os.Exit(1)
		}

		var err error
		config, err = ParseConfig(configFile)
		if err != nil {
			fmt.Printf("Error: couldn't load config file %s: %v", configFile, err)
			os.Exit(1)
		}
	}

	// override output type from environment if allowed by config
	if config.outputTypeFromEnviron {
		switch os.Getenv("LOGSHIFTER_OUTPUT_TYPE") {
		case "syslog":
			config.outputType = Syslog
		case "file":
			config.outputType = File
		case "multi":
			config.outputType = Multi
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
	writer, err := createWriter(config, tag, verbose)
	if err != nil {
		fmt.Printf("Error: couldn't create writer: %v", err)
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
	if err := shifter.Start(); err != nil {
		fmt.Printf("Error: logshifter startup failed: %v", err)
		os.Exit(1)
	}

	// shut down the stats reporter
	if statsChannel != nil {
		close(statsChannel)
		statsShutdownChan <- 0
		statsGroup.Wait()
	}

	// shut down the signal handler
	close(sigChan)
}

// Create writer instances based on config.
func createWriter(config *Config, tag string, verbose bool) (Writer, error) {
	switch config.outputType {
	case Syslog:
		return createSyslogWriter(config.syslogBufferSize, tag)
	case File:
		return createFileWriter(config, tag, verbose)
	case Multi:
		fileWriter, err := createFileWriter(config, tag, verbose)
		if err != nil {
			return nil, err
		}
		syslogWriter, err := createSyslogWriter(config.syslogBufferSize, tag)
		if err != nil {
			return nil, err
		}		
		return &MultiWriter {
			writers: []Writer{ syslogWriter, fileWriter },
		}, nil
	default:
		return nil, errors.New("unsupported output type")
	}
}

// Create file writer instance based on config
func createFileWriter(config *Config, tag string, verbose bool) (Writer, error) {
		var maxFileSize ByteSize
		maxFileSizeConfig := os.Getenv("LOGSHIFTER_" + strings.ToUpper(tag) + "_MAX_FILESIZE")
		maxFileSize, err := ParseByteSize([]byte(strings.ToUpper(maxFileSizeConfig)))
		if err != nil {
			maxFileSize = ByteSize(10 * MB)
		}

		var maxFiles int64
		maxFilesConfig := os.Getenv("LOGSHIFTER_" + strings.ToUpper(tag) + "_MAX_FILES")
		maxFiles, err = strconv.ParseInt(maxFilesConfig, 10, 0)
		if err != nil {
			maxFiles = 10
		}

		if verbose {
			fmt.Printf("using max file size %.0f and max files %d\n", maxFileSize, maxFiles)
		}

		rollDetector := &SizeRollDetector{maxSize: maxFileSize}
		roller := &RmRoller{maxFiles: int(maxFiles)}

		writer := &FileWriter{
			baseDir:      config.fileWriterDir,
			bufferSize:   config.fileBufferSize,
			tag:          tag,
			rollDetector: rollDetector,
			roller:       roller,
		}

		return writer, nil
}

// Create syslog writer instance based on config
func createSyslogWriter(bufferSize int, tag string) (Writer, error) {
	return &SyslogWriter{bufferSize: bufferSize, tag: tag}, nil
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
