module Membership
  extend ActiveSupport::Concern

  included do
    has_many :members

    def members
      attributes[:members] || []
    end

    def owner?
      members.find{ |m| m.id == api_identity_id && m.owner? } if api_identity_id
    end

    def admin?
      has_role?('admin')
    end

    def editor?
      has_role?('admin','edit')
    end

    def readonly?
      has_role?('read')
    end

    def has_role?(*roles)
      roles.present? and api_identity_id.present? and members.find{ |m| m.id == api_identity_id && roles.include?(m.role) }
    end

    def update_members(members)
      self.messages.clear
      body = {
        :members => members.map do |m| 
          {
            :id => m.id,
            :login => m.login,
            :role => m.role
          }
        end
      }
      response = post(:members, nil, body.to_json)
      self.messages = extract_messages(response)
      response.is_a? Net::HTTPOK
    rescue 
      # TODO handle known errors, use server-provided message when possible
      self.messages = [RestApi::Base::Message.new(0, nil, 'error', $!.to_s)]
      false
    end

  end
end
