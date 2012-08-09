#
# The REST API model object representing an SSH public key.
#
class Key < RestApi::Base
  #self.element_name = 'key'
  #self.primary_key = 'name'

  class DuplicateName < ActiveResource::ResourceConflict ; end
  on_exit_code 120, DuplicateName

  schema do
    string :name, 'type', :content, :raw_content
  end
  custom_id :name, true
  def id # support ID for legacy code which retrieves keys by .id
    name
  end

  # type is a method on Object in 1.8.7 and must be overriden so that the attribute 
  # will be read (method_missing is how ActiveResource attributes are looked up)
  def type
    @attributes[:type]
  end

  belongs_to :user

  attr_alters :raw_content, [:content, :type]
  # Raw content is decomposed into content and type
  def raw_content=(contents)
    if contents
      parts = contents.split
      case parts.length
      when 1
        self.type = nil
        self.content = parts[0]
      when 2
        if /^ssh-(rsa|dss)$/.match(parts[0])
          self.type, self.content = parts
        else
          self.type = nil
          self.content = parts[0]
        end
      when 3
        self.type, self.content = parts
      end
    end
    super
  end

  validates :name, :presence => true, :allow_blank => false
  #validates_format_of 'type',
  #                    :with => /^ssh-(rsa|dss)$/,
  #                    :message => "is not ssh-rsa or ssh-dss"
  validates :content, :presence => true, :allow_blank => false

  Inf = 1.0/0.0 # Replace with Float::INFINITY in 1.9 ruby
  def make_unique!(format='key %s')
    unless persisted? && @update_id == name
      keys = Key.find(:all, :as => as)
      if keys.any? {|k| k.name == name }
        self.name = format % (2..keys.length+2).find do |i|
          not keys.any? {|k| k.name == format % i}
        end
      end
    end
    self
  end

  def display_content
    if content.length > 20
      "#{content[1..8]}..#{content[-8..-1]}"
    else
      content
    end
  end

  #
  # Until the empty default key is attached from domain, ignore in lists
  #
  def default?
    'default' == name
  end
  def empty_default?
    default? and (!content or content.blank? or 'nossh' == content)
  end

  class << self
    def default(options=nil)
      Key.find('default', options)
    end
  end
end
