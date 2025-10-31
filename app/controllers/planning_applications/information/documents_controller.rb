# frozen_string_literal: true

module PlanningApplications
  module Information
    class DocumentsController < BaseController
      def show
        @documents = @planning_application.documents
      end
    end
  end
end
