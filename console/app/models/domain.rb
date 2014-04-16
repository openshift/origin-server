#
# The REST API model object representing the domain, which may contain multiple applications.
#
class Domain < RestApi::Base
  include Membership

  class Member < ::Member
    belongs_to :domain
    self.schema = ::Member.schema
  end

  schema do
    string :id
    string :suffix
    integer :application_count
    integer :available_gears
    integer :max_storage_per_gear
    boolean :private_ssl_certificates
  end

  has_many :allowed_gear_sizes, :class_name => String
  has_one :gear_counts, :class_name => as_indifferent_hash
  has_one :usage_rates, :class_name => as_indifferent_hash

  has_members :as => Domain::Member

  on_exit_code(158, :on_invalid => (Domain::UserAlreadyHasDomain = Class.new(ActiveResource::ResourceInvalid)))
  on_exit_code(103, :on_invalid => (Domain::AlreadyExists = Class.new(ActiveResource::ResourceInvalid)))

  custom_id :id, true # domain id is mutable, FIXME rename method to primary_key
  alias_attribute :name, :id

  singular_resource

  has_many :applications
  def applications
    @applications ||= Application.find :all, { :params => child_prefix_options, :as => as }
  end
  def find_application(name, opts={})
    Application.find :one, { :params => child_prefix_options.merge(:name => name), :as => as}.deep_merge!(opts)
  end

  #FIXME should have an observer pattern that clears cached associations on reload
  def reload
    @applications = nil
    super
  end

  def user
    User.find :one, :as => as
  end

  def destroy_recursive
    connection.delete(element_path({:force => true}.merge(prefix_options)), self.class.headers)
  end

  def child_prefix_options
    { :domain_id => id }
  end

  class Capabilities < OpenStruct
  end

  def capabilities
    Domain::Capabilities.new({
      :allowed_gear_sizes => allowed_gear_sizes,
      :max_gears => nil,
      :consumed_gears => nil,
      :gears_free => available_gears,
      :gears_free? => available_gears > 0,
      :max_storage_per_gear => max_storage_per_gear,
      :private_ssl_certificates => !!private_ssl_certificates
    }).tap do |c|
      if !gear_counts.nil?
        c.consumed_gears = gear_counts.values.sum
        c.max_gears      = available_gears + c.consumed_gears
      end
    end
  rescue
    nil
  end

  def allowed_gear_sizes
    Array(attributes[:allowed_gear_sizes]).map(&:to_sym)
  end

  def allows_gears?
    allowed_gear_sizes.present?
  end

  def has_available_gears?
    available_gears > 0
  end

  def can_rename?
    if readonly?
      false
    elsif application_count.present?
      application_count == 0
    else
      applications.count == 0
    end
  end

  # FIXME: Temporary until multiple domains are supported
  def self.find_one(options)
    domain = first(options)
    raise RestApi::ResourceNotFound.new(model_name, nil) if domain.nil?
    domain
  end
end
