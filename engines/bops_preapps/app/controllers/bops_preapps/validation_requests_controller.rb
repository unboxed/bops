# frozen_string_literal: true

module BopsPreapps
  class ValidationRequestsController < AuthenticationController
    before_action :set_layout
    before_action :set_planning_application
    before_action :set_case_record
    before_action :set_validation_request, except: %i[new create]
    before_action :build_validation_request, only: %i[new create]

    before_action :ensure_request_is_createable, only: %i[new create]
    before_action :ensure_request_is_editable, only: %i[edit update]
    before_action :ensure_request_is_destroyable, only: %i[destroy]

    helper_method :task_redirect_path

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @validation_request.save
          format.html do
            redirect_to task_redirect_path, notice: task_redirect_notice
          end
        else
          format.html { render :new }
        end
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @validation_request.update(validation_request_params)
          format.html do
            redirect_to task_redirect_path, notice: task_redirect_notice
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @validation_request.destroy
          format.html do
            redirect_to task_redirect_path, notice: task_redirect_notice
          end
        else
          format.html do
            redirect_to task_redirect_path, alert: task_redirect_alert
          end
        end
      end
    end

    private

    def set_layout
      @show_header_bar = true
      @show_sidebar = true
    end

    def set_planning_application
      scope = current_local_authority.planning_applications
      planning_application = scope.find_by!(reference: params[:reference])

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_case_record
      @case_record = @planning_application.case_record
    end

    def set_validation_request
      @validation_request = @planning_application.validation_requests.find(params[:id])
    end

    def request_type
      ValidationRequest::REQUEST_TYPE_MAP.fetch(params.fetch(:type))
    rescue KeyError
      raise BopsCore::Errors::BadRequestError, "Invalid validation request type"
    end

    def build_validation_request
      @validation_request = @planning_application.validation_requests.new(type: request_type)

      if action_name == "create"
        @validation_request.assign_attributes(validation_request_params)
      end
    end

    def validation_request_attributes
      scope = "bops_preapps.validation_requests.attributes"
      t(@validation_request.type_symbol, scope: scope.to_sym)
    end

    def validation_request_params
      params.require(:validation_request).permit(*validation_request_attributes).merge(user: current_user)
    end

    def task_redirect_lookup(scope)
      scope = "bops_preapps.validation_requests.#{scope}"
      t(@validation_request.type_symbol, scope: scope.to_sym)
    end

    def task_redirect_notice
      task_redirect_lookup("redirect_notices.#{action_name}")
    end

    def task_redirect_alert
      task_redirect_lookup("redirect_alerts.#{action_name}")
    end

    def task_redirect_slug
      task_redirect_lookup("redirect_slugs")
    end

    def task_redirect_path
      task_path(@planning_application, task_redirect_slug)
    end

    def ensure_request_is_createable
      if @planning_application.validated?
        redirect_to task_redirect_path, alert: t(".validation_request_not_createable")
      end
    end

    def ensure_request_is_editable
      unless @planning_application.not_started?
        redirect_to task_redirect_path, alert: t(".validation_request_not_editable")
      end
    end

    def ensure_request_is_destroyable
      unless @planning_application.not_started?
        redirect_to task_redirect_path, alert: t(".validation_request_not_destroyable")
      end
    end
  end
end
