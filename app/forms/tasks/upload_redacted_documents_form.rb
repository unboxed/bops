# frozen_string_literal: true

module Tasks
  class UploadRedactedDocumentsForm < Form
    self.task_actions = %w[save_draft save_and_complete edit_form]

    after_initialize do
      active_documents = planning_application.documents.active
      @documents = active_documents.not_redacted
      @redacted_documents = active_documents.redacted
    end

    attr_reader :documents, :redacted_documents

    private

    def save_and_complete
      create_redacted_documents!
      super
    end

    def save_draft
      create_redacted_documents!
      super
    end

    def documents_params
      params.fetch(:documents, {})
    end

    def create_redacted_documents!
      documents_params.each do |document_id, attrs|
        next unless attrs[:file]

        original = documents.find(document_id)
        planning_application.documents.create!(
          file: attrs[:file],
          tags: original.tags,
          redacted: true,
          publishable: true,
          validated: true
        )
      end
    end
  end
end
