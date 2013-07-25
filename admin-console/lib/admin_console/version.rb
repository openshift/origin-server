module AdminConsole
  module VERSION
    STRING = Gem.loaded_specs['openshift-origin-admin-console'].version.to_s
  rescue
    '0.0.0'
  end
end
