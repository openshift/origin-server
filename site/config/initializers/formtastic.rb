# encoding: utf-8

# --------------------------------------------------------------------------------------------------
# Please note: If you're subclassing Formtastic::SemanticFormBuilder in a Rails 3 project,
# Formtastic uses class_attribute for these configuration attributes instead of the deprecated
# class_inheritable_attribute. The behaviour is slightly different with subclasses (especially
# around attributes with Hash or Array) values, so make sure you understand what's happening.
# See the documentation for class_attribute in ActiveSupport for more information.
# --------------------------------------------------------------------------------------------------

# Set the default text field size when input is a string. Default is nil.
# Formtastic::SemanticFormBuilder.default_text_field_size = 50

# Set the default text area height when input is a text. Default is 20.
# Formtastic::SemanticFormBuilder.default_text_area_height = 5

# Set the default text area width when input is a text. Default is nil.
# Formtastic::SemanticFormBuilder.default_text_area_width = 50

# Should all fields be considered "required" by default?
# Rails 2 only, ignored by Rails 3 because it will never fall back to this default.
# Defaults to true.
# Formtastic::SemanticFormBuilder.all_fields_required_by_default = true

# Should select fields have a blank option/prompt by default?
# Defaults to true.
# Formtastic::SemanticFormBuilder.include_blank_for_select_by_default = true

# Set the string that will be appended to the labels/fieldsets which are required
# It accepts string or procs and the default is a localized version of
# '<abbr title="required">*</abbr>'. In other words, if you configure formtastic.required
# in your locale, it will replace the abbr title properly. But if you don't want to use
# abbr tag, you can simply give a string as below
# Formtastic::SemanticFormBuilder.required_string = "(required)"

# Set the string that will be appended to the labels/fieldsets which are optional
# Defaults to an empty string ("") and also accepts procs (see required_string above)
# Formtastic::SemanticFormBuilder.optional_string = "(optional)"

# Set the way inline errors will be displayed.
# Defaults to :sentence, valid options are :sentence, :list, :first and :none
# Formtastic::SemanticFormBuilder.inline_errors = :sentence
# Formtastic uses the following classes as default for hints, inline_errors and error list

# If you override the class here, please ensure to override it in your formtastic_changes.css stylesheet as well
Formtastic::SemanticFormBuilder.default_hint_class = "help-block"
Formtastic::SemanticFormBuilder.default_inline_error_class = "help-inline"
# Formtastic::SemanticFormBuilder.default_error_list_class = "errors"

# Set the method to call on label text to transform or format it for human-friendly
# reading when formtastic is used without object. Defaults to :humanize.
# Formtastic::SemanticFormBuilder.label_str_method = :humanize

# Set the array of methods to try calling on parent objects in :select and :radio inputs
# for the text inside each @<option>@ tag or alongside each radio @<input>@. The first method
# that is found on the object will be used.
# Defaults to ["to_label", "display_name", "full_name", "name", "title", "username", "login", "value", "to_s"]
# Formtastic::SemanticFormBuilder.collection_label_methods = [
#   "to_label", "display_name", "full_name", "name", "title", "username", "login", "value", "to_s"]

# Formtastic by default renders inside li tags the input, hints and then
# errors messages. Sometimes you want the hints to be rendered first than
# the input, in the following order: hints, input and errors. You can
# customize it doing just as below:
# Formtastic::SemanticFormBuilder.inline_order = [:input, :hints, :errors]

# Additionally, you can customize the order for specific types of inputs.
# This is configured on a type basis and if a type is not found it will
# fall back to the default order as defined by #inline_order
# Formtastic::SemanticFormBuilder.custom_inline_order[:checkbox] = [:errors, :hints, :input]
# Formtastic::SemanticFormBuilder.custom_inline_order[:select] = [:hints, :input, :errors]

# Specifies if labels/hints for input fields automatically be looked up using I18n.
# Default value: false. Overridden for specific fields by setting value to true,
# i.e. :label => true, or :hint => true (or opposite depending on initialized value)
Formtastic::SemanticFormBuilder.i18n_lookups_by_default = true

# You can add custom inputs or override parts of Formtastic by subclassing SemanticFormBuilder and
# specifying that class here.  Defaults to SemanticFormBuilder.
# Formtastic::SemanticFormHelper.builder = MyCustomBuilder

class BootstrapFormBuilder < Formtastic::SemanticFormBuilder

  # remove once all forms converted
  def new_forms_enabled?
    template.instance_variable_get('@new_forms_enabled')
  end

  # set the default css class
  def buttons(*args)
    return super unless new_forms_enabled?

    options = args.extract_options!
    options[:class] ||= 'form-actions'
    super *(args << options)
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

  # change from li to div.control-group, move hints/errors into the input block
  def input(method, options = {})
    return super unless new_forms_enabled?

    options = options.dup # Allow options to be shared without being tainted by Formtastic

    options[:required] = method_required?(method) unless options.key?(:required)
    options[:as]     ||= default_input_type(method, options)

    html_class = [ options[:as], (options[:required] ? :required : :optional), 'control-group' ] #changed
    html_class << 'error' if has_errors?(method, options)

    wrapper_html = options.delete(:wrapper_html) || {}
    wrapper_html[:id]  ||= generate_html_id(method)
    wrapper_html[:class] = (html_class << wrapper_html[:class]).flatten.compact.join(' ')

    if options[:input_html] && options[:input_html][:id]
      options[:label_html] ||= {}
      options[:label_html][:for] ||= options[:input_html][:id]
    end

    # moved hint/error output inside basic_input_helper

    template.content_tag(:div, Formtastic::Util.html_safe(inline_input_for(method, options)), wrapper_html) #changed to move to basic_input_helper
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

    # begin changes - moved from input()
    input_parts = (custom_inline_order[options[:as]] || inline_order).dup
    input_parts = input_parts - [:errors, :hints] if options[:as] == :hidden

    control_content = input_parts.map do |type|
      if :input == type
        send(respond_to?(form_helper_method) ? form_helper_method : :text_field, method, html_options)
      else
        send(:"inline_#{type}_for", method, options)
      end
    end.compact.join("\n")
    
    label(method, label_options) <<
      template.content_tag(:div, Formtastic::Util.html_safe(control_content), {:class => 'controls'}) #added class
    # end changes
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
    button_html.merge!(:class => [button_html[:class], key, 'btn btn-primary'].compact.join(' '))

    #remove need for wrapper
    #wrapper_html_class = ['btn-primary'] #changed # TODO: Add class reflecting on form action.
    #wrapper_html = options.delete(:wrapper_html) || {}
    #wrapper_html[:class] = (wrapper_html_class << wrapper_html[:class]).flatten.compact.join(' ')

    accesskey = (options.delete(:accesskey) || default_commit_button_accesskey) unless button_html.has_key?(:accesskey)
    button_html = button_html.merge(:accesskey => accesskey) if accesskey
    submit(text, button_html) # no wrapper
  end
end
Formtastic::SemanticFormHelper.builder = BootstrapFormBuilder
