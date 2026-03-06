# frozen_string_literal: true

module Tasks
  class ReviewDocumentsForRecommendationForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    attribute :publishable_document_ids, :list, default: []
    attribute :referenced_in_decision_notice_document_ids, :list, default: []

    after_initialize do
      @documents = planning_application.documents.active
    end

    attr_reader :documents

    private

    def save_and_complete
      super do
        planning_application.update!(review_documents_for_recommendation_status: "complete")

        update_documents(documents)
      end
    end

    def save_draft
      super do
        planning_application.update!(review_documents_for_recommendation_status: "in_progress")

        update_documents(documents)
      end
    end

    def update_documents(documents)
      documents.each do |document|
        document.update!(
          referenced_in_decision_notice: referenced_in_decision_notice?(document.id.to_s),
          publishable: publishable?(document.id.to_s)
        )
      end
    end

    def form_params(params)
      {
        publishable_document_ids: Array(params[:publishable_document_ids]),
        referenced_in_decision_notice_document_ids: Array(params[:referenced_in_decision_notice_document_ids])
      }
    end

    def publishable?(document_id)
      publishable_document_ids.include?(document_id)
    end

    def referenced_in_decision_notice?(document_id)
      referenced_in_decision_notice_document_ids.include?(document_id)
    end
  end
end
