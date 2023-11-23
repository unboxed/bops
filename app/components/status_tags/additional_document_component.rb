# frozen_string_literal: true

module StatusTags
  class AdditionalDocumentComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.validation_requests.additional_documents.open_or_pending.any?
        :invalid
      elsif planning_application.documents_missing == false
        :valid
      else
        :not_started
      end
    end
  end
end
