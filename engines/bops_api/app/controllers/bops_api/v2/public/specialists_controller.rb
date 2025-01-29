# frozen_string_literal: true

module BopsApi
    module V2
        module Public
            class SpecialistsController < PublicController
                def show
                    @pagy, @responses = Pagination.new(scope: response_scope, params: query_params).paginate

                    respond_to do |format|
                    format.json
                    end
                end

                private

                def response_scope
                    current_local_authority.consultee_responses
                end

                def query_params
                    params.permit(:page, :maxresults)
                end
            end
        end
    end
end