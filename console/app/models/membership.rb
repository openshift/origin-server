module Membership
  extend ActiveSupport::Concern

  def members
    mems = attributes[:members] || []
    @me ||= mems.find{ |m| m.id == api_identity_id } if api_identity_id
    @me.me = true if @me
    mems
  end

  def me
    @me ||= members.find{ |m| m.id == api_identity_id } if api_identity_id
    @me.me = true if @me
    @me
  end

  def owner?
    me && me.owner?
  end

  def admin?
    has_role?('admin')
  end

  def editor?
    has_role?('admin','edit')
  end

  def readonly?
    has_role?('view')
  end

  def has_role?(*roles)
    roles.present? and me and roles.include?(me.role)
  end

  def leave
    self.errors.clear
    self.messages.clear
    response = delete(:'members/self', nil)
    self.messages = extract_messages(response)
    response.is_a? Net::HTTPSuccess
  rescue ActiveResource::ConnectionError => e
    if e.respond_to? :response
      set_remote_errors(e.response, true)
    else
      self.messages = [RestApi::Base::Message.new(0, nil, 'error', $!.to_s)]
    end
    false
  end

  # FIXME Refactor this method into a patch_child_collection operation on RestApi::Base
  def update_members(members)
    self.errors.clear
    self.messages.clear
    body = {
      :members => members.map do |m|
        {
          :id => (m.id if m.respond_to? :id),
          :login => (m.login if m.respond_to? :login),
          :role => m.role,
          :type => m.type
        }
      end
    }
    response = post(:members, nil, body.to_json)
    self.messages = extract_messages(response)
    resource = self.class.format.decode(response.body)
    p = child_prefix_options
    if resource.is_a? Array
      self.attributes[:members] = resource.map{ |r| m = self.class.member_resource.new(r, true, p); m.as = as; m }
    else
      m = self.class.member_resource.new(resource, true, p)
      m.as = as
      self.members.delete_if{ |o| o == m }
      self.members << m
    end
    true
  rescue ActiveResource::ConnectionError => e
    if e.respond_to? :response
      @remote_errors = e.response
      load_remote_errors(e.response, false, true, members, :members)
      errors[:members] = "The #{self.class.model_name.humanize.downcase} members could not be updated." if errors.empty?
    end
    false
  end

  module ClassMethods
    def has_members(options={})
      has_many :members, :class_name => options[:as]
      @member_resource = options[:as]
    end
    attr_reader :member_resource
  end
end
