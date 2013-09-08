##
# @api model

# 
# @!attribute [r] state
#   @return [String] The state of deployment. i.e. active..
# @!attribute [r] created_at
#   @return [Date] Timestamp of when the deployment was created
# @!attribute [r] Description
#   @return [String] Description of deployment
# @!attribute [r] hot_deploy
#   @return [Boolean] 
# @!attribute [r] force_clean_build
#   @return [Boolean] 
# @!attribute [r] git_branch
#   @return [String] The git branch to be used for this deployment
# @!attribute [r] git_commit_id
#   @return [String] The git commit id to be used for this deployment
# @!attribute [r] git_tag
#   @return [String] The git tag to be used for this deployment
# @!attribute [r] artifact_url
#   @return [String] The URL where the deployment artifact can be downloaded from.

class Deployment
  include Mongoid::Document
  embedded_in :application

  self.field :id, type: String
  self.field :created_at,type: Date
  self.field :state, type: String, default: "active"
  self.field :description, type: String
  self.field :hot_deploy, type: Boolean, default: false
  self.field :force_clean_build, type: Boolean, default: false
  self.field :git_branch, type: String
  self.field :git_commit_id, type: String
  self.field :git_tag, type: String
  self.field :artifact_url, type: String

  #TODO define possible values?
  DEPLOYMENT_STATES =[:active, :past, :prepared]

  validates :state, :inclusion => { :in => DEPLOYMENT_STATES.map { |s| s.to_s }, :message => "%{value} is not a valid state. Valid states are #{DEPLOYMENT_STATES.join(", ")}." }
  validates :description, presence: {message: "Description is required and cannot be blank."}, length: {maximum: 250}, :allow_blank => false
  validates :git_commit_id, :allow_blank => true, length: {is: 40}
  validate  :validate_deployment

  def validate_deployment
    if self.git_branch.nil? and self.git_commit_id.nil? and self.git_tag.nil? and self.artifact_url.nil?
      self.errors[:base] << "At least one of the following information has to be provided to create a new deployment: git_branch, git_commit_id, git_tag or artifact_url"
    end
    if (self.git_branch or self.git_commit_id or self.git_tag) and self.artifact_url
      self.errors[:base] << "You can either use an aritifact URL or git.  You can not use both."
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
      "id" => id, "created_at" => created_at, "state" => state, "description" => description, "hot_deploy" => hot_deploy,
      "force_clean_build" => force_clean_build, "git_branch" => git_branch, "git_commit_id" => git_commit_id, 
      "git_tag" => git_tag, "artifact_url" => artifact_url
      }
  end
end
