require 'formtastic'

module Console
  module Formtastic
    class BootstrapFormBuilder < ::Formtastic::SemanticFormBuilder

      # In Rails 3.2, the builder is initialized before the form_tag is generated so
      # we can add helper logic
      #def initialize(object_name, object, template, options, proc)
      #  options[:html] ||= {}
      #  class_names = options[:html][:class] ? options[:html][:class].split(" ") : []

      #  class_names << 'form-inline' if options[:simple]
      #  options[:html][:class] = class_names.join(" ")

      #  super
      #end

      # remove once all forms converted
      def new_forms_enabled?
        true
      end

      def current_layout
        layout = template.controller.send(:_layout)
        if layout.instance_of? String
          layout
        else
          File.basename(layout.identifier).split('.').first
        end
      end

      # set the default css class
      def buttons(*args)
        return super unless new_forms_enabled?

        options = args.extract_options!
        options[:class] ||= @options[:simple] ? 'btn-toolbar' : 'form-actions'
        super *(args << options)
      end

      def loading(*args)
        image = template.instance_variable_get(:@loader_image) || template.image_path('loader.gif')
        template.content_tag(:img, nil, :alt => 'Working...', 'data-loading' => 'true', :class => 'icon-loading', :style => 'display: none', :src => image)
      end

      # override tag creation
      def field_set_and_list_wrapping(*args, &block) #:nodoc:
        return super unless new_forms_enabled?

        contents = args.last.is_a?(::Hash) ? '' : args.pop.flatten
        html_options = args.extract_options!

        legend  = html_options.dup.delete(:name).to_s
        legend %= parent_child_index(html_options[:parent]) if html_options[:parent]
        legend  = template.content_tag(:legend, template.content_tag(:span, Formtastic::Util.html_safe(legend))) unless legend.blank?

        if block_given?
          contents = if template.respond_to?(:is_haml?) && template.is_haml?
            template.capture_haml(&block)
          else
            template.capture(&block)
          end
        end

        # Ruby 1.9: String#to_s behavior changed, need to make an explicit join.
        contents = contents.join if contents.respond_to?(:join)
        fieldset = template.content_tag(:fieldset,
          Formtastic::Util.html_safe(legend) << Formtastic::Util.html_safe(contents), #changed
          html_options.except(:builder, :parent)
        )
        template.concat(fieldset) if block_given? && !Formtastic::Util.rails3?
        fieldset
      end

      def semantic_errors(*args)
        return super unless new_forms_enabled?
        html_options = args.extract_options!
        html_options[:class] ||= 'alert alert-error unstyled errors'

        full_errors = args.inject([]) do |array, method|
          attribute = localized_string(method, method.to_sym, :label) || humanized_attribute_name(method)
          @object.errors[method.to_sym].each do |error|
            if error.present?
              error = [attribute, error].join(" ") unless error[0,1] == error[0,1].upcase
              array << error
            end
          end
          array
          #errors = Array(@object.errors[method.to_sym]).to_sentence
          #errors.present? ? array << [attribute, errors].join(" ") : array ||= []
        end
        full_errors << @object.errors[:base] unless html_options.delete(:not) == :base
        full_errors.flatten!
        full_errors.compact!
        return nil if full_errors.blank?
        #html_options[:class] ||= "errors"
        template.content_tag(:ul, html_options) do
          Formtastic::Util.html_safe(full_errors.map { |error| template.content_tag(:li, error) }.join)
        end
      end

      def inline_errors_for(method, options = {}) #:nodoc:
        return super unless new_forms_enabled?
        if render_inline_errors?
          errors = error_keys(method, options).map do |x|
            attribute = localized_string(x, x.to_sym, :label) || humanized_attribute_name(x)
            @object.errors[x].map do |error| 
              (error[0,1] == error[0,1].upcase) ? error : [attribute, error].join(" ")
            end
          end.flatten.compact.uniq
          send(:"error_#{inline_errors}", [*errors], options) if errors.any?
        else
          nil
        end
      end

      def error_list(errors, options = {}) #:nodoc:
        return super unless new_forms_enabled?
        error_class = options[:error_class] || default_inline_error_class
        template.content_tag(:p, errors.join(' ').untaint, :class => error_class)
      end

      # change from li to div.control-group, move hints/errors into the input block
      def input(method, options = {})
        return super unless new_forms_enabled?

        options = options.dup # Allow options to be shared without being tainted by Formtastic

        options[:required] = method_required?(method) unless options.key?(:required)
        options[:as]     ||= default_input_type(method, options)

        html_class = [ options[:as], (options[:required] ? :required : :optional), 'control-group' ] #changed

        wrapper_html = options.delete(:wrapper_html) || {}
        if has_errors?(method, options)
          html_class << 'error'

          wrapper_html[:"data-server-error"] = "server-error"
        end
        wrapper_html[:id]  ||= generate_html_id(method)
        wrapper_html[:class] = (html_class << wrapper_html[:class]).flatten.compact.join(' ')

        if options[:input_html] && options[:input_html][:id]
          options[:label_html] ||= {}
          options[:label_html][:for] ||= options[:input_html][:id]
        end

        # moved hint/error output inside basic_input_helper

        template.content_tag(:div, Formtastic::Util.html_safe(inline_input_for(method, options)), wrapper_html) #changed to move to basic_input_helper
      end

      def parts(method, options, &block)
        input_parts = (custom_inline_order[options[:as]] || inline_order).dup
        input_parts = input_parts - [:errors, :hints] if options[:as] == :hidden
        input_parts.map do |type|
          (:input == type) ? yield : send(:"inline_#{type}_for", method, options)
        end.compact.join("\n")
      end

      # wrap contents in div.controls
      def basic_input_helper(form_helper_method, type, method, options) #:nodoc:
        return super unless new_forms_enabled?

        html_options = options.delete(:input_html) || {}
        html_options = default_string_options(method, type).merge(html_options) if [:numeric, :string, :password, :text, :phone, :search, :url, :email].include?(type)
        field_id = generate_html_id(method, "")
        html_options[:id] ||= field_id
        label_options = options_for_label(options)
        label_options[:class] ||= 'control-label'
        label_options[:for] ||= html_options[:id]

        control_content = parts(method, options) do
          send(respond_to?(form_helper_method) ? form_helper_method : :text_field, method, html_options)
        end

        label(method, label_options) <<
          template.content_tag(:div, Formtastic::Util.html_safe(control_content), {:class => 'controls'}) #added class
        # end changes
      end

      # wrap select in a control
      def select_input(method, options)
        return super unless new_forms_enabled?

        html_options = options.delete(:input_html) || {}
        html_options[:multiple] = html_options[:multiple] || options.delete(:multiple)
        html_options.delete(:multiple) if html_options[:multiple].nil?

        reflection = reflection_for(method)
        if reflection && [ :has_many, :has_and_belongs_to_many ].include?(reflection.macro)
          html_options[:multiple] = true if html_options[:multiple].nil?
          html_options[:size]     ||= 5
          options[:include_blank] ||= false
        end
        options = set_include_blank(options)
        input_name = generate_association_input_name(method)
        html_options[:id] ||= generate_html_id(input_name, "")

        select_html = if options[:group_by]
          # The grouped_options_select is a bit counter intuitive and not optimised (mostly due to ActiveRecord).
          # The formtastic user however shouldn't notice this too much.
          raw_collection = find_raw_collection_for_column(method, options.reverse_merge(:find_options => { :include => options[:group_by] }))
          label, value = detect_label_and_value_method!(raw_collection, options)
          group_collection = raw_collection.map { |option| option.send(options[:group_by]) }.uniq
          group_label_method = options[:group_label_method] || detect_label_method(group_collection)
          group_collection = group_collection.sort_by { |group_item| group_item.send(group_label_method) }
          group_association = options[:group_association] || detect_group_association(method, options[:group_by])

          # Here comes the monster with 8 arguments
          grouped_collection_select(input_name, group_collection,
                                         group_association, group_label_method,
                                         value, label,
                                         strip_formtastic_options(options), html_options)
        else
          collection = find_collection_for_column(method, options)

          select(input_name, collection, strip_formtastic_options(options), html_options)
        end

        label_options = options_for_label(options).merge(:input_name => input_name)
        label_options[:for] ||= html_options[:id]
        label(method, label_options) <<
          template.content_tag(:div, Formtastic::Util.html_safe(select_html), {:class => 'controls'})
      end

      def boolean_input(method, options)
        parts(method, options){ super }
      end

      # remove the button wrapper
      def commit_button(*args)
        return super unless new_forms_enabled?

        options = args.extract_options!
        text = options.delete(:label) || args.shift

        if @object && (@object.respond_to?(:persisted?) || @object.respond_to?(:new_record?))
          if @object.respond_to?(:persisted?) # ActiveModel
            key = @object.persisted? ? :update : :create
          else # Rails 2
            key = @object.new_record? ? :create : :update
          end

          # Deal with some complications with ActiveRecord::Base.human_name and two name models (eg UserPost)
          # ActiveRecord::Base.human_name falls back to ActiveRecord::Base.name.humanize ("Userpost")
          # if there's no i18n, which is pretty crappy.  In this circumstance we want to detect this
          # fall back (human_name == name.humanize) and do our own thing name.underscore.humanize ("User Post")
          if @object.class.model_name.respond_to?(:human)
            object_name = @object.class.model_name.human
          else
            object_human_name = @object.class.human_name                # default is UserPost => "Userpost", but i18n may do better ("User post")
            crappy_human_name = @object.class.name.humanize             # UserPost => "Userpost"
            decent_human_name = @object.class.name.underscore.humanize  # UserPost => "User post"
            object_name = (object_human_name == crappy_human_name) ? decent_human_name : object_human_name
          end
        else
          key = :submit
          object_name = @object_name.to_s.send(label_str_method)
        end

        text = (localized_string(key, text, :action, :model => object_name) ||
                ::Formtastic::I18n.t(key, :model => object_name)) unless text.is_a?(::String)

        button_html = options.delete(:button_html) || {}
        button_html.merge!(:class => [button_html[:class] || 'btn btn-primary', key].compact.join(' '))

        #remove need for wrapper
        #wrapper_html_class = ['btn-primary'] #changed # TODO: Add class reflecting on form action.
        #wrapper_html = options.delete(:wrapper_html) || {}
        #wrapper_html[:class] = (wrapper_html_class << wrapper_html[:class]).flatten.compact.join(' ')

        accesskey = (options.delete(:accesskey) || default_commit_button_accesskey) unless button_html.has_key?(:accesskey)
        button_html = button_html.merge(:accesskey => accesskey) if accesskey
        submit(text, button_html) # no wrapper
      end
    end
  end
end
