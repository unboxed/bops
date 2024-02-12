# frozen_string_literal: true

module StatusTags
  class DocumentComponent < StatusTags::BaseComponent
    def initialize(planning_application:, document:)
      @planning_application = planning_application
      @document = document
    end

    private

    attr_reader :planning_application, :document

    delegate(
      :replacement_document_validation_request,
      to: :document
    )

    def status
      if document.validated?
        :valid
      elsif replacement_document_validation_request&.open_or_pending?
        :invalid
      elsif ReplacementDocumentValidationRequest.find_by(new_document: document).present?
        :updated
      else
        :not_started
      end
    end
  end
end
