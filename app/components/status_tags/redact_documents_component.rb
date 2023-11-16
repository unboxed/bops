# frozen_string_literal: true

module StatusTags
  class RedactDocumentsComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.documents.redacted.any?
        :complete
      else
        :not_started
      end
    end
  end
end
