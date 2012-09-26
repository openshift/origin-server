module Console
  module VERSION #:nocov:
    STRING = Gem.loaded_specs['openshift-origin-console'].version.to_s rescue '0.0.0'
  end
end
