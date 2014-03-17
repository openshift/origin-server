class RestMember < OpenShift::Model
  attr_accessor :id, :type, :login, :role, :explicit_role, :from, :owner, :links
  
  def initialize(member, owner, url, membership, nolinks=false)
    self.type = to_type(member.type)
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
    unless nolinks
      case membership.class
      when Domain
        url = URI::join(url, "domain/#{membership.namespace}/")
      when Team 
        url = URI::join(url, "team/#{membership.id}/")
      when Application
        url = URI::join(url, "application/#{membership.id}/")
      end
        
      self.links = {
        "GET" => Link.new("Get member", "GET", URI::join(url, "member/#{id}").to_s + (self.type == "team" ? "?type=team" : "")),
        "UPDATE" => Link.new("Update member", "PUT", URI::join(url, "member/#{id}").to_s + (self.type == "team" ? "?type=team" : ""), [
          Param.new("role", "string", "New role for member")]),
        "DELETE" => Link.new("Delete member", "DELETE", URI::join(url, "member/#{id}").to_s + (self.type == "team" ? "?type=team" : ""))
      }
    end
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