Time::DATE_FORMATS.merge!({
  :pretty_date => lambda do |time| 
    time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end,
  :billing_date => lambda do |time| 
    time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y")
  end,
  :credit_card => lambda do |time| 
    time.strftime("%B %Y")
  end,
  :pretty_time => lambda do |time| 
    time.strftime("%A, %b #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end,
})
