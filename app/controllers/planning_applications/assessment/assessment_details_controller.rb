# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class AssessmentDetailsController < BaseController
      include ReturnToReport

      before_action :set_assessment_detail, only: %i[show edit update]
      before_action :set_category, :set_rejected_assessment_detail, only: %i[new create edit update show]
      before_action :set_consultation, if: :has_consultation_and_summary?
      before_action :set_neighbour_responses, if: :neighbour_summary?
      before_action :set_site_and_press_notices, if: :check_publicity?
      before_action :store_return_to_report_path, only: %i[new create edit]

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        @assessment_detail = @planning_application.assessment_details.new

        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def create
        @assessment_detail = @planning_application.assessment_details.new(set_params)

        respond_to do |format|
          if @assessment_detail.save
            format.html do
              redirect_to redirect_path, notice: created_notice
            end
          else
            @category = @assessment_detail.category
            format.html { render :new }
          end
        end
      end

      def update
        respond_to do |format|
          if @assessment_detail.update(set_params)
            format.html do
              redirect_to redirect_path,
                notice: I18n.t("planning_applications.assessment.assessment_details.#{@assessment_detail.category}.updated.success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def set_category
        @category = params[:category] || assessment_details_params[:category]
      end

      def set_neighbour_responses
        @neighbour_responses = @planning_application.consultation.neighbour_responses
      end

      def set_site_and_press_notices
        @site_notice = @planning_application.site_notices.last
        @press_notice = @planning_application.press_notice
      end

      def check_publicity?
        @category == "check_publicity"
      end

      def consultation_summary?
        @category == "consultation_summary"
      end

      def neighbour_summary?
        @category == "neighbour_summary"
      end

      def set_rejected_assessment_detail
        return unless @planning_application.recommendation&.rejected?

        @rejected_assessment_detail = @planning_application.rejected_assessment_detail(category: @category)
      end

      def set_assessment_detail
        @assessment_detail = @planning_application.assessment_details.find(assessment_detail_id)
      end

      def assessment_detail_id
        Integer(params[:id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid assessment detail id: #{params[:id].inspect}"
      end

      def assessment_details_params
        params
          .require(:assessment_detail)
          .permit(:entry, :category, NeighbourResponse::TAGS, :untagged, :summary_tag)
          .merge(assessment_status:)
      end

      def neighbour_response_params
        new_params = assessment_details_params

        tag_array = NeighbourResponse::TAGS.dup

        new_params[:entry] = tag_array.push(:untagged).map do |tag|
          next unless assessment_details_params[tag]

          "#{tag.to_s.humanize}: #{assessment_details_params[tag]}\n"
        end.join

        NeighbourResponse::TAGS.each do |tag|
          new_params.delete tag
        end

        new_params.except(:untagged)
      end

      def set_params
        neighbour_summary? ? neighbour_response_params : assessment_details_params
      end

      def assessment_status
        save_progress? ? :in_progress : :complete
      end

      def created_notice
        action = @rejected_assessment_detail.present? ? :updated : :created
        I18n.t("planning_applications.assessment.assessment_details.#{@category}.#{action}.success")
      end

      def has_consultation_and_summary?
        consultation_summary? && @planning_application.application_type.consultation?
      end

      def redirect_path
        if current_user.reviewer? && @category == "site_description" && !@planning_application.pre_application?
          report_path_or @back_path
        else
          report_path_or planning_application_assessment_tasks_path(@planning_application)
        end
      end
    end
  end
end
