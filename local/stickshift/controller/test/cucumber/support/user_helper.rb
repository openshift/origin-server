#require '/var/www/stickshift/broker/config/environment'

module UserHelper
  #
  # Obtain a unique username from S3.
  #
  #   reserved_usernames = A list of reserved names that may
  #     not be in the global store
  #
  def get_unique_username(reserved_usernames=[])
    result={}

    loop do
      # Generate a random username
      chars = ("1".."9").to_a
      namespace = "unit" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
      login = "cucumber-test+#{namespace}@example.com"
      #has_txt = !StickShift::DnsService.instance.namespace_available?(namespace)
      has_txt = namespace_available?(namespace)

      unless has_txt or reserved_usernames.index(login)
        result[:login] = login
        result[:namespace] = namespace
        break
      end
    end

    return result
  end

  def register_user(login, password)
    command = "#{$user_register_script} -u #{login} -p #{password}"
    run command
  end

end
World(UserHelper)
