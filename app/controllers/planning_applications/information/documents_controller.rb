# frozen_string_literal: true

module PlanningApplications
  module Information
    class DocumentsController < BaseController
      def show
        @documents = @planning_application.documents.active
      end
    end
  end
end
