class RegistrationsController < ApplicationController
  before_action :set_registration, only: [:show, :edit, :update, :destroy]

  # GET /registrations
  def index
    @registrations = Registration.all
  end

  # GET /registrations/1
  def show
  end

  # GET /registrations/new
  def new
    @registration = Registration.new
    @registration.build_card
    @course = Course.find_by id: params["course_id"]
  end

  # POST /registrations
  def create
    @registration = Registration.new(registration_params)
    @registration.card.ip_address = request.remote_ip
    if @registration.save
      case params['payment_method']
        when "paypal"
          @count = Random.rand(1000...10000)
          redirect_to @registration.paypal_url(registration_path(@registration),@count)
        when "card"
          if @registration.card.purchase
            redirect_to registration_path(@registration), notice: @registration.card.card_transaction.message
          else
            redirect_to registration_path(@registration), alert: @registration.card.card_transaction.message
          end
      end
    else
      render :new
    end
  end

  protect_from_forgery except: [:hook]
  def hook
    params.permit! # Permit all Paypal input params
    status = params[:payment_status]
    transaction_id = params[:txn_id]
    if status == "Completed"
      # @registration = Registration.find params[:invoice]
      @registration = Registration.find(2)
      @registration.update_attributes(notification_params: "This is Transtion", status: status, transaction_id: transaction_id, purchased_at: Time.now)
      # @registration.card.card_transaction.update_attributes transaction_id: params[:txn_id]
    end
    render nothing: true
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_registration
      @registration = Registration.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def registration_params
      params.require(:registration).permit(:course_id, :full_name, :company, :email, :telephone,
                                           card_attributes: [
                                               :first_name, :last_name, :card_type, :card_number,
                                               :card_verification, :card_expires_on])
    end
end
