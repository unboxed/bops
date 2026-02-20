# frozen_string_literal: true

module Tasks
  class UploadRedactedDocumentsForm < Form
    self.task_actions = %w[save_draft save_and_complete edit_form]

    def documents
      @documents ||= planning_application.documents.active.not_redacted
    end

    def redacted_documents
      @redacted_documents ||= planning_application.documents.active.redacted
    end

    def update(params)
      super do
        transaction do
          create_redacted_documents!(params)

          case action
          when "save_draft"
            save_draft
          when "save_and_complete"
            save_and_complete
          when "edit_form"
            task.in_progress!
          end
        end
      end
    end

    private

    def create_redacted_documents!(params)
      params.fetch(:documents, {}).each do |document_id, attrs|
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
