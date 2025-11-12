# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ChooseApplicationTypeForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          planning_application.update!(params, :recommended_application_type)
          task.update!(status: :completed)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        params.require(:task).permit(:recommended_application_type_id)
      end
    end
  end
end
