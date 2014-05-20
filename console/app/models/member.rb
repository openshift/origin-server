class Member < RestApi::Base
  singular_resource

  attr_accessor :me

  schema do
    string :id, :login, :name, :role, :explicit_role, :type
    boolean :owner
  end

  has_many :from, :class_name => as_indifferent_hash

  validates :login, presence: true, if: "id.blank?"
  validates :role, presence: true

  def name
    super || login
  end

  def type
    super || 'user'
  end

  def from
    Array(super)
  end

  def explicit_role?
    explicit_role.present?
  end

  def team?
    type == 'team'
  end

  def grant_from?(type, id)
    from.detect {|f| f[:type] == type && f[:id] == id}
  end

  def <=>(other)
    [type, name, id] <=> [other.type, other.name, other.id]
  end

  # return the items in the members array corresponding to the team grants this member has
  def teams(members)
    team_ids = from.inject([]) {|ids, f| ids << f[:id] if f[:type] == 'team'; ids }
    if team_ids.present?
      members.select {|m| m.type == 'team' && team_ids.include?(m.id) }
    else
      []
    end
  end

  def self.default_role
    'edit'
  end

  def allowed_roles
    ['view','edit','admin']
  end

  def role_description(role=role)
    in_team = from.any? {|f| f[:type] == 'team' }

    case role.to_s
    when 'admin'
      in_team ? 'Can administer (+ team access)' : 'Can administer'
    when 'edit'
      in_team ? 'Can edit (+ team access)' : 'Can edit'
    when 'view'
      in_team ? 'Can view (+ team access)' : 'Can view'
    when 'none'
      in_team ? 'Team access only' : 'No role'
    else
      role.to_s.humanize
    end
  end

  def allowed_role_descriptions(include_blank=false)
    ((include_blank ? ['none'] : []) + allowed_roles).map {|r| [role_description(r), r] }
  end

end
