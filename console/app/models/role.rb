class Role < RestApi::Base
  singular_resource
  schema do
    string :id, :name
  end

  def self.description_for(role)
    case role
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

  def self.role_descriptions(include_blank=false)
    if include_blank
      @blank_descriptions ||= [
        ['No access', 'none'],
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
end
