#
# The REST API model object representing an SSH public key.
#
class Key < RestApi::Base
  #self.element_name = 'key'
  #self.primary_key = 'name'

  schema do
    string :name, 'type', :content, :raw_content
  end
  custom_id :name, true
  # type is a method on Object in 1.8.7 and must be overriden
  def type
    @attributes[:type]
  end

  belongs_to :user
  self.prefix = "#{RestApi::Base.site.path}/user/"

  attr_set_on_load :raw_content
  # Raw content is decomposed into content and type
  def raw_content=(contents)
    if contents
      parts = contents.split
      case parts.length
      when 1
        self.content = parts[0]
      when 2
        if /^ssh-(rsa|dss)$/.match(parts[0])
          self.type = parts[0]
          self.content = parts[1]
        else
          self.content = parts[0]
        end
      when 3
        self.type = parts[0]
        self.content = parts[1]
      end
    end
    super
  end

  validates :name, :length => {:maximum => 50},
                   :presence => true,
                   :allow_blank => false
  #validates_format_of 'type',
  #                    :with => /^ssh-(rsa|dss)$/,
  #                    :message => "is not ssh-rsa or ssh-dss"
  validates :content, :length => {:maximum => 2048},
                    :presence => true,
                    :allow_blank => false

  def validate_ssh(ssh)
    type_regex = /^ssh-(rsa|dss)$/
    key_regex =  /^[A-Za-z0-9+\/]+[=]*$/
    type_required = true

    values = { :valid => true }
    parts = ssh.split

    case parts.length
    when 1
      values[:key] = parts[0]
    when 2
      if type_regex.match(parts[0])
        values[:type] = parts[0]
        values[:key] = parts[1]
      else
        values[:key] = parts[0]
        values[:comment] = parts[1]
      end
    when 3
      values[:type] = parts[0]
      values[:key] = parts[1]
      values[:comment] = parts[2]
    end

    if type_required && !values[:type]
      values[:valid] = false
    end

    if values[:type] && !type_regex.match(values[:type])
      values[:valid] = false
    end

    if values[:key] && !key_regex.match(values[:key])
      values[:valid] = false
    end
    values
  end
end
