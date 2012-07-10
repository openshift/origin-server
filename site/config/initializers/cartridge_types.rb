known_types = YAML::load(IO.read(File.expand_path(File.join('config', 'cartridge_types.yml'))))

Rails.application.config.cartridge_types_by_name = known_types.inject({}) { |i, t| i[t[:name]] = t; t.freeze; i }.freeze

