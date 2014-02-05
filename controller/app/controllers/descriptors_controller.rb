##
# Application descriptor API
# @api REST
class DescriptorsController < BaseController
  before_filter :get_application
  ##
  # Retrieve application descriptor
  #
  # Action: GET
  #
  # Example Descriptor:
  #   ```
  #   Name: appname
  #   Requires:
  #   - mysql-5.1
  #   - mongodb-2.4
  #   - php-5.4
  #   Group-Overrides:
  #   - components:
  #     - comp: php-5.4
  #       cart: php-5.4
  #     min_gears: 1
  #     max_gears: -1
  #   ```
  # @return [RestReply<YAML>] Application Descriptor in YAML format
  def show
    render_success(:ok, "descriptor", @application.to_descriptor.to_yaml, "Show descriptor for application '#{@application.name}' for domain '#{@application.domain_namespace}'")
  end
end
