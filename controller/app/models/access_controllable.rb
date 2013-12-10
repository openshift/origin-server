module AccessControllable
  extend ActiveSupport::Concern

  def as_member(role=nil)
    Member.new do |u|
      u._id = self._id
      u.type = self.class.member_type
      u.name = name
      u.role = role
    end
  end

  def member_of?(o)
    o.members.include? self
  end

  module ClassMethods
    def member_as(s)
      @member_as = s.to_s
    end

    def member_type
      @member_as
    end

    def members_of(acl, &block)
      self.in(
        _id:
          if Membership === acl
            acl.members.inject([]) do |a, m|
              next a unless member_type == m.type
              (next a unless yield m) if block_given?
              a << m._id
              a
            end
          else
            acl
          end
      )
    end
  end
end