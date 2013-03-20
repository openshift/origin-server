Time::DATE_FORMATS.merge!({
  :pretty_date => lambda do |time| 
    time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end,
  :billing_date => lambda do |time| 
    time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}, %Y")
  end,
  :billing_date_no_year => lambda do |time| 
    time.strftime("%B #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end,
  :credit_card => lambda do |time| 
    time.strftime("%m/%Y")
  end,
  :pretty_time => lambda do |time| 
    time.strftime("%A, %b #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end,
})
