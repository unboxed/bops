# frozen_string_literal: true

module BopsApi
    module V2
        module Public
            class CommentsController < PublicController
                def show
                    # Log incoming parameters for debugging
                    logger.debug "Incoming params: #{params.inspect}"

                    # Validate that the reference parameter exists
                    if params[:planning_application_id].blank?
                        render json: { error: 'Reference parameter is required' }, status: :unprocessable_entity and return
                    end

                    # Find the planning application using the reference
                    @planning_application = find_planning_application(params[:planning_application_id])
                    @consultation = consultation_scope.find_by(planning_application_id: @planning_application.id)
                    @comments = comments_scope.find_by(consultation_id: @consultation.id)


                    if @planning_application.nil?
                        render json: { error: 'Planning application not found' }, status: :not_found and return
                    end

                    respond_to do |format|
                        format.json { render json: @comments }
                    end
                end

                private

                def find_planning_application(reference)
                PlanningApplication.find_by(reference: reference)
                end
            end
        end
    end
end