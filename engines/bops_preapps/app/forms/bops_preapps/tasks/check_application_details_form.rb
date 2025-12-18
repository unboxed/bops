# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckApplicationDetailsForm < BaseForm
      def initialize(task, params = {})
        super

        @consistency_checklist = @planning_application.consistency_checklist ||
          @planning_application.create_consistency_checklist
      end
      attr_reader :consistency_checklist

      def update(params)
        ActiveRecord::Base.transaction do
          consistency_checklist.update!(params)

          if @button == "save_draft"
            task.start!
          else
            task.complete!
          end
        end
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def permitted_fields(params)
        @button = params[:button]

        params.require(:consistency_checklist).permit(%i[description_matches_documents
          documents_consistent
          proposal_details_match_documents
          proposal_details_match_documents_comment
          site_map_correct
          site_map_correct_comment])
      end
    end
  end
end
