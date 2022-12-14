# frozen_string_literal: true

module AccordionSections
  class DocumentsComponent < AccordionSections::BaseComponent
    private

    def documents
      planning_application.documents.active.order(:created_at)
    end
  end
end
