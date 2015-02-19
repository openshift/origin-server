class KeyContentValidator < ActiveModel::Validator
   def validate(record)
     key = Net::SSH::KeyFactory.load_data_public_key(record.type + " " + record.content)
     if key.is_a?(OpenSSL::PKey::RSA)
       unless key.n.num_bytes * 8 >= SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i
         record.errors.add(:content, "Invalid key size.  Must be greater or equal to #{SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i}.")
       end
     elsif key.is_a?(OpenSSL::PKey::DSA)
       unless key.public_key.pub_key.num_bytes * 8 >= SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i
         record.errors.add(:content, "Invalid key size.  Must be greater or equal to #{SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i}.")
       end
     end
   end
end

