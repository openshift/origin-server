require 'net/ssh'
class KeyContentValidator < ActiveModel::Validator
   def validate(record)
     # If it is not a key type that we have a size requirement for or 
     # an empty key check it for validity. We have other validation checks
     # for empty keys.
     unless SshKey.get_minimum_ssh_key_size(record.type).join.to_i == 0
       begin
         key = Net::SSH::KeyFactory.load_data_public_key(record.type + " " + record.content)
       rescue NotImplementedError
         record.errors.add(:content, "Invalid key type. Please check the validity of the key and try again.")
       rescue
         record.errors.add(:content, "Failed to load/validate key. Please check the validity of the key and try again.")
       else
         if key.is_a?(OpenSSL::PKey::RSA)
           unless key.n.num_bytes * 8 >= SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i
             record.errors.add(:content, "Invalid RSA key size.  Must be greater or equal to #{SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i}.")
           end
         elsif key.is_a?(OpenSSL::PKey::DSA)
           unless key.public_key.pub_key.num_bytes * 8 >= SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i
             record.errors.add(:content, "Invalid DSA key size.  Must be greater or equal to #{SshKey.get_minimum_ssh_key_size(key.ssh_type).join.to_i}.")
           end
         end
       end
     end
   end
end

