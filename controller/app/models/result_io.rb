class ResultIO
  attr_accessor :debugIO, :resultIO, :messageIO, :errorIO, :appInfoIO, :exitcode, :data, :cart_commands, :properties, :hasUserActionableError, :deployments

  def initialize(exitcode=nil, output=nil, gear_id=nil)
    @debugIO = StringIO.new
    @resultIO = StringIO.new
    @messageIO = StringIO.new
    @errorIO = StringIO.new
    @appInfoIO = StringIO.new
    @data = ""
    @hasUserActionableError = false

    @exitcode = exitcode || 0
    @cart_commands = []
    @hasUserActionableError = false
    @properties = {}
    parse_output(output, gear_id) unless output.nil?
  end

  def set_cart_property(gear_id, category, key, value)
    self.properties[category] = {} if self.properties[category].nil?
    self.properties[category][gear_id] = {} if self.properties[category][gear_id].nil?
    self.properties[category][gear_id][key] = value
  end

  # Append a {ResultIO} to the current instance.
  # @note the last non-zero exitcode is retained
  def append(resultIO)
    self.debugIO << resultIO.debugIO.string
    self.resultIO << resultIO.resultIO.string
    self.messageIO << resultIO.messageIO.string
    self.errorIO << resultIO.errorIO.string
    self.appInfoIO << resultIO.appInfoIO.string

    if resultIO.exitcode != 0
      if resultIO.hasUserActionableError
        unless (!self.hasUserActionableError) && self.exitcode != 0
          self.hasUserActionableError = true
        end
      else
        self.hasUserActionableError = false
      end
    end

    self.cart_commands += resultIO.cart_commands

    self.data += resultIO.data

    resultIO.properties.each do |category, cat_props|
      self.properties[category] = {} if self.properties[category].nil?
      self.properties[category] = self.properties[category].merge(cat_props) unless cat_props.nil?
    end
    self.exitcode = resultIO.exitcode if resultIO.exitcode != 0

    if resultIO.exitcode != 0
      if resultIO.hasUserActionableError
        unless (!self.hasUserActionableError) && self.exitcode != 0
          self.hasUserActionableError = true
        end
      else
        self.hasUserActionableError = false
      end
    end

    self
  end

  # Returns the output of this {ResultIO} object as a string. Primarily used for debug output.
  def to_s
    str = "--DEBUG--\n#{@debugIO.string}\n" +
          "--RESULT--\n#{@resultIO.string}\n" +
          "--MESSAGE--\n#{@messageIO.string}\n" +
          "--ERROR--\n#{@errorIO.string}\n" +
          "--APP INFO--\n#{@appInfoIO.string}\n" +
          "--CART COMMANDS--\n#{@cart_commands.join("\n")}\n" +
          "--CART PROPERTIES--\n#{@properties.inspect}\n" +
          "--DATA--\n#{@data}\n" +
          "--EXIT CODE--\n#{@exitcode}\n" +          
          "--USER ACTIONABLE--\n#{@hasUserActionableError}\n"
  end

  def parse_output(output, gear_id)
    if output.present?
      output.each_line do |line|
        if line =~ /^CLIENT_(MESSAGE|RESULT|DEBUG|ERROR|INTERNAL_ERROR): /
          case $1
          when 'MESSAGE'
            self.messageIO << line['CLIENT_MESSAGE: '.length..-1]
          when 'RESULT'
            self.resultIO << line['CLIENT_RESULT: '.length..-1]
          when 'DEBUG'
            self.debugIO << line['CLIENT_DEBUG: '.length..-1]
          when 'INTERNAL_ERROR'
            self.errorIO << line['CLIENT_INTERNAL_ERROR: '.length..-1]
          else
            self.errorIO << line['CLIENT_ERROR: '.length..-1]
            self.hasUserActionableError = true
          end
        elsif line.start_with?('CART_DATA: ')
          key,value = line['CART_DATA: '.length..-1].chomp.split('=')
          self.set_cart_property(gear_id, "attributes", key, value)
        elsif line.start_with?('CART_PROPERTIES: ')
          key,value = line['CART_PROPERTIES: '.length..-1].chomp.split('=')
          self.set_cart_property(gear_id, "component-properties", key, value)
        elsif line.start_with?('ATTR: ')
          key,value = line['ATTR: '.length..-1].chomp.split('=')
          self.set_cart_property(gear_id, "attributes", key, value)              
        elsif line.start_with?('APP_INFO: ')
          self.appInfoIO << line['APP_INFO: '.length..-1]
        elsif line =~ /^NOTIFY_ENDPOINT_(CREATE|DELETE): /
          # 'NOTIFY_ENDPOINT_CREATE: ' and 'NOTIFY_ENDPOINT_DELETE: '
          # both have length 24.
          if line =~ /^NOTIFY_ENDPOINT_CREATE: /
            endpoint_hash = JSON.parse(line[23..-1].chomp)
            self.cart_commands.push({:command => "NOTIFY_ENDPOINT_CREATE", :args => [endpoint_hash]})
          else
            address,port = line[23..-1].chomp.split(' ')
            self.cart_commands.push({:command => "NOTIFY_ENDPOINT_DELETE", :args => [address,port]})
          end
        elsif self.exitcode == 0
          if line.start_with?('SSH_KEY_ADD: ')
            key = line['SSH_KEY_ADD: '.length..-1].chomp
            self.cart_commands.push({:command => "SYSTEM_SSH_KEY_ADD", :args => [key]})
          elsif line.start_with?('APP_SSH_KEY_ADD: ')
            response = line['APP_SSH_KEY_ADD: '.length..-1].chomp
            cart,key = response.split(' ')
            cart = cart.gsub(".", "-")
            self.cart_commands.push({:command => "APP_SSH_KEY_ADD", :args => [cart, key]})
          elsif line.start_with?('APP_ENV_VAR_REMOVE: ')
            key = line['APP_ENV_VAR_REMOVE: '.length..-1].chomp
            self.cart_commands.push({:command => "APP_ENV_VAR_REMOVE", :args => [key]})
          elsif line.start_with?('ENV_VAR_ADD: ')
            env_var = line['ENV_VAR_ADD: '.length..-1].chomp.split('=')
            self.cart_commands.push({:command => "ENV_VAR_ADD", :args => [env_var[0], env_var[1]]})
          elsif line =~ /^BROKER_AUTH_KEY_(ADD): /
            if $1 == 'ADD'
              self.cart_commands.push({:command => "BROKER_KEY_ADD", :args => []})
            end
          else
            #self.debugIO << line
          end
        else # exitcode != 0
          self.debugIO << line
          Rails.logger.debug "DEBUG: server results: " + line
        end
      end
    end
  end
end





