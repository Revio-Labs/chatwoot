class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  before_action :check_feature_enabled
  before_action :check_authorization
  before_action :fetch_ticket, only: [:show, :update, :destroy]

  def index
    @tickets = Current.account.tickets.includes(:ticket_type, :contact, :assignee)
    @tickets = @tickets.where(ticket_type_id: params[:ticket_type_id]) if params[:ticket_type_id].present?
    @tickets = @tickets.where(state: params[:state]) if params[:state].present?
    @tickets = @tickets.order(created_at: :desc)
  end

  def show; end

  def create
    @ticket = Current.account.tickets.new(ticket_params)
    @ticket.save!
  end

  def update
    @ticket.update!(ticket_params)
  end

  def destroy
    @ticket.destroy!
    head :ok
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:id])
  end

  def ticket_params
    params.permit(:ticket_type_id, :conversation_id, :contact_id, :assignee_id, :team_id,
                  :title, :description, :state, custom_attributes: {})
  end

  def check_feature_enabled
    return if Current.account.tickets_enabled?

    render json: { error: I18n.t('errors.tickets.feature_not_enabled') }, status: :forbidden
  end

  def check_authorization
    authorize(Ticket)
  end
end
