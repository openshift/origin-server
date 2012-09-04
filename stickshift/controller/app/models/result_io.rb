# Class to collect results from component level operations.
# @!attribute [r] debugIO
#   @return [StringIO] Collects debug output from the component hooks.
# @!attribute [r] resultIO
#   @return [StringIO] Collects stdout output from the component hooks.
# @!attribute [r] messageIO
#   @return [StringIO] Collects messages that the component hooks that need to be displayed to the user.
# @!attribute [r] errorIO
#   @return [StringIO] Collects stderr output from the component hooks.
# @!attribute [r] appInfoIO
#   @return [StringIO] ???
# @!attribute [r] data
#   @return [String] ???
# @!attribute [r] exitcode
#   @return [FixNum] Returns the exitcode from the component hooks.
# @!attribute [r] exitcode
#   @return [FixNum] Returns the exitcode from the component hooks.
# @!attribute [r] cart_commands
#   @return [Array] Directives returned by the component hooks processed in {Application#process_commands}
# @!attribute [r] cart_properties
#   @return [Array] Properties returned by component hooks processed in {ComponentInstance#process_properties}
class ResultIO
  attr_accessor :debugIO, :resultIO, :messageIO, :errorIO, :appInfoIO, :exitcode, :data, :cart_commands, :cart_properties
  
  def initialize
    @debugIO = StringIO.new
    @resultIO = StringIO.new
    @messageIO = StringIO.new
    @errorIO = StringIO.new
    @appInfoIO = StringIO.new
    @data = ""
    @exitcode = 0
    @cart_commands = []
    @cart_properties = {}
  end
  
  # Append a {ResultIO} to the current instance.
  # @note the last non-zero exitcode is retained
  def append(resultIO)
    self.debugIO << resultIO.debugIO.string
    self.resultIO << resultIO.resultIO.string
    self.messageIO << resultIO.messageIO.string
    self.errorIO << resultIO.errorIO.string
    self.appInfoIO << resultIO.appInfoIO.string
    self.cart_commands += resultIO.cart_commands
    self.cart_properties = resultIO.cart_properties.merge(self.cart_properties)
    self.exitcode = resultIO.exitcode if resultIO.exitcode != 0
    self.data += resultIO.data
    self
  end
  
  
  #CART_DATA: PROXY_HOST=504605c568-localns.example.com
  #CART_DATA: PROXY_PORT=35531
  #CART_DATA: HOST=127.0.250.1
  #CART_DATA: PORT=3306
  #CLIENT_RESULT: 
  #CLIENT_RESULT: MySQL 5.1 database added.  Please make note of these credentials:
  #CLIENT_RESULT: 
  #CLIENT_RESULT:    Root User: admin
  #CLIENT_RESULT:    Root Password: K-8R3IIgd2Q5
  #CLIENT_RESULT:    Database Name: myapp
  #CLIENT_RESULT: 
  #CLIENT_RESULT: Connection URL: mysql://504605c568-localns.example.com:35531/
  #CLIENT_RESULT: MySQL gear-local connection URL: mysql://127.0.250.1:3306/
  #CLIENT_RESULT: 
  #CART_PROPERTIES: connection_url=mysql://504605c568-localns.example.com:35531/
  #CART_PROPERTIES: username=admin
  #CART_PROPERTIES: password=K-8R3IIgd2Q5
  #CART_PROPERTIES: database_name=myapp
  #APP_INFO: Connection URL: mysql://504605c568-localns.example.com:35531/
  #
  #
  #elsif line =~ /^CART_DATA: /
  #  result.data << line['CART_DATA: '.length..-1]
  #elsif line =~ /^CART_PROPERTIES: /
  #  property = line['CART_PROPERTIES: '.length..-1].chomp.split('=')
  #  result.cart_properties[property[0]] = property[1]
  
  # Returns the output of this {ResultIO} object as a string. Primarily used for debug output.
  def to_s
    str = "--DEBUG--\n#{@debugIO.string}\n" +
          "--RESULT--\n#{@resultIO.string}\n" +
          "--MESSAGE--\n#{@messageIO.string}\n" +
          "--ERROR--\n#{@errorIO.string}\n" +
          "--APP INFO--\n#{@appInfoIO.string}\n" +
          "--CART COMMANDS--\n#{@cart_commands.join("\n")}\n" +
          "--CART PROPERTIES--\n#{@cart_properties.inspect}\n" +
          "--DATA--\n#{@data}\n" +
          "--EXIT CODE--\n#{@exitcode}\n"          
  end

  # Returns the output of this {ResultIO} object as a JSON string. Used by {LegacyReply}
  def to_json(*args)
    reply = LegacyReply.new
    reply.debug = @debugIO.string
    reply.messages = @messageIO.string
    if !@errorIO.string.empty?
      reply.result = @errorIO.string
    else
      reply.result = @resultIO.string
    end
    reply.data = @data
    reply.exit_code = @exitcode
    reply.to_json(*args)
  end
end
