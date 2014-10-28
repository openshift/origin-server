#
# Enable Capybara / PhantomJS integration
#
# Supported environment variables:
#
#   CAPYBARA_DEBUG 
#     A boolean or path to a file to log output to.  Recommend
#     always setting this to a file when running automated suites.
#
#   CAPYBARA_HOST
#     A URL of a server to connect to.  Pass the root URL. E.g. to a devenv:
#
#        CAPYBARA_HOST=https://ec2-xx-xx-xx-xx.compute-1.amazonaws.com
#
#     When setting this to a devenv you will need to set 
#     RAILS_RELATIVE_URL_ROOT=/app to generate correct URLs.
#
#   TEST_SCREENSHOT_DIR
#     A path to write screenshots to.
#
if defined? Capybara
  require 'capybara/rails'
  require 'capybara/poltergeist'
  debug = ENV['CAPYBARA_DEBUG']
  debug = 
    if debug.nil?
      {}
    elsif debug.start_with? '/'
      CAPYBARA_LOG = File.open(debug, 'a')
      {
        :debug => true,
        :logger => CAPYBARA_LOG,
        :phantomjs_logger => CAPYBARA_LOG,
      }
    else
      CAPYBARA_LOG = STDOUT
      {
        :debug => true,
      }
    end

  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, {
      :phantomjs_options => %w[
        --disk-cache=yes
        --ignore-ssl-errors=yes
        --ssl-protocol=TLSv1
        --load-images=no
      ],
    }.merge(debug))
  end

  Capybara.javascript_driver = :poltergeist
  if ENV['CAPYBARA_HOST']
    Capybara.app_host = ENV['CAPYBARA_HOST'] 
    Capybara.run_server = false
  end

  class ActionDispatch::IntegrationTest
    include Capybara::DSL
    def self.web_integration
      setup do 
        Capybara.current_driver = Capybara.javascript_driver
        if defined? CAPYBARA_LOG 
          CAPYBARA_LOG.puts
          CAPYBARA_LOG.puts '-' * 40
          CAPYBARA_LOG.puts "BEGIN #{"#{self.class}#{__name__}".parameterize}_#{DateTime.now.strftime("%Y%m%d%H%M%S%L")}"
          CAPYBARA_LOG.puts
         end
         Capybara.current_session.driver.reset!
      end
      teardown do
        save_screenshot("#{ENV['TEST_SCREENSHOT_DIR']}#{"#{self.class}#{__name__}".parameterize}_#{DateTime.now.strftime("%Y%m%d%H%M%S%L")}.png", :full => true) unless passed?
        Capybara.current_session.driver.reset!
      end
    end
  end
end