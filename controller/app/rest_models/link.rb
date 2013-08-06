##
# @api REST
# Represents a REST API link
#
# Example:
#   ```
#   <link>
#     <rel>Retrieve quickstart with :id</rel>
#     <method>GET</method>
#     <href>https://broker.example.com/broker/rest/quickstarts/:id</href>
#     <required-params>
#       <param>
#         <name>:id</name>
#         <type>string</type>
#         <description>Unique identifier of the quickstart</description>
#         <valid-options/>
#         <invalid-options/>
#       </param>
#     </required-params>
#     <optional-params/>
#   </link>
#   ```
#
# @!attribute [r] rel
#   @return [String] Description of the operation
# @!attribute [r] method
#   @return [String] HTTP method to use for this operation
# @!attribute [r] href
#   @return [String] URI for this operation
# @!attribute [r] required_params
#   @return [Array[Param]] List of required parameters
# @!attribute [r] optional_params
#   @return [Array[OptionalParam]] List of optional parameters
class Link < OpenShift::Model
  attr_accessor :rel, :method, :href, :required_params, :optional_params

  def initialize(rel, method, href, required_params=nil, optional_params=nil)
    self.rel = rel
    self.method = method
    self.href = href.to_s
    self.required_params = Array(required_params)
    self.optional_params = Array(optional_params)
  end
end
