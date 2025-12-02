# frozen_string_literal: true

module BopsCore
  module DocumentHelper
    def document_link_path(document, **kwargs)
      if document.status == :invalid
        main_app.planning_application_validation_replacement_document_validation_request_path(
          document.planning_application,
          document.replacement_document_validation_request,
          **kwargs
        )
      else
        main_app.edit_planning_application_document_path(
          document.planning_application,
          document,
          validate: :yes,
          **kwargs
        )
      end
    end
  end
end
