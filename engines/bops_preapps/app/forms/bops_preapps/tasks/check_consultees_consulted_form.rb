# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckConsulteesConsultedForm < BaseForm
      def update(params)
        if params[:button] == "save_draft"
          task.start!
        else
          begin
            ActiveRecord::Base.transaction do
              planning_application.consultation.create_consultees_review!
              task.complete!
            end
          rescue ActiveRecord::ActiveRecordError
            false
          end
        end
      end

      def permitted_fields(params)
        params # no params sent: just a submit button
      end

      def add_consultees_task
        task.case_record.find_task_by_slug_path!("consultees/add-and-assign-consultees")
      end

      def determine_consultation_requirement_task
        task.case_record.find_task_by_slug_path!("consultees/determine-consultation-requirement")
      end
    end
  end
end
