# frozen_string_literal: true

module PlanningApplications
  module Review
    class DocumentsController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable

      before_action :set_planning_application
      before_action :set_documents
      before_action :ensure_planning_application_is_validated

      def index
        respond_to do |format|
          format.html
        end
      end

      def update
        ActiveRecord::Base.transaction do
          @planning_application.update!(review_documents_for_recommendation_status: status)

          @documents.each do |document|
            document.update!(
              referenced_in_decision_notice: referenced_in_decision_notice?(document.id.to_s),
              publishable: publishable?(document.id.to_s)
            )
          end
        end

        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: t(".success")
      rescue ActiveRecord::ActiveRecordError => e
        redirect_to planning_application_review_documents_path(@planning_application),
                    alert: "Couldn't update documents with error: #{e.message}. Please contact support."
      end

      private

      def planning_applications_scope
        super.includes(:documents)
      end

      def set_documents
        @documents = @planning_application.documents.active
      end

      def referenced_in_decision_notice?(document_id)
        return false unless referenced_in_decision_notice_document_ids

        referenced_in_decision_notice_document_ids.include?(document_id)
      end

      def referenced_in_decision_notice_document_ids
        params["referenced_in_decision_notice_document_ids"]
      end

      def publishable?(document_id)
        return false unless publishable_document_ids

        publishable_document_ids.include?(document_id)
      end

      def publishable_document_ids
        params["publishable_document_ids"]
      end

      def status
        save_progress? ? "in_progress" : "complete"
      end
    end
  end
end
