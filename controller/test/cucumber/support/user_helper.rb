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

      #TODO Should we check for unique ns here?
      unless reserved_usernames.index(login)
        result[:login] = login
        result[:namespace] = namespace
        break
      end
    end

    return result
  end

  def register_user(login, password)
    command = $user_register_script_format % [login, password]
    run command
  end

  def set_max_domains(login, max_domains)
    command = "/usr/sbin/oo-admin-ctl-user -l #{login} --setmaxdomains #{max_domains}"
    run command
  end

end
World(UserHelper)
