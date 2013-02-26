##
# Application descriptor API
# @api REST
class DescriptorsController < BaseController
  ##
  # Retrieve application descriptor
  # 
  # URL: /domains/:domain_id/applications/:application_id/descriptor
  #
  # Action: GET
  #
  # Example Descriptor:
  #   ```
  #   Name: appname
  #   Requires:
  #   - mysql-5.1
  #   - mongodb-2.2
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
    domain_id = params[:domain_id]
    application_id = params[:application_id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_DESCRIPTOR")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound      
      return render_error(:not_found, "Application '#{application_id}' not found", 101, "SHOW_DESCRIPTOR")
    end
    render_success(:ok, "descriptor", application.to_descriptor.to_yaml, "SHOW_DESCRIPTOR", "Show descriptor for application '#{application_id}' for domain '#{domain_id}'")
  end
end
