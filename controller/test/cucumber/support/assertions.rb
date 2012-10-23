require 'benchmark'
require 'test/unit/assertions'

## Run code block and log performance results
def record_measure_elapsed(label)
  elapsed = Benchmark.realtime do
    yield
  end

  mins, secs = elapsed.abs.divmod(60)
  $logger.debug("#{label}: #{mins}m #{secs.to_i}s")
end

## Run code block and log performance results
def record_measure(label)
  $logger.debug(
    tms = Benchmark.measure(label) do
      yield
    end.format("%n: %10.6rreal %10.6u user %10.6y sys")
  )
end

## Provide far more meaninful messages than 'assert File.exists?(...)'

def assert_directory_exists(filename, msg = nil)
  full_message = build_message(msg, "Directory ? should have been found.", filename)
  assert_block(full_message) do
    File.directory?(filename)
  end
end

def assert_directory_not_exists(filename, msg = nil)
  full_message = build_message(msg, "Directory ? should not have been found.", filename)
  assert_block(full_message) do
    ! File.directory?(filename)
  end
end

def assert_file_exists(filename, msg = nil)
  full_message = build_message(msg, "File ? should have been found.", filename)
  assert_block(full_message) do
    File.exists?(filename)
  end
end

def assert_file_not_exists(filename, msg = nil)
  full_message = build_message(msg, "File ? should not have been found.", filename)
  assert_block(full_message) do
    ! File.exists?(filename)
  end
end

