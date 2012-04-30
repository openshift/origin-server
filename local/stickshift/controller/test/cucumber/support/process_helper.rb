require 'timeout'

module CommandHelper
  def urls_from_files(pattern)
    results = []
    Dir.glob(pattern).each do |file|
      File.new(file, "r").each {|line| results << line.chomp}
    end
    results
  end

  def add_failure(url, pid=$$)
    system("flock /tmp/rhc/lock echo '#{url}' >> #{$temp}/#{pid}-failures.log")
  end

  def failures
    urls_from_files("#{$temp}/*-failures.log")
  end

  def add_success(url, pid=$$)
    system("echo '#{url}' >> #{$temp}/#{pid}-success.log")
  end

  def successes(pattern="*")
    urls_from_files("#{$temp}/#{pattern.to_s}-success.log")
  end

  def wait(pid, expected_urls, timeout=300)
    begin
      Timeout::timeout(timeout) do
        Process.wait(pid)
        exit_status = $?.exitstatus
        $logger.error("Process #{pid} failed with #{exit_status}") if exit_status != 0
      end
    rescue Timeout::Error
      $logger.error("Process #{pid} timed out")
      # Log the remaining url's as failures
      failed_urls = expected_urls - successes(pid)
      $logger.error("Recording the following urls as failed = #{failed_urls.pretty_inspect}")
      failed_urls.each {|url| add_failure(url, pid)}
    end
  end
end
World(CommandHelper)
