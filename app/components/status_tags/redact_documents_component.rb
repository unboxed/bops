# frozen_string_literal: true

module StatusTags
  class RedactDocumentsComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      planning_application.documents_status.to_sym
    end
  end
end
