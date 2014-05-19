#
# A model with the ability to add and remove membership.  Membership changes may require
# work to be done on distributed resources associated with this model, or on child resources.
#
module Membership
  extend ActiveSupport::Concern
  include AccessControlled

  included do
    validate :explicit_members_are_limited
    validate :team_members_are_limited
  end
 

  def has_member?(o)
    members.include?(o)
  end

  def role_for(member_or_id)
    id = member_or_id.respond_to?(:_id) ? member_or_id._id : member_or_id
    type = (member_or_id.class.member_type if member_or_id.class.respond_to?(:member_type)) || CloudUser.member_type
    members.inject(default_role){ |r, m| return (m.role || r) if m._id === id and m.type === type; r }
    nil
  end

  def default_role
    self.class.default_role
  end

  def member_ids
    members.map(&:_id)
  end

  def add_members(*args)
    from = args.pop if args.length > 1 && args.last.is_a?(Array)
    role = args.pop if args.last.is_a?(Symbol) && args.length > 1
    changing_members do
      args.flatten(1).map do |arg|
        m = self.class.to_member(arg)
        m.add_grant(role || m.role || default_role, from) if from || !m.role?
        if exists = m.find_in(members) rescue nil
          exists.merge(m)
        else
          members.push(m)
        end

        m.submembers.map(&:clone).map(&:clear).each do |submember|
          submember.add_grant(role || m.role || default_role, m.as_source)
          if exists = submember.find_in(members) rescue nil
            exists.merge(submember)
          else
            members.push(submember)
          end
        end

      end
    end
    self
  end

  # Removes given members, if they exist in the resource's membership
  def remove_members(*args)
    from = args.pop if args.last.is_a?(Symbol) || (args.length > 1 && args.last.is_a?(Array))
    return self if args.empty?
    changing_members do
      args.flatten(1).each do |arg|
        m = self.class.to_member(arg)
        
        if exists = m.find_in(members) rescue nil
          exists.delete if exists.remove_grant(from)
        end

        if source = m.as_source
          members.select{|m| m.remove_grant(source) }.map(&:delete)
        end
      end
    end
    self
  end

  def reset_members
    changing_members do
      members.clear
    end
    self
  end

  # FIXME
  # Mongoid has no support for adding/removing embedded relations in bulk in 3.0.
  # Until that is available, provide a block form that signals that the set of operations
  # is intended to be deferred until a save on the document is called, and track
  # the ids that are removed and added
  def changing_members(&block)
    _assigning do
      ids = members.map(&:to_key)
      instance_eval(&block)
      new_ids = members.map(&:to_key)

      added, removed = (new_ids - ids), (ids - new_ids)

      @original_members ||= ids
      @members_added ||= []; @members_removed ||= []
      @members_added -= removed; @members_removed -= added
      @members_added.concat(added).uniq!; @members_removed.concat(removed & @original_members).uniq!
    end
    self
  end

  def has_member_changes?
    @members_added.present? || @members_removed.present? || members.any?(&:role_changed?) || members.any?(&:explicit_role_changed?) || members.any?(&:from_changed?)
  end

  def explicit_members_are_limited
    max = Rails.configuration.openshift[:max_members_per_resource]
    if members.target.count(&:explicit_role?) > max
      errors.add(:members, "You are limited to #{max} members per #{self.class.model_name.humanize.downcase}")
    end
  end
  
  def team_members_are_limited
    max = Rails.configuration.openshift[:max_teams_per_resource]
    if members.target.count(&:team?) > max
      errors.add(:members, "You are limited to #{max} teams per #{self.class.model_name.humanize.downcase}")
    end
  end

  #
  # Helper method for processing role changes
  #
  def change_member_roles(changed_roles, source)
    changed_roles.each do |(id, type, old_role, new_role)|
      if m = members.detect{ |m| m._id == id && m.type == type }
        m.update_grant(new_role, source)

        m.submembers.map(&:clone).map(&:clear).each do |submember|
          if exists = submember.find_in(members) rescue nil
            exists.update_grant(new_role, m.as_source)
          else
            submember.add_grant(new_role, m.as_source)
            members.push(submember)
          end
        end
      end
    end
    self
  end

  def with_member_change_parent_op(member_change_parent_op)
    old_member_change_parent_op = @_member_change_parent_op
    @_member_change_parent_op = member_change_parent_op
    yield
  ensure
    @_member_change_parent_op = old_member_change_parent_op
  end

  protected
    def parent_membership_relation
      relations.values.find{ |r| r.macro == :belongs_to }
    end

    def default_members
      if parent = parent_membership_relation
        p = send(parent.name)
        p.inherit_membership.each{ |m| role = m.role; m.clear.add_grant(role || default_role, parent.name) } if p
      end || []
    end

    #
    # The list of member ids that changed on the object.
    # This method needs to be implemented in any class that includes Membership
    #
    def members_changed(added, removed, changed_roles, parent_op)
      Rails.logger.error "The members_changed method needs to be implemented in the specific classes\n  #{caller.join("\n  ")}"
      raise "Membership changes not implemented"
    end

    def handle_member_changes
      # v1 formats (type was nil for user)
      # added:   [ [_id, role, type, name], ...]
      # changed: [ [_id, old_role, new_role], ...]
      # removed: [ _id, ...]

      # v2 formats:
      # added:   [ [_id, type, role, name], ...]
      # changed: [ [_id, type, old_role, new_role], ...]
      # removed: [ [_id, type], ...]

      if persisted?
        changing_members{ members.concat(default_members) } if members.empty?
        if has_member_changes?
          changed_roles = members.select{ |m| m.role_changed? && !(@members_added && @members_added.include?(m.to_key)) }.map{ |m| [m._id, m.type].concat(m.role_change) }
          added_roles = members.select{ |m| @members_added && @members_added.include?(m.to_key) }.map{ |m| [m._id, m.type, m.role, m.name] }
          members_changed(added_roles, @members_removed, changed_roles, @_member_change_parent_op)
          @original_members, @members_added, @members_removed = nil
        end
      else
        members.concat(default_members)
      end
      @_children = nil # ensure the child collection is recalculated
      true
    end

  module ClassMethods
    def has_members(opts={})
      embeds_many :members, as: :access_controlled, cascade_callbacks: true
      before_save :handle_member_changes

      index({'members._id' => 1, 'members.t' => 1})

      class_attribute :default_role, instance_accessor: false

      if through = opts[:through].to_s.presence
        define_method :parent_membership_relation do
          relations[through]
        end
      end
      self.default_role = opts[:default_role] || :view
    end

    #
    # Overrides AccessControlled#accessible
    #
    def accessible(to)
      scope_limited(to, accessible_criteria(to))
    end

    def accessible_criteria(to)
      with_member(to)
    end

    def with_member(to)
      where(:'members._id' => to.is_a?(String) ? to : to._id, :'members.t' => to.respond_to?(:member_type) ? to.member_type : nil)
    end

    def to_member(arg)
      if Member === arg
        arg
      else
        if arg.respond_to?(:as_member)
          arg.as_member
        elsif arg.is_a?(Array)
          Member.new{ |m| m._id = arg[0]; m.type = arg[1]; m.role = arg[2]; m.name = arg[3] }
        else
          Member.new{ |m| m._id = arg; m.type = CloudUser.member_type; }
        end
      end
    end
  end
end