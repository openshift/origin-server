module StickShift
  class UserModel < Model

    def initialize()
      super()
    end

    def self.find(login, id)
      hash = DataStore.instance.find(self.name,login,id)
      return nil unless hash

      hash_to_obj(hash)
    end

    def self.find_by_uuid(uuid)
      hash = DataStore.instance.find_by_uuid(self.name,uuid)
      return nil unless hash

      hash_to_obj(hash)
    end

    def self.find_all(login, f=nil)
      hash_list = DataStore.instance.find_all(self.name,login,f)
      return [] if hash_list.empty?
      hash_list.map! do |hash|
        hash_to_obj(hash)
      end
    end

    def delete(login)
      id_var = self.class.pk || "uuid"
      DataStore.instance.delete(self.class.name, login, instance_variable_get("@#{id_var}"))
    end

    def save(login)
      id_var = self.class.pk || "uuid"
      if persisted?
        if self.class.requires_update_attributes
          changed_attrs = {}
          unless changes.empty?
            changes.each do |key, value|
              changed_attrs[key] = value[1] unless self.class.excludes_attributes.include? key.to_sym
            end
          end
          self.class.requires_update_attributes.each do |key|
            key = key.to_s
            value = instance_variable_get("@#{key}")
            if value.kind_of?(StickShift::Model)
              changed_attrs[key] = value.attributes(true)
            else
              changed_attrs[key] = value
            end
          end
          DataStore.instance.save(self.class.name, login, instance_variable_get("@#{id_var}"), changed_attrs) unless changed_attrs.empty?
        else
          DataStore.instance.save(self.class.name, login, instance_variable_get("@#{id_var}"), self.attributes(true))
        end
      else
        DataStore.instance.create(self.class.name, login, instance_variable_get("@#{id_var}"), self.attributes(true))
      end
      @previously_changed = changes
      @changed_attributes.clear
      @new_record = false
      @persisted = true
      @deleted = false
      self
    end

    protected

    def self.json_to_obj(json)
      obj = self.new.from_json(json)
      obj.reset_state
      obj
    end

    def self.hash_to_obj(hash)
      obj = self.new
      obj.attributes=hash
      obj.reset_state
      obj
    end

  end
end
