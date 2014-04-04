class Role < RestApi::Base
  singular_resource
  schema do
    string :id, :name
  end

  def self.description_for(role)
    case role.to_s
    when 'admin'
      'Can administer'
    when 'edit'
      'Can edit'
    when 'view'
      'Can view'
    else
      role.to_s.humanize
    end
  end

  def self.role_descriptions(include_blank=false, has_team_role=false)
    if include_blank && has_team_role
      @blank_descriptions_with_team ||= [
        ['Team access only', 'none'],
        ['Can view (+ team access)','view'],
        ['Can edit (+ team access)','edit'],
        ['Can administer (+ team access)','admin']
      ]
    elsif include_blank
      @blank_descriptions ||= [
        ['No role', 'none'],
        ['Can view','view'],
        ['Can edit','edit'],
        ['Can administer','admin']
      ]
    else
      @descriptions ||= [
        ['Can view','view'],
        ['Can edit','edit'],
        ['Can administer','admin']
      ]
    end
  end

  def self.higher_of(*args)
    ROLES[args.map{ |r| ROLES.index(r.to_s) }.compact.max]
  rescue
    nil
  end

  private
    ROLES = ['view', 'edit', 'admin'].freeze
end
