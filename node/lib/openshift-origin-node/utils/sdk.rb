require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  module Runtime
    module Utils
      class Sdk
        CLIENT_OUTPUT_PREFIXES = %w(CLIENT_RESULT CLIENT_MESSAGE CLIENT_ERROR CLIENT_INTERNAL_ERROR CLIENT_DEBUG)

        # Public: Translates a ShellExecutionException into a new instance whose stdout, stderr,
        # and return code are suitable for returning to the client. Output is translated with
        # translate_out_for_client, and return codes < 100 are mapped to 157.
        #
        # e           - The ShellExecutionException to translate.
        # rc_override - If not Nil, the given return code will be used in place of the actual
        #               return code present on e.
        #
        # Returns the translated ShellExecutionException instance.
        def self.translate_shell_ex_for_client(e, rc_override = nil)
          return e unless (e && e.is_a?(Utils::ShellExecutionException))

          stdout = self.translate_out_for_client(e.stdout, :message)
          stderr = self.translate_out_for_client(e.stderr, :error)
          rc     = rc_override || e.rc

          ex = ::OpenShift::Runtime::Utils::ShellExecutionException.new(e.message, rc, stdout, stderr)
          ex.set_backtrace(e.backtrace)
          ex
        end

        # Public: Translate a String destined for the client with CLIENT_ prefixes. Handles newlines
        # and skips lines which are already prefixed.
        #
        # out  - The String to translate.
        # type - Either :message or :error.
        #
        # Examples
        #
        #    translate_out_for_client("A message", :message)
        #    # => "CLIENT_MESSAGE: A message"
        #
        #    translate_out_for_client("An error", :error)
        #    # => "CLIENT_ERROR: An error"
        #
        # Returns the translated String.
        def self.translate_out_for_client(out, type = :message)
          return '' unless out

          suffix = (type == :error ? "ERROR" : "MESSAGE")
          out.split("\n").map { |l| l.start_with?('CLIENT_') ? l : "CLIENT_#{suffix}: #{l}" }.join("\n")
        end
      end
    end
  end
end
