class RestUser < StickShift::Model
  attr_accessor :login, :links
  
  def initialize(cloud_user, url)
    self.login = cloud_user.login
    @links = {
      "LIST_KEYS" => Link.new("Get SSH keys", "GET", URI::join(url, "user/keys")),
      "ADD_KEY" => Link.new("Add new SSH key", "POST", URI::join(url, "user/keys"), [
        Param.new("name", "string", "Name of the application"),
        Param.new("type", "string", "Type of Key", ["ssh-rsa", "ssh-dss"]),
        Param.new("content", "string", "The key portion of an rsa key (excluding ssh-rsa and comment)"),
      ]),
    }
  end
  
  def to_xml(options={})
    options[:tag_name] = "user"
    super(options)
  end
end
