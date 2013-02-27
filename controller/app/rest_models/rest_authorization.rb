class RestAuthorization < OpenShift::Model
  attr_accessor :id, :identity, :token, :note, :created_at, :expires_in, :expires_in_seconds, :links, :scopes

  def initialize(auth, url, nolinks=false)
    [:token, :created_at, :expires_in, :expires_in_seconds, :note].each{ |sym| self.send("#{sym}=", auth.send(sym)) }
    self.id = auth._id
    self.scopes = auth.scopes
    self.identity = auth.identity_id

    self.links = {
      "GET" => Link.new("Get authorization", "GET", URI::join(url, "user/authorizations/#{id}")),
      "UPDATE" => Link.new("Update authorization", "PUT", URI::join(url, "user/authorizations/#{id}"), [
        Param.new("note", "string", "A note to remind you what this token is for."),
      ]),
      "DELETE" => Link.new("Delete authorization", "DELETE", URI::join(url, "user/authorizations/#{id}"))
    } unless nolinks
  end

  def to_xml(options={})
    options[:tag_name] = "authorization"
    super(options)
  end
end
