class Quickstart < RestApi::Base
  include RestApi::Cacheable
  allow_anonymous
  singular_resource
  
  instance_variable_set(:@connection, nil)

  schema do
    string :id, :name, :href, :initial_git_url, :initial_git_branch
    string :website
    string :body, :summary
    integer :priority
  end

  Disabled = Class.new(StandardError)
  SearchDisabled = Class.new(StandardError)

  alias_attribute :display_name, :name
  alias_attribute :description, :summary

  def name
    entity_decoded(super)
  end

  def priority
    super.to_i rescue 0
  end

  def provider
    (attributes[:provider] || :community).to_sym
  end

  def learn_more_url
    URI.join(self.class.site, href).to_s if href
  end

  def tags
    @tags ||= ApplicationType.user_tags(tags_from(attributes[:tags])) + admin_tags
  end

  def updated
    @updated ||= Time.at(attributes[:updated].to_i)
  end

  def cartridges_spec
    entity_decoded(attributes[:cartridges])
  end

  def scalable
    true
  end
  alias_method :scalable?, :scalable

  def may_not_scale
    (tags.include?(:not_scalable) rescue false)
  end
  alias_method :may_not_scale?, :may_not_scale

  def >>(application)
    #application.cartridges = cartridges
    application.initial_git_url = initial_git_url
    application
  end

  cache_method :find_every, :expires_in => 10.minutes
  cache_method :find_single, :expires_in => 5.minutes

  class << self
    def promoted(opts={})
      all({:from => (api_links[:list] or raise Disabled)}.merge(opts))
    rescue Disabled
      []
    end

    def search(terms, opts={})
      all(opts.merge(
        :from => (api_links[:search] or raise SearchDisabled),
        :params => {
          (api_links[:search_param] or raise SearchDisabled) => terms
        }
      ))
    rescue SearchDisabled
      terms.downcase!
      promoted(opts).select do |q|
        q.description.downcase.include?(terms) or
          q.display_name.downcase.include?(terms) or
          (q.tags.include?(terms.to_sym) rescue false)
      end
    end

    def disabled?
      !api_links[:list] rescue true
    end

    def site
      api_links[:site] or RestApi::Info.site
    end
    def prefix_parameters
      {}
    end

    def reset!
      @api_links = nil
    end

    protected
      def collection_path(*args)
        api_links[:list] rescue super
      end
      def element_path(id, prefix_options = {}, query_options = nil)
        api_links[:get].gsub(/:id/, id.to_s) rescue super
      end
      def api_links
        @api_links ||= begin
          info = RestApi::Info.cached.find :one
          {
            :site => (URI.join(info.link("LIST_QUICKSTARTS"), '/') rescue nil),
            :list => (info.link("LIST_QUICKSTARTS").path rescue nil),
            :get => (info.link("SHOW_QUICKSTART").path rescue nil),
            :search => (info.link("SEARCH_QUICKSTARTS").path rescue nil),
            :search_param => (info.required_params('SEARCH_QUICKSTARTS').first['name'] rescue nil),
          }
        end
      end

      def instantiate_record(record, *args)
        super record.is_a?(Array) ? record.first : record, *args
      end
  end

  protected
    def admin_tags
      @admin_tags ||= tags_from(attributes[:admin_tags])
    end

  private
    def tags_from(s)
      (s.is_a?(Array) ? s : ((s || '').split(','))).map(&:strip).map(&:downcase).map(&:to_sym)
    end
end
