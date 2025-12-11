# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class AddReportingDetailsForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          return false unless planning_application.update(reporting_details_params(params), :reporting_types)

          if save_draft?
            task.start! || raise(ActiveRecord::RecordInvalid.new(task))
          else
            task.complete! || raise(ActiveRecord::RecordInvalid.new(task))
          end
        end

        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        @button = params[:button]
        params.require(:planning_application).permit(:reporting_type_id, :regulation, :regulation_3)
      end

      private

      def reporting_details_params(params)
        regulation = ActiveModel::Type::Boolean.new.cast(params[:regulation])
        regulation_3_selected = ActiveModel::Type::Boolean.new.cast(params[:regulation_3])

        {
          reporting_type_id: params[:reporting_type_id],
          regulation:,
          regulation_3: regulation && regulation_3_selected,
          regulation_4: regulation && !regulation_3_selected
        }
      end
    end
  end
end
