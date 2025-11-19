# frozen_string_literal: true

module PlanningApplications
  class ValidationsController < AuthenticationController
    before_action :set_planning_application

    def show
      @planning_application.update(validated_at: @planning_application.valid_from_date)

      if @planning_application.pre_application?
        @planning_application.start!
        @planning_application.send_validation_notice_mail

        redirect_to @planning_application, notice: t("planning_applications.validations.create.success")
      else
        respond_to do |format|
          format.html { render :show }
        end
      end
    end

    def create
      if @planning_application.validation_requests.pending.any?
        @planning_application.errors.add(:planning_application,
          "Planning application cannot be validated if pending validation requests exist.")
      elsif @planning_application.invalid_documents.present?
        @planning_application.errors.add(
          :planning_application,
          "This application has an invalid document. You cannot validate an application with invalid documents."
        )
      elsif @planning_application.boundary_geojson.blank?
        @planning_application.errors.add(
          :base,
          :no_boundary_geojson,
          path: planning_application_validation_sitemap_path(@planning_application)
        )
      end

      if @planning_application.errors.any?
        render :show
      else
        @planning_application.update!(planning_application_params)
        @planning_application.start!
        @planning_application.send_validation_notice_mail

        redirect_to @planning_application, notice: t(".success")
      end
    end

    def destroy
      if @planning_application.may_invalidate?
        @planning_application.invalidate!

        @planning_application.send_invalidation_notice_mail

        redirect_to @planning_application, notice: t(".success")
      else
        validation_requests = @planning_application.validation_requests
        @cancelled_validation_requests = validation_requests.where(state: "cancelled")
        @active_validation_requests = validation_requests.where.not(state: "cancelled")

        flash.now[:alert] = t(".failure")
        render "planning_applications/validation/validation_requests/index"
      end
    end

    private

    def planning_application_params
      params.require(:planning_application).permit(:valid_from_date)
    end
  end
end
