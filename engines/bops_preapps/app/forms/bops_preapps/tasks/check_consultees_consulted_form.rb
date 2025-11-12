# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckConsulteesConsultedForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          planning_application.consultation.create_consultees_review!
          task.update!(status: :completed)
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        {} # no params sent: just a submit button
      end
    end
  end
end
