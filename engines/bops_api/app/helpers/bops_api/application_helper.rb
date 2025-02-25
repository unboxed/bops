# frozen_string_literal: true

module BopsApi
  module ApplicationHelper
    include Pagy::Frontend
    include Pagy::Backend

    def document_download_url(planning_application, document)
      if %r{/public/}.match?(request.params[:controller])
        download_v2_public_planning_application_documents_url(planning_application, document)
      else
        download_v2_planning_application_documents_url(planning_application, document)
      end
    end
  end
end
