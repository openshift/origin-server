require 'uri'

module OpenShift
  module Git
    #
    # This spec will start the application with an empty Git repository.
    #
    EMPTY_CLONE_SPEC = "empty"

    #
    # Return true if this clone specification should create an empty repository
    # 
    def self.empty_clone_spec?(url)
      EMPTY_CLONE_SPEC == url
    end

    #
    # Allowed schemes for Git clone.
    #
    ALLOWED_SCHEMES = %w{git git@ http https ftp ftps rsync}
    ALLOWED_NODE_SCHEMES = ALLOWED_SCHEMES + ['file']

    #
    # Check an incoming Git clone spec against a list of allowed
    # schemes and ranges.  If valid, return an tuple with a 
    # valid clone spec, and the optional fragment.  Return nil
    # if the spec is not allowed, otherwise raise 
    # URI::InvalidURIError if the input is not a valid URI.
    #
    def self.safe_clone_spec(url, schemes=ALLOWED_SCHEMES)
      return [EMPTY_CLONE_SPEC, nil] if empty_clone_spec?(url)
      uri = URI.parse(url)
      return nil unless schemes.include?(uri.scheme)
      fragment = uri.fragment
      uri.fragment = nil
      uri = uri.to_s.gsub(%r(\Afile:/(?=[^/])), 'file:///') if uri.scheme == "file"
      [uri.to_s, fragment]
    rescue URI::InvalidURIError
      # Allow [user]@<host>:<path>.git[#commit]
      if schemes.include?('git@') && %r{\A([\w\d\-_\.+]+@[\w\d\-_\.+]+:[\w\d\-_\.+%/]+\.git)(?:#([\w\d\-_\.\^~]+))?\Z}i.match(url)
        [$1, $2]
      else
        raise
      end
    end

    #
    # Return a clone specification that can be safely persisted
    # to the database (empty and userinfo are both removed).
    #
    def self.persistable_clone_spec(url)
      return nil if empty_clone_spec?(url)
      uri = URI.parse(url)
      uri.userinfo = nil rescue nil
      uri.to_s
    rescue URI::InvalidURIError
      url
    end
  end
end