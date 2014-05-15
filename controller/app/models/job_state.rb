##
# @api model
# Abstract class representing an SSH key. Used by {UserSshKey}, {ApplicationSshKey}, and {SystemSshKey}
# @!attribute [r] name
#   @return [String] Name of the ssh key. Must be unique for the user.
# @!attribute [r] type
#   @return [String] Type of the ssh key. Must be "ssh-rsa" or "ssh-dsa".
# @!attribute [r] content
#   @return [String] SSH key content
class JobState
  include Mongoid::Document
  include AccessControlled

  field :op_id, type: Moped::BSON::ObjectId
  field :op_type, type: String # this is the class name of the pending op
  
  has_many :child_jobs, class_name: JobState.name, inverse_of: :parent_job
  belongs_to :parent_job, class_name: JobState.name, inverse_of: :child_jobs
  field :state, type: String, default: :init
  field :completion_state, type: String
  field :retry_count, type: Integer, default: 0
  field :rollback_retry_count, type: Integer, default: 0
  field :percentage_complete, type: Integer, default: 0
  field :resource_id, type: Moped::BSON::ObjectId
  belongs_to :resource_owner, class_name: CloudUser.name, inverse_of: nil
  belongs_to :owner, class_name: CloudUser.name, inverse_of: nil

  field :object_url, type: String
  
  # result attributes
  field :output_debug, type: Array, default: []
  field :output_result, type: Array, default: []
  field :output_message, type:Array, default: [] 
  field :output_error, type: Array, default: []
  field :output_info, type: Array, default: []
  field :output_data, type: String, default: ""
  field :hasUserActionableError, type: Boolean, default: false
  field :exitcode, type: Integer, default: 0
  field :properties, type: Hash, default: {}
  
  def append_result(resultIO)
    self.output_debug << resultIO.debugIO.string if resultIO.debugIO.string.present?
    self.output_result << resultIO.resultIO.string if resultIO.resultIO.string.present?
    self.output_message << resultIO.messageIO.string if resultIO.messageIO.string.present?
    self.output_error << resultIO.errorIO.string if resultIO.errorIO.string.present?
    self.output_info << resultIO.appInfoIO.string if resultIO.appInfoIO.string.present?

    if resultIO.exitcode != 0
      if resultIO.hasUserActionableError
        unless (!self.hasUserActionableError) && self.exitcode != 0
          self.hasUserActionableError = true
        end
      else
        self.hasUserActionableError = false
      end
    end

    self.output_data += resultIO.data

    resultIO.properties.each do |category, cat_props|
      self.properties[category] = {} if self.properties[category].nil?
      self.properties[category] = self.properties[category].merge(cat_props) unless cat_props.nil?
    end
    self.exitcode = resultIO.exitcode if resultIO.exitcode != 0

    if resultIO.exitcode != 0
      if resultIO.hasUserActionableError
        unless (!self.hasUserActionableError) && self.exitcode != 0
          self.hasUserActionableError = true
        end
      else
        self.hasUserActionableError = false
      end
    end

    self
  end


end
