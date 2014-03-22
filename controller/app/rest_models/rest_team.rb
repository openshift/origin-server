class RestTeam < OpenShift::Model
  attr_accessor :id, :name, :links

  def initialize(team, url, nolinks=false)
    [:id, :name].each{ |sym| self.send("#{sym}=", team.send(sym)) }
    unless nolinks
      self.links = {
          "GET" => Link.new("Get team", "GET", URI::join(url, "team/#{id}")),
          "ADD_MEMBER" => Link.new("add member", "POST", URI::join(url, "team/#{id}/members"),
            [Param.new("role", "string", "The role the user should have on the team", ["view"])],
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute")]),
          "LIST_MEMBERS" => Link.new("list members", "GET", URI::join(url, "team/#{id}/members")),
          "UPDATE_MEMBERS" => Link.new("Add or remove one or more members to/from this team.", "PATCH", URI::join(url, "team/#{id}/members"),
            [Param.new("role", "string", "The role the user should have on the team", ["view", "none"])],
            [OptionalParam.new("id", "string", "Unique identifier of the user"),
            OptionalParam.new("login", "string", "The user's login attribute"),
            OptionalParam.new("members", "Array", "An array of users to add with corresponding role. e.g. [{\"login\" => \"foo\", \"role\" => \"view\"}, {\"id\" =>\"5326534e2046fde9d3000001\", \"role\" => \"none\" }]")
            ]
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
