require_relative '../test_helper'

class MemberTest < ActiveSupport::TestCase

  setup do 
  end

  teardown do
  end

  [nil, :view, :edit, :admin].each do |explicit_role|
    [nil, :view, :edit, :admin].each do |from_role|
      [nil, :view, :edit, :admin].each do |other_explicit_role|
        [nil, :view, :edit, :admin].each do |other_from_role|
          test "test merging a member with #{other_explicit_role.to_s.inspect} explicit role and #{other_from_role.to_s.inspect} from role into a member with a #{explicit_role.to_s.inspect} explicit role and #{from_role.to_s.inspect} from role" do
            if (explicit_role || from_role) && (other_explicit_role || other_from_role)
              # Set up the first member
              m = Member.new
              if explicit_role and from_role
                # To get an explicit and implicit role, we have to create and merge
                m.add_grant(explicit_role)
                m2 = Member.new
                m2.add_grant(from_role, [:team, 1])
                m.merge(m2) 
              elsif explicit_role
                m.add_grant(explicit_role) 
              elsif from_role
                m.add_grant(from_role, [:team, 1])
              end
              assert_equal explicit_role, m.explicit_role
              assert_equal Role.higher_of(*[explicit_role, from_role].compact), m.role
              assert_equal 0, Array(m.from).length if from_role.blank?
              assert_equal 1, Array(m.from).length if from_role.present?

              # Set up the second member
              other = Member.new
              if other_explicit_role and other_from_role
                # To get an explicit and implicit role, we have to create and merge
                other.add_grant(other_explicit_role)
                other_2 = Member.new
                other_2.add_grant(other_from_role, [:team, 1])
                other.merge(other_2) 
              elsif other_explicit_role
                other.add_grant(other_explicit_role) 
              elsif other_from_role
                other.add_grant(other_from_role, [:team, 1])
              end
              assert_equal other_explicit_role, other.explicit_role
              assert_equal Role.higher_of(*[other_explicit_role, other_from_role].compact), other.role
              assert_equal 0, Array(other.from).length if other_from_role.blank?
              assert_equal 1, Array(other.from).length if other_from_role.present?

              m.merge(other)

              # The other roles should be used if present
              highest_role = Role.higher_of(*[other_explicit_role || explicit_role, other_from_role || from_role].compact)

              assert_equal other_explicit_role || explicit_role, m.explicit_role
              assert_equal highest_role, m.role
              assert_equal 0, Array(m.from).length if from_role.blank? and other_from_role.blank?
              assert_equal 1, Array(m.from).length if from_role.present? or other_from_role.present?
            end
          end
        end
      end
    end
  end

end
