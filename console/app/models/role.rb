class Role < RestApi::Base
  singular_resource
  schema do
    string :id, :name
  end

  def category
    case id
    when 'admin'
      'Admins'
    when 'edit'
      'Editors'
    when 'view'
      'Viewers'
    else
      name
    end
  end

  def self.role_options_ascending
    role_options_descending.reverse
  end

  def self.role_options_descending
    [
      Role.new(:id => 'admin', :name => 'Admin'),
      Role.new(:id => 'edit',  :name => 'Edit' ),
      Role.new(:id => 'view',  :name => 'View' )
    ]
  end

  def self.role_descriptions_descending
    [
      ['Can administer','admin'],
      ['Can edit','edit'],
      ['Can view','view'],
      ['Remove', 'none']
    ]
  end
end
