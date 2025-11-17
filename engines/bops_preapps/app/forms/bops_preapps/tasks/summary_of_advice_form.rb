# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SummaryOfAdviceForm < BaseForm
      def update(params)
        assessment_detail = planning_application.assessment_details.find_or_initialize_by(category: :summary_of_advice)
        ActiveRecord::Base.transaction do
          assessment_detail.update!(params)
          task.update!(status: :completed)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        params.require(:task).permit(:summary_tag, :entry)
      end
    end
  end
end
