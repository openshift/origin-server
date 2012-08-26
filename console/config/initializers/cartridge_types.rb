known_types = YAML::load(IO.read(Console.config.cartridge_type_metadata))
known_types.each{ |t| t[:description] = t.delete(:description_html).html_safe if t[:description_html].present? }

Rails.application.config.cartridge_types_by_name = known_types.inject({}) { |i, t| i[t[:name]] = t; t.freeze; i }.freeze

