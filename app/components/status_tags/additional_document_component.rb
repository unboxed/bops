# frozen_string_literal: true

module StatusTags
  class AdditionalDocumentComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.additional_document_validation_requests.open_or_pending.any?
        :invalid
      elsif planning_application.documents_missing == false
        :complete
      else
        :not_started
      end
    end
  end
end
