# frozen_string_literal: true

module BopsApi
    module V2
        module Public
            class SpecialistCommentsController < PublicController
                def show
                    @pagy, @responses = query_service.call

                    respond_to do |format|
                    format.json
                    end
                end

                private

                def response_scope
                    current_local_authority.consultee_responses.select(:id, :redacted_response, :received_at, :summary_tag)
                end
                def search_params
                    params.permit(:page, :maxresults, :q, :sort_by, :order)
                end
                def query_service(scope = response_scope)
                    @query_service ||= Comment::QuerySpecialistService.new(scope, search_params)
                end
            end
        end
    end
end