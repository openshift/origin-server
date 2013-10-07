##
# @api model

#
# @!attribute [r] created_at
#   @return [Float] Time in seconds of when the deployment was created
# @!attribute [r] hot_deploy
#   @return [Boolean]
# @!attribute [r] force_clean_build
#   @return [Boolean]
# @!attribute [r] ref
#   @return [String] The git ref to be used for this deployment
# @!attribute [r] artifact_url
#   @return [String] The URL where the deployment artifact can be downloaded from
# @!sha1 [r] sha1
#   @return [String] The sha of what was actually deployed
# @!activations [r] activations
#   @return [Array] Array of activation times in seconds

class Deployment
  include Mongoid::Document
  embedded_in :application, class_name: Application.name

  self.field :deployment_id, type: String
  self.field :created_at, type: Time
  self.field :hot_deploy, type: Boolean, default: false
  self.field :force_clean_build, type: Boolean, default: false
  self.field :ref, type: String
  self.field :sha1, type: String
  self.field :artifact_url, type: String
  self.field :activations, type: Array, default: []

  validates :ref, presence: true, :allow_blank => false, length: {maximum: 256}
  validates :sha1, presence: true, :allow_blank => false, length: {maximum: 256}
  validates_presence_of :deployment_id
  validates_presence_of :created_at
  validates_presence_of :activations
  validate  :validate_activations
  validate  :validate_deployment

  def validate_deployment
    if (self.ref and not self.ref.empty?) and (self.artifact_url and not self.artifact_url.empty?)
      self.errors[:base] << "You can either use an artifact URL or ref.  You cannot use both."
    end
  end

  def validate_activations
    self.activations.each do |activation|
      unless activation.is_a? Numeric
        self.errors[:activations] << "Activations must a numeric representing time in seconds."
        break
      end
    end
  end

  #TODO add error codes for deployment to li/misc/docs/ERROR_CODES.txt
  def self.validation_map
    return {}
  end
  ##
  # Returns the deployment object as a hash
  # @return [Hash]
  def to_hash
    {
      "deployment_id" => deployment_id, "created_at" => created_at, "hot_deploy" => hot_deploy,
      "force_clean_build" => force_clean_build, "ref" => ref, "sha1" => sha1, "artifact_url" => artifact_url, "activations" => activations
    }
  end
end
