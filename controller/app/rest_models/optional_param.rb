##
# @api REST
# Describes an optional parameter for a REST API endpoint
# @see Link
#
# Example:
#   ```
#   <link>
#     <rel>Create new application</rel>
#     <method>POST</method>
#     <href>https://broker.example.com/broker/rest/domains/localns/applications</href>
#     <required-params>
#       ...
#     </required-params>
#     <optional-params>
#       ...
#       <optional-param>
#         <name>scale</name>
#         <type>boolean</type>
#         <description>Mark application as scalable</description>
#         <valid-options>
#           <valid-option>true</valid-option>
#           <valid-option>false</valid-option>
#         </valid-options>
#         <default-value>false</default-value>
#       </optional-param>
#       ...
#     </optional-params>
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
# @!attribute [r] default_value
#   @return [String] Default option value
class OptionalParam < OpenShift::Model
  attr_accessor :name, :type, :description, :valid_options, :default_value

  def initialize(name=nil, type=nil, description=nil, valid_options=nil, default_value=nil)
    self.name = name
    self.type = type
    self.description = description
    self.valid_options = Array(valid_options)
    self.default_value = default_value
  end
end
