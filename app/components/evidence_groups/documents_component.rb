# frozen_string_literal: true

module EvidenceGroups
  class DocumentsComponent < AccordionSections::BaseComponent
    def initialize(documents:)
      @documents = documents
    end

    attr_reader :documents
  end
end
