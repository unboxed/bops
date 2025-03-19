# frozen_string_literal: true

module BopsApi
  # This class handles pagination for Postsubmission data using the Pagy gem.
  # It calculates the number of results per page and the current page based on the provided parameters.
  class PostsubmissionPagination
    include Pagy::Backend

    DEFAULT_PAGE = 1
    DEFAULT_MAXRESULTS = 10
    MAXRESULTS_LIMIT = 50

    # Initializes the pagination service.
    #
    # @param scope [ActiveRecord::Relation] The dataset to paginate.
    # @param params [Hash] The request parameters containing pagination options.
    def initialize(scope:, params:)
      @scope = scope
      @params = params || {}
    end

    attr_reader :scope, :params

    def call
      pagy, paginated_scope = pagy(scope, page:, limit: results_per_page, overflow: :last_page)
      [pagy, paginated_scope]
    end
 
    private

    def results_per_page
      value = params[:resultsPerPage].to_i
      value = DEFAULT_MAXRESULTS if value <= 0
      [value, MAXRESULTS_LIMIT].min.clamp(1, 1000)
    end

    def page
      value = params[:page].to_i
      value = DEFAULT_PAGE if value <= 0
      value.clamp(1, 1000)
    end
  end
end
