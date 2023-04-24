# frozen_string_literal: true

module EvidenceGroups
  class DocumentsComponent < AccordionSections::BaseComponent
    def initialize(documents:)
      @documents = documents
    end

    attr_reader :documents

    private 

    def url_for_document(document)
      if document.published?
        api_v1_planning_application_document_url(document.planning_application, document)
      else
        rails_blob_url(document.file)
      end
    end
  end
end
