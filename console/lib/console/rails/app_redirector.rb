module ActionDispatch::Routing
  class Mapper
    module ApplicationRedirector
      #
      # Provide a redirect helper which allows the user to redirect 
      # to an application relative url.
      #
      # Usage (in routes.rb):
      #
      #   match 'power' => app_redirect('platform')
      #   match 'email_confirm_express' => app_redirect {|p, req| "email_confirm?#{req.query_string}"}
      #
      # will generate a redirect from /<appbaseuri>/power to /<appbaseuri>/platform, regardless of
      # whether Rails is run as a root site or as a subsite.  Should respond to the same arguments as
      # redirect.
      #
      def app_redirect(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        path = args.shift || block
        path_proc = path.is_a?(Proc) ? path : lambda do |params| 
          path % params
        end
        block = lambda do |params, req|
          newargs = [params]
          newargs << req if path_proc.arity > 1
          uri = URI.join('http://localhost', "#{req.script_name}/", path_proc.call(*newargs))
          Rails.logger.debug "URI #{uri}, #{req.script_name}"
          if uri.host == 'localhost'
            uri.request_uri
          else
            uri
          end
        end

        redirect(block, options)
      end
    end
    include ApplicationRedirector
  end
end
