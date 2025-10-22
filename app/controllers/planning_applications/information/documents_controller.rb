# frozen_string_literal: true

module PlanningApplications
  module Information
    class DocumentsController < BaseController
      def show
        @documents = @planning_application.documents.active
      end

      private

      def current_section
        :documents
      end
    end
  end
end
