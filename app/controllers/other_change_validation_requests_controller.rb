# frozen_string_literal: true

class OtherChangeValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  before_action :ensure_planning_application_not_validated, only: %i[new create edit update]
  before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]
  before_action :ensure_planning_application_not_invalidated, only: :edit
  before_action :set_other_validation_request, only: %i[show edit update]
  before_action :validate_fee?, only: %i[new create edit update]

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @other_change_validation_request = @planning_application.other_change_validation_requests.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      if @other_change_validation_request.closed?
        format.html { render plain: "Not Found", status: :not_found }
      else
        format.html { render :edit }
      end
    end
  end

  def create
    @other_change_validation_request =
      @planning_application.other_change_validation_requests.new(other_change_validation_request_params)
    @other_change_validation_request.user = current_user

    respond_to do |format|
      if @other_change_validation_request.save
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
            notice: t(".success")
        end
      else
        format.html { render :new, validate_fee: params[:validate_fee] }
      end
    end
  end

  def update
    respond_to do |format|
      if @other_change_validation_request.update(other_change_validation_request_params)
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
            notice: t(".success")
        end
      else
        format.html { render :edit }
      end
    end
  end

  private

  def other_change_validation_request_params
    params.require(:other_change_validation_request).permit(:summary, :suggestion, :fee_item)
  end

  def set_other_validation_request
    @other_change_validation_request = @planning_application.other_change_validation_requests.find(params[:id])
  end

  def validate_fee?
    @validate_fee = params[:validate_fee] == "yes" || @other_change_validation_request.try(:fee_item?)
  end
end
