# frozen_string_literal: true

module BopsApi
    module V2
        module Public
            class CommentsController < PublicController
                def show
                    @planning_application = find_planning_application params[:planning_application_id]
                    # @planning_application_id = planning_application.id
                    # @consultation = consultation params[:planning_application_id]   
                    # @consultation = consultee_responses
                    # @planning_application_id = planning_application.id
                    # @consultation = consultation params[:planning_application_id]
                    # @documents = @planning_application.documents_for_publication
                    # @count = @documents.length
                    logger.debug "test #{@planning_application}"
                    # puts @planning_application_id
                    # puts "consultation" @consultation

                    respond_to do |format|
                        format.json
                    end
                end
            end
        end
    end
end