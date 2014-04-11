require 'strscan'
require 'openshift-origin-node/utils/metrics_helper'

module OpenShift
  module Runtime
    module ApplicationContainerExt
      module Metrics

        class MetricsLineProcessor
          attr_accessor :cartridge

          def initialize(container, cartridge=nil)
            @container = container
            @cartridge = cartridge
            @gear_env = ::OpenShift::Runtime::Utils::Environ::for_gear(container.container_dir)
            @metadata = []
            container.metrics_metadata.each_pair do |key, env_var|
              @metadata << "#{key}=#{@gear_env[env_var]}"
            end
            @metadata = @metadata.join(' ')
          end

          def process(line)
            if @cartridge
              puts "type=metric cart=#{@cartridge.name} #{@metadata} #{line}"
            else
              puts "type=metric #{@metadata} #{line}"
            end
          end
        end

        # This class is a buffered stream parser that is capable of receiving a
        # stream of text and splitting it into lines up to a configurable max
        # length. If its buffer fills up without receiving a newline, the entire
        # buffer is discarded.
        class BufferedLineParser
          NEWLINE_REGEX = /\n/

          # Create a new instance.
          #
          # @param max_line_length [Integer] maximum line length
          # @param line_handler [#process] a line handler
          def initialize(max_line_length, line_handler)
            @buf = ""
            @max_line_length = max_line_length
            @discard_current = false
            @line_handler = line_handler
          end

          # Receive stream input.
          #
          # If the input contains a newline, invoke the line_handler's
          # `#process` method, passing it the complete line.
          #
          # If the input does not contain a newline:
          # - if the buffer's length + the input's length > maximum line length,
          #   discard the buffer's contents.
          # - otherwise, append the input to the buffer and wait to be invoked
          #   again.
          def <<(input)
            s = StringScanner.new(input)

            loop do
              line = s.scan_until(NEWLINE_REGEX)

              if line
                @discard_current = true if @buf.length + line.length > @max_line_length
              else
                if @buf.length + s.rest.length > @max_line_length
                  @discard_current = true
                else
                  @buf += s.rest
                end

                break
              end

              unless @discard_current
                @line_handler.process(@buf + line.chomp)
              end

              @discard_current = false
              @buf = ""
            end
          end
        end

        def metrics_per_gear_timeout
          # default overall metrics timeout per gear to 3 seconds if not configured in node.conf
          @metrics_per_gear_timeout ||= (@config.get("METRICS_PER_GEAR_TIMEOUT") || 3).to_f
        end

        def metrics_per_script_timeout
          # default metrics oo_spawn timeout to 1 second if not configured in node.conf
          @metrics_per_script_timeout ||= (@config.get("METRICS_PER_SCRIPT_TIMEOUT") || 1).to_f
        end

        def metrics_max_line_length
          # default the metrics line parser's buffer size to 2000 if not configured in node.conf
          @metrics_max_line_length ||= (@config.get("METRICS_MAX_LINE_LENGTH") || 2000).to_i
        end

        def metrics_metadata
          @metrics_metadata ||= ::OpenShift::Runtime::Utils::MetricsHelper.metrics_metadata(@config)
        end

        # Run metrics for cartridges and the application.
        #
        # Each cartridge must have a Metrics entry in its manifest for its
        # bin/metrics script to be invoked.
        #
        # If the application's repo has a metrics action hook, run that as well.
        #
        def metrics
          begin
            Timeout::timeout(metrics_per_gear_timeout) do
              processor = MetricsLineProcessor.new(self)
              parser = BufferedLineParser.new(metrics_max_line_length, processor)

              cartridge_metrics(processor, parser)
              application_metrics(processor, parser)
            end
          rescue Timeout::Error => e
            puts("Gear metrics exceeded timeout of #{metrics_per_gear_timeout}s for gear #{uuid}")
          end
        end

        def cartridge_metrics(processor, parser)
          @cartridge_model.each_cartridge do |cart|
            # Check if cartridge has a metrics entry in its manifest
            unless cart.metrics.nil?
              begin
                cart_metrics = PathUtils.join(@container_dir, cart.directory, "bin", "metrics")

                if File.file?(cart_metrics) and File.executable?(cart_metrics)
                  processor.cartridge = cart
                  run_in_container_context(cart_metrics,
                                          buffer_size: metrics_max_line_length,
                                          out: parser,
                                          timeout: metrics_per_script_timeout)
                end

              #FIXME should really be doing 'rescue => e' once ShellExecutionException is modified
              #to extend StandardError instead of Exception
              rescue Exception => e
                puts("Error retrieving metrics for gear #{uuid}, cartridge '#{cart.name}': #{e.message}")
              end
            end
          end
        end

        def application_metrics(processor, parser)
          begin
            metrics_hook = PathUtils.join(@container_dir, "app-root", "repo", ".openshift", "action_hooks", "metrics")

            if File.exist?(metrics_hook) and File.executable?(metrics_hook)
              processor.cartridge = nil
              run_in_container_context(metrics_hook,
                                      buffer_size: metrics_max_line_length,
                                      out: parser,
                                      timeout: metrics_per_script_timeout)
            end

          #FIXME should really be doing 'rescue => e' once ShellExecutionException is modified
          #to extend StandardError instead of Exception
          rescue Exception => e
            puts("Error retrieving application metrics for gear #{uuid}: #{e.message}")
          end
        end
      end
    end
  end
end
