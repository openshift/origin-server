require 'formtastic'

module Console
  module Formtastic
    class BootstrapFormBuilder < ::Formtastic::SemanticFormBuilder
      include ::Formtastic::Util

      def initialize(object_name, object, template, options, proc)
        options[:html] ||= {}
        class_names = options[:html][:class] ? options[:html][:class].split(" ") : []

        class_names << 'form-inline' if options[:simple]
        options[:html][:class] = class_names.join(" ")

        super
      end

      # set the default css class
      def buttons(*args)
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
        contents = args.last.is_a?(::Hash) ? '' : args.pop.flatten
        html_options = args.extract_options!

        legend  = html_options.dup.delete(:name).to_s
        legend %= parent_child_index(html_options[:parent]) if html_options[:parent]
        legend  = template.content_tag(:legend, template.content_tag(:span, ::Formtastic::Util.html_safe(legend))) unless legend.blank?

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
          ::Formtastic::Util.html_safe(legend) << ::Formtastic::Util.html_safe(contents), #changed
          html_options.except(:builder, :parent)
        )
        template.concat(fieldset) if block_given? && !::Formtastic::Util.rails3?
        fieldset
      end

      def semantic_errors(*args)
        html_options = args.extract_options!
        html_options[:class] ||= 'alert alert-error unstyled errors'
        except = Array(html_options.delete(:except))
        # Skip the base here because we will add it later if desired
        except << :base
        desired_keys = args.present? ? args : (@object.errors.keys - except)

        # Loop through all of the aliased attributes and merge them
        unless (aliases = html_options.delete(:alias)).nil?
          aliases.each do |master,_alias|
            if @object.errors.include?(_alias)
              @object.errors[master] |= @object.errors.delete(_alias)
            end
          end
        end

        # Make sure the merged attributes are a flat array
        @object.errors.keys.each do |key|
          @object.errors.set(key, @object.errors[key].flatten.compact.uniq)
        end

        full_errors = desired_keys.inject([]) do |array, method|
          attribute = localized_string(method, method.to_sym, :label) || humanized_attribute_name(method)
          @object.errors[method.to_sym].each do |error|
            if error.present?
              error = [attribute, error].join(" ") unless error[0,1] == error[0,1].upcase
              array << error
            end
          end
          array
        end

        unless Array(html_options.delete(:not)).include?(:base) or args.present?
          base_errors = @object.errors[:base]
          full_errors << base_errors
          with_details = base_errors.length > 1
          html_options[:class] << ' with-alert-details' if with_details
        end
        full_errors.flatten!
        full_errors.compact!
        full_errors.uniq!

        return nil if full_errors.blank?
        #html_options[:class] ||= "errors"

        error_content = template.content_tag(:ul, html_options) do
          if with_details
            html_safe(template.content_tag(:li) do
              html_safe('Unable to complete the requested operation. ') <<
              html_safe(template.content_tag(:a, {:href => '#'}) { 'Show more' })
            end)
          else
            html_safe(full_errors.map { |error| template.content_tag(:li, error) }.join)
          end
        end
        details_content = ''
        if with_details
          details_content = template.content_tag(:pre, {:class => 'alert-details hide'}) do
            template.content_tag(:ul, {:class => 'unstyled'}) do
              html_safe(full_errors.map { |error| template.content_tag(:li, error.strip) }.join)
            end
          end
        end
        error_content + details_content
      end

      def inline_hints_for(method, options) #:nodoc:
        options[:hint] = localized_string(method, options[:hint], :hint)
        return if options[:hint].blank? or options[:hint].kind_of? Hash
        if input_inline?
          @input_inline_hints << options[:hint]
          return nil
        end
        hint_class = options[:hint_class] || default_hint_class
        template.content_tag(:p, ::Formtastic::Util.html_safe(options[:hint]), :class => hint_class)
      end

      def inline_errors_for(method, options = {}) #:nodoc:
        return nil unless render_inline_errors?
        errors = error_keys(method, options).map do |x|
          attribute = localized_string(x, x.to_sym, :label) || humanized_attribute_name(x)
          @object.errors[x].map do |error|
            (error[0,1] == error[0,1].upcase) ? error : [attribute, error].join(" ")
          end
        end.flatten.compact.uniq
        return nil unless errors.any?
        if input_inline?
          @input_inline_errors << errors
          return nil
        end
        send(:"error_#{inline_errors}", [*errors], options)
      end

      def error_list(errors, options = {}) #:nodoc:
        error_class = options[:error_class] || default_inline_error_class
        ensure_dot = lambda { |s| s.strip!; s << '.' unless s.end_with?('.'); s }
        template.content_tag(:p, errors.flatten.map(&ensure_dot).join(' ').untaint, :class => error_class)
      end

      def inputs(*args, &block)
        title = field_set_title_from_args(*args)
        html_options = args.extract_options!
        html_options[:class] ||= "inputs"
        html_options[:name] = title

        if html_options[:autocomplete]
          @old_autocomplete_section = @autocomplete_section
          @autocomplete_section = html_options[:autocomplete]
        end

        if html_options[:for] # Nested form
          inputs_for_nested_attributes(*(args << html_options), &block)
        elsif html_options[:inline]
          @input_inline = true
          @input_inline_errors = []
          @input_inline_hints = []
          fieldset = inline_fields_and_wrapping(*(args << html_options), &block)
          @input_inline = false
          @label = nil
          fieldset
        elsif block_given?
          field_set_and_list_wrapping(*(args << html_options), &block)
        else
          if @object && args.empty?
            args  = association_columns(:belongs_to)
            args += content_columns
            args -= RESERVED_COLUMNS
            args.compact!
          end
          legend = args.shift if args.first.is_a?(::String)
          contents = args.collect { |method| input(method.to_sym) }
          args.unshift(legend) if legend.present?

          field_set_and_list_wrapping(*((args << html_options) << contents))
        end

      ensure
        @autocomplete_section = @old_autocomplete_section
      end

      def inline_fields_and_wrapping(*args, &block)
        contents = args.last.is_a?(::Hash) ? '' : args.pop.flatten
        html_options = args.extract_options!

        html_options.delete(:inline)
        html_class = ['control-group']
        html_class << 'control-group-important' if html_options.delete(:important)

        label = template.content_tag(:label, ::Formtastic::Util.html_safe(html_options.dup.delete(:name).to_s) << required_or_optional_string(html_options.delete(:required)), { :class => 'control-label' }) if html_options[:name]

        # Generate form elements
        if block_given?
          contents = if template.respond_to?(:is_haml?) && template.is_haml?
            template.capture_haml(&block)
          else
            template.capture(&block)
          end
        end

        # Ruby 1.9: String#to_s behavior changed, need to make an explicit join.
        #contents = contents.join if contents.respond_to?(:join)
        unless html_options[:without_errors]
          contents << send(:"error_#{inline_errors}", [*@input_inline_errors], {})
          html_class << 'error' unless @input_inline_errors.empty?
        end

        @input_inline_hints.each do |hint|
          contents << template.content_tag(:p, hint, :class => default_hint_class)
        end

        template.content_tag(:div, ::Formtastic::Util.html_safe(label || '') << template.content_tag(:div, ::Formtastic::Util.html_safe(contents), {:class => 'controls'}), { :class => html_class.join(' ') })
      end

      def input_inline?
        @input_inline
      end

      # change from li to div.control-group, move hints/errors into the input block
      def input(method, options = {})
        options = options.dup # Allow options to be shared without being tainted by Formtastic

        options[:required] = method_required?(method) unless options.key?(:required)
        options[:as]     ||= default_input_type(method, options)

        if (field = options[:autocomplete])
          if (section = @autocomplete_section)
            field = "#{section} #{field}"
          end
          options[:input_html] ||= {}
          options[:input_html][:autocomplete] = field
        end

        html_class = [
          options[:as],
          options[:required] ? :required : :optional,
          'control-group',
        ] #changed
        html_class << 'control-group-important' if options[:important]

        wrapper_html = options.delete(:wrapper_html) || {}
        if has_errors?(method, options)
          html_class << 'error'

          wrapper_html[:"data-server-error"] = "server-error"

          options[:input_html] ||= {}
          options[:input_html][:class] ||= ""
          options[:input_html][:class] << " error"
        end
        wrapper_html[:id]  ||= generate_html_id(method)
        wrapper_html[:class] = (html_class << wrapper_html[:class]).flatten.compact.join(' ')

        if options[:input_html] && options[:input_html][:id]
          options[:label_html] ||= {}
          options[:label_html][:for] ||= options[:input_html][:id]
        end

        # moved hint/error output inside basic_input_helper
        safe_html_output = ::Formtastic::Util.html_safe(inline_input_for(method, options))
        return safe_html_output if input_inline?
        template.content_tag(:div, safe_html_output, wrapper_html) #changed to move to basic_input_helper
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

        safe_control_content = ::Formtastic::Util.html_safe(control_content)
        input_inline? ? safe_control_content : label(method, label_options) << template.content_tag(:div, safe_control_content, {:class => 'controls'}) #added class
        # end changes
      end

      # wrap select in a control
      def select_input(method, options)
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
        label_options[:class] ||= 'control-label'
        label_options[:for] ||= html_options[:id]

        select_html = parts(method, options) do
          select_html
        end

        safe_select_html = ::Formtastic::Util.html_safe(select_html)

        return safe_select_html if input_inline?
        label(method, label_options) << template.content_tag(:div, safe_select_html, {:class => 'controls'})
      end

      def boolean_input(method, options)
        html_options  = options.delete(:input_html) || {}
        checked_value = options.delete(:checked_value) || '1'
        unchecked_value = options.delete(:unchecked_value) || '0'
        checked = @object && ActionView::Helpers::InstanceTag.check_box_checked?(@object.send(:"#{method}"), checked_value)

        html_options[:id] = html_options[:id] || generate_html_id(method, "")
        input_html = template.check_box_tag(
          "#{@object_name}[#{method}]",
          checked_value,
          checked,
          html_options
        )

        label_options = options_for_label(options)
        label_options[:for] ||= html_options[:id]
        (label_options[:class] ||= []) << 'checkbox'

        input_html << localized_string(method, label_options[:label], :label) || humanized_attribute_name(method)
        label_options.delete :label

        safe_input_html = ::Formtastic::Util.html_safe(input_html)

        return safe_input_html if input_inline?

        template.content_tag(:div, label(method, safe_input_html, label_options), {:class => 'controls'}) << template.hidden_field_tag((html_options[:name] || "#{@object_name}[#{method}]"), unchecked_value, :id => nil, :disabled => html_options[:disabled])
      end

      def check_boxes_input(method, options)
        collection = find_collection_for_column(method, options)
        html_options = options.delete(:input_html) || {}

        input_name      = generate_association_input_name(method)
        hidden_fields   = options.delete(:hidden_fields)
        value_as_class  = options.delete(:value_as_class)
        unchecked_value = options.delete(:unchecked_value) || ''
        html_options    = { :name => "#{@object_name}[#{input_name}][]" }.merge(html_options)
        input_ids       = []

        selected_values = find_selected_values_for_column(method, options)
        disabled_option_is_present = options.key?(:disabled)
        disabled_values = [*options[:disabled]] if disabled_option_is_present

        li_options = value_as_class ? { :class => [method.to_s.singularize, 'default'].join('_') } : {}

        list_item_content = collection.map do |c|
          label = c.is_a?(Array) ? c.first : c
          value = c.is_a?(Array) ? c.last : c
          input_id = generate_html_id(input_name, value.to_s.gsub(/\s/, '_').gsub(/\W/, '').downcase)
          input_ids << input_id

          html_options[:checked] = selected_values.include?(value)
          html_options[:disabled] = (disabled_values.include?(value) || options[:disabled] == true) if disabled_option_is_present
          html_options[:id] = input_id

          li_content = template.content_tag(:label,
            ::Formtastic::Util.html_safe("#{create_check_boxes(input_name, html_options, value, unchecked_value, hidden_fields)} #{escape_html_entities(label)}"),
            :for => input_id, :class => 'checkbox',
          )

          li_options = value_as_class ? { :class => [method.to_s.singularize, value.to_s.downcase].join('_') } : {}
          template.content_tag(:li, ::Formtastic::Util.html_safe(li_content), li_options)
        end

        list_html = parts(method, options) do
          template.content_tag(:ul, ::Formtastic::Util.html_safe(list_item_content.join), :class => 'unstyled')
        end

        content = label(method, :class => 'control-label', :for => html_options[:id])
        content << create_hidden_field_for_check_boxes(input_name, value_as_class) unless hidden_fields
        content << template.content_tag(:div, ::Formtastic::Util.html_safe(list_html), {:class => 'controls'})
      end

      # remove the button wrapper
      def commit_button(*args)
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
