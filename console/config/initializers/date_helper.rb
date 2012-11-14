Time::DATE_FORMATS.merge!({
  :pretty_date => lambda do |time| 
    time.strftime("%A, %b #{ActiveSupport::Inflector.ordinalize(time.day)}")
  end
})
