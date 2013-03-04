module Console
  module CommunityAware
    extend ActiveSupport::Concern

    included do
      helper_method :community_base_url, :community_path, :community_url if respond_to?(:helper_method)
    end

    protected
      def community_path
        community_base_url('')
      end

      def community_url
        community_path
      end

      def community_base_url(path, opts=nil)
        "#{Console.config.community_url || "#{request.scheme}://#{request.host}:8118/"}#{path}#{opts && opts[:anchor] ? "##{opts[:anchor]}" : ""}"
      end
  end
end
