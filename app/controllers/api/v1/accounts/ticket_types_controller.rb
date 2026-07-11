class Api::V1::Accounts::TicketTypesController < Api::V1::Accounts::BaseController
  before_action :check_feature_enabled
  before_action :check_authorization
  before_action :fetch_ticket_type, only: [:show, :update, :destroy]

  def index
    @ticket_types = Current.account.ticket_types.order(:name)
  end

  def show; end

  def create
    @ticket_type = Current.account.ticket_types.new(ticket_type_params)
    @ticket_type.field_schema = params[:field_schema] if params[:field_schema].present?
    @ticket_type.save!
  end

  def update
    @ticket_type.assign_attributes(ticket_type_params)
    @ticket_type.field_schema = params[:field_schema] if params[:field_schema].present?
    @ticket_type.save!
  end

  def destroy
    @ticket_type.destroy!
    head :ok
  end

  private

  def fetch_ticket_type
    @ticket_type = Current.account.ticket_types.find(params[:id])
  end

  def ticket_type_params
    params.permit(:name, :category, :icon, :status)
  end

  def check_feature_enabled
    return if Current.account.tickets_enabled?

    render json: { error: I18n.t('errors.tickets.feature_not_enabled') }, status: :forbidden
  end

  def check_authorization
    authorize(TicketType)
  end
end
