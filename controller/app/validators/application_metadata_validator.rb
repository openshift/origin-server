class ApplicationMetadataValidator < ActiveModel::Validator
  def validate(record)
    meta = record.meta
    if meta.present?
      meta.each_pair do |k,v|
        record.errors.add(:meta, "Key #{k} is not a string") unless k.is_a? String
        if v
          if v.is_a? Array
            record.errors.add(:meta, "The array of values provided for '#{k}' must be strings or numbers") if v.any?{ |o| not (o.is_a?(String) or o.is_a?(Numeric)) }
          else
            record.errors.add(:meta, "Value for '#{k}' must be a string, number, or list of strings and numbers") unless v.is_a?(String) or v.is_a?(Numeric)
          end
        end
      end
      size = BSON.serialize(meta).length
      record.errors.add(:meta, "Application metadata may not be larger than 10KB - currently #{(size/1024).ceil}KB") if size > 10*1024
    end
  end
end
