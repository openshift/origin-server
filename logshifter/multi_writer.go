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

	for _, w := range writer.writers {
		err := w.Close()
		if err != nil {
			return err
		}		
	}
	return nil
}

func (writer *MultiWriter) Write(b []byte) (n int, err error) {
	
	n = 0
	for _, w := range writer.writers {
		num, err := w.Write(b)
		if err != nil {
			return len(b), err
		}
	}

	return n, nil
}
