class RestKey < OpenShift::Model
  attr_accessor :name, :content, :type, :links
  
  def initialize(name, content, type, url, nolinks=false)
    self.name= name
    self.content = content
    self.type = type || Key::DEFAULT_SSH_KEY_TYPE

    self.links = {
      "GET" => Link.new("Get SSH key", "GET", URI::join(url, "user/keys/#{name}")),
      "UPDATE" => Link.new("Update SSH key", "PUT", URI::join(url, "user/keys/#{name}"), [
        Param.new("type", "string", "Type of Key", Key::VALID_SSH_KEY_TYPES),
        Param.new("content", "string", "The key portion of an ssh key (excluding ssh type and comment)"),
      ]),
      "DELETE" => Link.new("Delete SSH key", "DELETE", URI::join(url, "user/keys/#{name}"))
    } unless nolinks
  end
  
  def to_xml(options={})
    options[:tag_name] = "key"
    super(options)
  end

end
