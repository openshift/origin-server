package main

// MultiWriter writes to multiple Writers (file, syslog)
// MultiWriter implements the Writer interface, and is also a wrapper around multiple Writer types
type MultiWriter struct {
	writers []Writer
}

// Init loops through 'writers' slice and calls the writer.Init() method on each
// Init will return on first error encountered, or when complete
func (writer *MultiWriter) Init() error {

	for _, w := range writer.writers {
		err := w.Init()
		if err != nil {
			return err
		}
	}
	return nil
}

// Close loops through 'writers' slice and calls the writer.Close() method on each
// Close will attempt to close all writers, and return the last error encountered
func (writer *MultiWriter) Close() error {

	var err error = nil
	for _, w := range writer.writers {
		result := w.Close()
		if result != nil {
			err = result
		}
	}
	return err
}

// Write loops through 'writers' slice and calls the writer.Write() method on each
// Write will attempt a write for each and supress any errors encountered, as 
// there are no delivery guarantees by design
func (writer *MultiWriter) Write(b []byte) (int, error) {
	
	for _, w := range writer.writers {
		_, _ = w.Write(b)
	}

	return len(b), nil
}
