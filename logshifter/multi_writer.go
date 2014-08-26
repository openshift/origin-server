package main

type MultiWriter struct {
	writers []Writer
}

func (writer *MultiWriter) Init() error {

	for _, w := range writer.writers {
		err := w.Init()
		if err != nil {
			return err
		}
	}
	return nil
}

func (writer *MultiWriter) Close() error {

	var err error = nil
	for _, w := range writer.writers {
		err = w.Close()
	}
	return err
}

func (writer *MultiWriter) Write(b []byte) (n int, err error) {
	
	n = 0
	for _, w := range writer.writers {
		_, _ = w.Write(b)
	}

	return n, nil
}
