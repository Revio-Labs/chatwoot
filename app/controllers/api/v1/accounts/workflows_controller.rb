class Api::V1::Accounts::WorkflowsController < Api::V1::Accounts::BaseController
  before_action :check_feature_enabled
  before_action :check_authorization
  before_action :fetch_workflow, only: [:show, :update, :destroy]

  def index
    @workflows = Current.account.workflow_definitions.order(:inbox_id, :priority)
  end

  def show; end

  def create
    @workflow = Current.account.workflow_definitions.new(workflow_permit)
    assign_json_attributes
    @workflow.save!
  end

  def update
    @workflow.assign_attributes(workflow_permit)
    assign_json_attributes
    @workflow.save!
  end

  def destroy
    @workflow.destroy!
    head :ok
  end

  def reorder
    Array(params[:priority_order]).each_with_index do |id, index|
      Current.account.workflow_definitions.where(id: id).update_all(priority: index) # rubocop:disable Rails/SkipsModelValidations
    end
    head :ok
  end

  private

  def fetch_workflow
    @workflow = Current.account.workflow_definitions.find(params[:id])
  end

  # flow and trigger_rules are free-form JSON, assigned outside strong params.
  def assign_json_attributes
    @workflow.flow = params[:flow] if params[:flow].present?
    @workflow.trigger_rules = params[:trigger_rules] if params.key?(:trigger_rules)
  end

  def workflow_permit
    params.permit(:name, :inbox_id, :status, :trigger_type, :audience_type, :priority)
  end

  def check_feature_enabled
    return if Current.account.workflows_enabled?

    render json: { error: I18n.t('errors.workflows.feature_not_enabled') }, status: :forbidden
  end

  def check_authorization
    authorize(WorkflowDefinition)
  end
end
