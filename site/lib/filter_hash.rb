module FilterHash
  def self.safe_values(h)
    tests = filters
    out = nil
    h.keys.each do |k|
      key_s = k.to_s.downcase
      (out ||= h.dup)[k] = '[FILTERED]' if tests.any?{ |s| key_s.include?(s) }
    end
    out || h
  end
  protected
    def self.filters
      @filters ||= Rails.application.config.filter_parameters.map(&:to_s).map(&:downcase).uniq
    end
end
