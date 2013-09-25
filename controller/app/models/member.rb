class Member
  include Mongoid::Document
  embedded_in :access_controlled, polymorphic: true

  # The ID this member refers to.
  field :_id, :as => :_id, type: Moped::BSON::ObjectId, default: -> { nil }
  # The type of this member.  All members are currently CloudUsers
  field :_type, type: String, default: ->{ self.class.name if hereditary? }
  # The name of this member, denormalized
  field :n,  :as => :name, type: String
  #
  # An array of implicit grants, where each grant is an array of uniquely
  # distinguishing elements ending with the role granted to the member.
  #
  # e.g.: [
  #   ['domain', :view],
  #   ['team', '345', :admin],
  # ]
  #
  # indicates the current member has an implicit role (denormalized) on this resource
  # from the domain (singleton) and from a team with id 345.  The team 345 must itself
  # be listed as a member of this resource.
  #
  field :f,  :as => :from, type: Array
  # A role for the member on this resource
  field :r,  :as => :role, type: Symbol
  # When multiple grants are present, this value stores the role assigned to the
  # member directly on this resource (vs the value of the role inherited by an
  # implicit grant.
  field :e, :as => :explicit_role, type: Symbol

  attr_accessible :_id, :role

  validates_presence_of :_id, :message => 'You must provide a valid id for your member.'
  validates_presence_of :role, :message => "must be one of : #{Role.all.join(', ')}"

  def ==(other)
    _id == other._id && (member_type === other || self.class == other.class)
  end

  def clone
    m = super
    m._id = _id
    m
  end

  #
  # A membership is explicit if there are no implicit grants, or if an explicit_role
  # has been set.  If there are no implicit grants, the explicit_role value must be
  # equal to the role.
  #
  def explicit_role?
    from.blank? || super
  end
  def explicit_role
    super || (from.blank? ? role : nil)
  end

  #
  # Given two members, calculate the effective role of the two together.  Use when
  # a member already exists for the current resource.
  #
  def merge(other)
    if other.from.blank?
      if from.blank?
        self.explicit_role = nil
        self.role = other.role
      else
        self.explicit_role = other.role
        self.role = Role.higher_of(other.role, role)
      end
    else
      self.explicit_role = role if from.blank?
      self.from ||= []
      self.from.concat(Array(other.from)).uniq!
      self.role = effective_role
    end
    self
  end

  #
  # Remove a specific grant of membership - will return true if the member should be
  # removed because there is no longer an explicit role or any remaining grants.
  #
  def remove_grant(source=nil)
    if source.nil?
      # remove the explicit grant
      if from.blank?
        true
      elsif explicit_role
        self.role = effective_role
        self.explicit_role = nil
        false
      end
    else
      # remove an implicit grant
      if from
        source = to_source(source)
        from.delete_if{ |f| f[0...-1] == source }
      end
      if from.blank?
        if self.e
          self.role = explicit_role
          self.explicit_role = nil
          false
        else
          true
        end
      else
        self.role = effective_role
        false
      end
    end
  end

  def add_grant(role, source=nil)
    if source.nil?
      if from.blank?
        self.role = role
      else
        self.explicit_role = role
        self.role = effective_role
      end
    else
      self.from ||= []
      source = to_source(source)
      from.delete_if{ |f| f[0...-1] == source }
      from << (source << role)
      self.role = effective_role
    end
    self
  end

  def update_grant(role, source)
    if from.present?
      source = to_source(source)
      if grant = from.find{ |f| f[0...-1] == source }
        grant[-1] = role
        self.role = effective_role
        true
      end
    end
  end

  def clear
    self.from = nil
    self.explicit_role = nil
    self.role = nil
    self
  end

  def member_type
    CloudUser
  end

  def _type=(obj)
    super obj == 'user' ? nil : obj
  end

  protected
    def effective_role
      Role.higher_of(explicit_role, *from.map(&:last))
    end

    def to_source(source)
      source = source.is_a?(Array) ? source.dup : [source]
      source[0] = source[0].to_s unless source[0].is_a? String
      source
    end
end