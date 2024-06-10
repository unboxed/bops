# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class DocumentsController < PublicController
        def show
          @planning_application = find_planning_application params[:planning_application_id]

          respond_to do |format|
            format.json
          end
        end

        private

        def planning_applications_scope
          @local_authority.planning_applications.published
        end
      end
    end
  end
end
