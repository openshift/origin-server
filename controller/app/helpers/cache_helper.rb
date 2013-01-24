module CacheHelper
  # Helper method to maintain cached informtaion
  # 
  # == Parameters:
  # key::
  #   Cache key
  # opts::
  #   Cache options
  # block::
  #   Code block to run and cache output
  #
  # == Returns:
  # Cached output of code block
  def self.get_cached(key, opts={})
    unless Rails.configuration.action_controller.perform_caching
      if block_given?
        return yield
      end
    end

    val = Rails.cache.read(key)
    unless val
      if block_given?
        val = yield
        if val
          Rails.cache.write(key, val, opts)
        end
      end
    end

    return val
  end
end
