class User
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :emailAddress, :password, :passwordConfirmation, :termsAccepted
  validates_format_of :emailAddress, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i, :message => 'Invalid email address'
  validates_length_of :password, :minimum => 6, :message => 'Passwords must be at least 6 characters'  
  validates_each :termsAccepted do |record, attr, value|
    record.errors.add attr, 'Terms must be accepted' if value != '1'
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
end
