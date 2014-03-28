module AdminConsole
  module ApplicationHelper
    include AdminConsole::Html5BoilerplateHelper

    def product_title
      'OpenShift Origin'
    end

    def gear_group_cartridges(app, group_instance)
      group_instance.all_component_instances.map { |component_instance|
      cart = component_instance.cartridge

      # Handling the case when component_properties is an empty array
      # This can happen if the mongo document is copied and pasted back and saved using a UI tool
      if component_instance.component_properties.nil? or component_instance.component_properties.is_a? Array
        component_instance.component_properties = {}
      end

      component_instance.component_properties.merge({
        :is_sparse => component_instance.is_sparse?,
        :id => component_instance.id,
        :name => cart.name,
        :display_name => cart.display_name,
        :tags => cart.categories
      })
    }
    end
  end
end
