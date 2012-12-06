class ResultIO
  attr_accessor :debugIO, :resultIO, :messageIO, :errorIO, :appInfoIO, :exitcode, :data, :cart_commands, :cart_properties, :hasUserActionableError
  
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
    @hasUserActionableError = false
  end
  
  def append(resultIO)
    self.debugIO << resultIO.debugIO.string
    self.resultIO << resultIO.resultIO.string
    self.messageIO << resultIO.messageIO.string
    self.errorIO << resultIO.errorIO.string
    self.appInfoIO << resultIO.appInfoIO.string
    self.cart_commands += resultIO.cart_commands
    self.cart_properties = resultIO.cart_properties.merge(self.cart_properties)
    self.exitcode = resultIO.exitcode
    self.data += resultIO.data
    self.hasUserActionableError = self.hasUserActionableError && resultIO.hasUserActionableError
    self
  end
  
  def to_s
    str = "--DEBUG--\n#{@debugIO.string}\n" +
          "--RESULT--\n#{@resultIO.string}\n" +
          "--MESSAGE--\n#{@messageIO.string}\n" +
          "--ERROR--\n#{@errorIO.string}\n" +
          "--APP INFO--\n#{@appInfoIO.string}\n" +
          "--CART COMMANDS--\n#{@cart_commands.join("\n")}\n" +
          "--CART PROPERTIES--\n#{@cart_properties.inspect}\n" +
          "--DATA--\n#{@data}\n" +
          "--EXIT CODE--\n#{@exitcode}\n" +          
          "--USER ACTIONABLE--\n#{@hasUserActionableError}\n"
  end
  
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
