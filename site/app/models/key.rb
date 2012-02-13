#
# The REST API model object representing an SSH public key.
#
class Key < RestApi::Base
  self.element_name = 'key'

  schema do
    string :name, 'type', :content
  end
  def id() name end

  belongs_to :user
  self.prefix = "#{RestApi::Base.site.path}/user/"
  def type
    @attributes[:type]
  end

  validates :name, :length => {:maximum => 50},
                   :presence => true,
                   :allow_blank => false
  validates_format_of 'type',
                      :with => /^ssh-(rsa|dss)$/,
                      :message => "is not ssh-rsa or ssh-dss"
  validates :content, :length => {:maximum => 2048},
                    :presence => true,
                    :allow_blank => false
end
