class RestTeam < OpenShift::Model
  attr_accessor :id, :name, :links

  def initialize(team, url, nolinks=false)
    [:id, :name].each{ |sym| self.send("#{sym}=", team.send(sym)) }
    unless nolinks
      self.links = {
          "GET" => Link.new("Get team", "GET", URI::join(url, "team/#{id}")),
          "UPDATE" => Link.new("Update team", "PUT", URI::join(url, "team/#{id}"), 
            [Param.new("name", "string", "New name of the team")]),
          "ADD_MEMBER" => Link.new("add member", "POST", URI::join(url, "team/#{id}/members"), nil,
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute")]),
          "LIST_MEMBERS" => Link.new("list members", "GET", URI::join(url, "team/#{id}/members")),
          "UPDATE_MEMBERS" => Link.new("Add or remove one or more members to/from this team.", "PATCH", URI::join(url, "team/#{id}/members"),
            [Param.new("role", "string", "The role the user should have on the team", ["view", "none"])],
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute")]
          ),
          "LEAVE" => Link.new("Leave team", "DELETE", URI::join(url, "team/#{id}/members/self")),
          "DELETE" => Link.new("Delete team", "DELETE", URI::join(url, "team/#{id}"))
        }
    end
  end

  def to_xml(options={})
    options[:tag_name] = "team"
    super(options)
  end
end
