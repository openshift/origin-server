##
# @api REST
# Describes an required parameter for a REST API endpoint
# @see Link
#
# Example:
#   ```
#   <link>
#     <rel>Update domain</rel>
#     <method>PUT</method>
#     <href>https://broker.example.com/broker/rest/domains/localns</href>
#     <required-params>
#       <param>
#         <name>id</name>
#         <type>string</type>
#         <description>Name of the domain</description>
#         <valid-options/>
#         <invalid-options/>
#       </param>
#     </required-params>
#     <optional-params/>
#   </link>
#   ```
#
# @!attribute [r] name
#   @return [String] Parameter name
# @!attribute [r] type
#   @return [String] Parameter type
# @!attribute [r] description
#   @return [String] Parameter description
# @!attribute [r] valid_options
#   @return [Array<String>] List of valid options
# @!attribute [r] invalid_options
#   @return [Array<String>] List of options that are not valid
class Param < OpenShift::Model
  attr_accessor :name, :type, :description, :valid_options, :invalid_options

  def initialize(name=nil, type=nil, description=nil, valid_options=nil, invalid_options=nil)
    self.name = name
    self.type = type
    self.description = description
    self.valid_options = Array(valid_options)
    self.invalid_options = Array(invalid_options)
  end
end

