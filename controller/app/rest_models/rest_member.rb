class RestMember < OpenShift::Model
  attr_accessor :id, :type, :login, :role, :explicit_role, :from, :owner
  
  def initialize(member, owner, url, nolinks=false)
    self.type = to_type(member._type)
    self.login = member.name || "#{type}:#{member.id}"
    @name = member.name if member.name != login # only display name if it differs from login
    self.id = member._id
    self.role = member.role
    self.explicit_role = member.explicit_role
    if member.from
      self.from = member.from.map do |m| 
        f = {:type => m.first, :role => m.last}
        f[:id] = m[1] if m.length > 2
        f
      end
    end
    self.owner = owner
=begin
    self.links = {
      "GET" => Link.new("Get SSH key", "GET", URI::join(url, "user/keys/#{name}")),
      "UPDATE" => Link.new("Update SSH key", "PUT", URI::join(url, "user/keys/#{name}"), [
        Param.new("type", "string", "Type of Key", SshKey.get_valid_ssh_key_types]),
        Param.new("content", "string", "The key portion of an rsa key (excluding ssh key type and comment)"),
      ]),
      "DELETE" => Link.new("Delete SSH key", "DELETE", URI::join(url, "user/keys/#{name}"))
    } unless nolinks
=end
  end

  def to_type(type)
    case type
    when 'team' then 'team'
    else             'user'
    end
  end

  def to_xml(options={})
    options[:tag_name] = "member"
    super(options)
  end
end