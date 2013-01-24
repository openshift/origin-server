module UtilHelper
  def deep_copy(value)
    if value.is_a?(Hash)
      result = value.clone
      value.each{|k, v| result[k] = deep_copy(v)}
      result
    elsif value.is_a?(Array)
      result = value.clone
      result.clear
      value.each{|v| result << deep_copy(v)}
      result
    else
      value
    end
  end
end
