# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SummaryOfAdviceForm < BaseForm
      def update(params)
        assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :summary_of_advice)
        ActiveRecord::Base.transaction do
          assessment_detail.update!(params)

          if @button == "save_draft"
            task.start!
          else
            task.complete!
          end
        end
      rescue ActiveRecord::ActiveRecordErrror
        false
      end

      def permitted_fields(params)
        @button = params[:button]
        begin
          params.require(:task).permit(:summary_tag, :entry)
        rescue ActionController::ParameterMissing
          {}
        end
      end
    end
  end
end
