require 'cqpid'

module MCollective
  module Connector
    # Handles sending and receiving messages over the AMQP 1.0 protocol
    #
    # This plugin requires the qpid-qmf bindings for ruby.
    #
    # Configuration options (non SSL):
    #   connector = qpid
    #   plugin.qpid.secure = false
    #   plugin.qpid.host = qpid server
    #   plugin.qpid.host.port = qpid port (default: 5672)
    #   plugin.qpid.timeout = qpid connection timeout in seconds (default: 5)
    #
    # Configuration options (SSL):
    #   connector = qpid
    #   plugin.qpid.secure = true
    #   plugin.qpid.ha_host = qpid server
    #   plugin.qpid.host.ha.port = qpid port (default: 5671)
    #   plugin.qpid.timeout = qpid connection timeout in seconds (default: 5)
    #
    class Qpid<Base
      attr_reader :connection

      def initialize
        @config = Config.new
        @subscriptions = {}
      end

      def connect
        Log.debug("Connection attempt to qpidd")
        if @connection
          Log.debug("Already connected. Not re-initializing connection")
          return
        end

        # Parse out the config info
        host = get_option("qpid.host", "127.0.0.1")
        host_port = get_option("qpid.host.port", 5672).to_i
        ha_host = get_option("qpid.host.ha", nil)
        ha_host_port = get_option("qpid.host.ha.port", nil)
        secure = (get_option("qpid.secure", "false") == "true")
        timeout = get_option("qpid.timeout", 5).to_i
        args = []
        Log.debug("SECURE SECURE SECURE") if secure

        # Default ports as necessary
        if secure
          host = ha_host
          host_port = ha_host_port || 5671
          url = "amqp:ssl:#{host}:#{host_port}"
          args << "transport:ssl"
        else
          host_port ||= 5672
          url = "amqp:tcp:#{host}:#{host_port}"          
        end
        
        args << "reconnect-urls: '#{url}'"
        args << "reconnect:true"
        args << "reconnect-timeout:#{timeout}" if timeout
        args << "heartbeat:1"
        qpid_options = "{#{args.join(', ')}}"

        @connection = nil
        begin
          Log.debug("Connecting to #{url},  #{qpid_options}")
          @connection = Cqpid::Connection.new(url, qpid_options)
          @connection.open
        rescue StandardError => e
          Log.error("Initial connection failed... retrying")
          sleep 5
          retry
        end

        @session = @connection.createSession
        @sender = @session.createSender("amq.direct")
        Log.info("AMQP Connection established")
      end

      def receive
        begin
          Log.debug("Waiting for a message...")
          receiver = Cqpid::Receiver.new
          while 1 do
            break if @session.nextReceiver(receiver,Cqpid::Duration.IMMEDIATE)
            raise "Need to reconnect" unless @session.getConnection().isOpen()
            sleep 0.01
          end
          qpid_msg = receiver.fetch()
          Log.debug("Received message #{qpid_msg.inspect}")

          @session.acknowledge
          msg = Message.new(qpid_msg.getContent, qpid_msg)
          Log.debug("Constructed mcollective message #{msg.inspect}")
          msg
        rescue StandardError => e
          Log.debug("Caught Exception #{e}")
          @session.sync
          retry
        end
      end

      def publish(msg)
        Log.debug("Publish #{msg.inspect}")
        begin
          target = make_target(msg.agent, msg.type, msg.collective)

          Log.debug("in send with #{target}")
          Log.debug("Sending a message to target '#{target}'")

          @message = Cqpid::Message.new()
          @message.setSubject(target)
          @message.setContent(msg.payload)
          @message.setContentType("text/plain")
          @sender.send(@message);
          Log.debug("Message sent")
        rescue StandardError => e
          Log.debug("Caught Exception #{e}")
          @session.sync
        end
      end
      
      # Subscribe to a topic or queue
      def subscribe(agent, type, collective)
        Log.debug("Subscription request for #{agent} #{type} #{collective}")
        source = make_target(agent, type, collective)
        unless @subscriptions.include?(source)
          Log.debug("Subscribing to #{source}")
          receiver = @session.createReceiver("amq.direct/#{source}" )
          receiver.setCapacity(10)
          @subscriptions[source] = receiver
        end
        Log.debug("Current subscriptions #{@subscriptions}")
      end      

      def make_target(agent, type, collective)
        raise("Unknown target type #{type}") unless [:directed, :broadcast, :reply, :request, :direct_request].include?(type)

        case type
          when :reply
            suffix = :reply
          when :broadcast
            suffix = :command
          when :request
            suffix = :command
          when :direct_request
            raise("Direct request not supported")
          when :directed
            raise("Directed not supported")            
        end

        ["#{collective}", agent, suffix].compact.join(".")
      end

      def unsubscribe(agent, type, collective)
        source = make_target(agent, type, collective)        
        Log.debug("Unsubscribing #{source}")
        receiver = @subscriptions.delete(source)
        receiver.close if receiver
        Log.debug("Current subscriptions #{@subscriptions}")
      end

      def disconnect
        Log.debug("Disconnecting from Qpid")

        # Cleanup the session
        begin
          @session.sync
          @session.close
        rescue Exception => e
          Log.debug("Failed to cleanup session: #{e}")
        ensure
          @session = nil
        end

        # Clear the subscription cache
        @subscriptions = {}

        # Cleanup the connection
        begin
          @connection.close
        rescue Exception => e
          Log.debug("Failed to cleanup connection: #{e}")
        ensure
          @connection = nil
        end
      end

      private

      # looks for a config option, accepts an optional default
      # raises an exception when it cant find a value anywhere
      def get_option(opt, default=nil, allow_nil=true)
        return @config.pluginconf[opt] if @config.pluginconf.include?(opt)
        return default if (default or allow_nil)
        raise("No plugin.#{opt} configuration option given")
      end
    end
  end
end
