# encoding: UTF-8

module Console::DateHelper
  def collapse_dates(date1, date2, opts={})
    year = opts[:year] ? ", %Y " : ""
    day1 = opts[:ordinalize] ? ActiveSupport::Inflector.ordinalize(date1.day) : date1.day
    day2 = opts[:ordinalize] ? ActiveSupport::Inflector.ordinalize(date2.day) : date2.day
    if date1.year == date2.year and date1.month == date2.month
      date1.strftime("%B #{day1}–#{day2}#{year}")
    elsif date1.year == date2.year
      date1.strftime("%B #{day1}") + " – " + date2.strftime("%B #{day2}#{year}")
    else
      date1.strftime("%B #{day1}#{year}") + " – " + date2.strftime("%B #{day2}#{year}")
    end
  end
end
