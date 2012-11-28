class GearsController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]

    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "LIST_GEARS") if !domain || !domain.hasAccess?(@cloud_user)

    @domain = domain.namespace
    app = get_application(app_id)
    return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'",
                        101, "LIST_GEARS") unless app
   
    @app = app.name
    begin 
      app_gears_info = []
      gears = app.group_instances.uniq.map{ |ginst| ginst.gears }.flatten

      has_proxy_cart = false
      rx1 = Regexp.new(/^PROXY_HOST=(.*)/)
      rx2 = Regexp.new(/^PROXY_PORT=(.*)/)
      rx3 = Regexp.new(/^PORT=(.*)/)

      gears.each do |gear|
        comp_list = []
        gear.configured_components.each do |cname|
          comp_inst = app.comp_instance_map[cname]
          has_proxy_cart = true if app.proxy_cartridge and cname.include? app.proxy_cartridge
          next if comp_inst.parent_cart_name == app.name

          begin
            res = gear.show_port(comp_inst).data

            m = rx1.match(res)
            proxy_host = m[1] if m 
            m = rx2.match(res)
            proxy_port = m[1].to_i if m 
            m = rx3.match(res)
            internal_port = m[1].to_i if m 
          rescue
            #ignore
          end

          comp_info = { 
                       'name' => comp_inst.parent_cart_name, 
                       'proxy_host' => proxy_host,
                       'proxy_port' => proxy_port,
                       'internal_port' => internal_port
                      }
          if comp_inst.cart_properties and comp_inst.cart_properties.length > 0
            comp_info = comp_inst.cart_properties.merge comp_info
          end
          comp_list.push comp_info
        end

        gear_info = RestGear.new(gear.uuid, comp_list)
        app_gears_info.push gear_info
      end
      render_success(:ok, "gears", app_gears_info, "LIST_GEARS",
                     "Showing gears for application '#{app_id}' for domain '#{domain_id}'")
    rescue Exception => e
      return render_exception(e, "LIST_GEARS")
    end
  end
end
