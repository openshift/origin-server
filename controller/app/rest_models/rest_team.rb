class RestTeam < OpenShift::Model
  attr_accessor :id, :name, :global, :maps_to, :links

  def initialize(team, url, nolinks=false, include_members=false)
    [:id, :name, :maps_to].each{ |sym| self.send("#{sym}=", team.send(sym)) }

    self.global = team.owner_id ? false : true

    if include_members
      @members = team.members.map{ |m| RestMember.new(m, team.owner_id == m._id, url, team, nolinks) }
    end

    unless nolinks
      self.links = {
          "GET" => Link.new("Get team", "GET", URI::join(url, "team/#{id}")),
          "ADD_MEMBER" => Link.new("add member", "POST", URI::join(url, "team/#{id}/members"),
            [Param.new("role", "string", "The role the user should have on the team", ["view"])],
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute")]),
          "LIST_MEMBERS" => Link.new("list members", "GET", URI::join(url, "team/#{id}/members")),
          "UPDATE_MEMBERS" => Link.new("Add or remove one or more members to or from this team.", "PATCH", URI::join(url, "team/#{id}/members"),
            [Param.new("role", "string", "The role the user should have on the team", ["view", "none"])],
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute"),
            OptionalParam.new("members", "Array", "An array of users to add with corresponding role. e.g. {'members': [{'login': 'foo', 'type': 'user', 'role': 'view'}, {'id': '5326534e2046fde9d3000001', 'type': 'user', 'role': 'none'}]}")
            ]
          ),
          "LEAVE" => Link.new("Leave team", "DELETE", URI::join(url, "team/#{id}/members/self")),
          "DELETE" => Link.new("Delete team", "DELETE", URI::join(url, "team/#{id}"))
        }

      if self.global
        self.links.delete_if {|k, v| ["ADD_MEMBER", "UPDATE_MEMBERS", "LEAVE", "DELETE"].include? k}
      end
    end
  end

  def to_xml(options={})
    options[:tag_name] = "team"
    super(options)
  end
end
