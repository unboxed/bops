# frozen_string_literal: true

module BopsApi
  class Pagination
    include Pagy::Backend

    DEFAULT_PAGE = 1
    DEFAULT_MAXRESULTS = 10
    MAXRESULTS_LIMIT = 50

    def initialize(scope:, params:)
      @scope = scope
      @params = params
    end

    attr_reader :scope, :params

    def paginate
      page = (params[:page] || DEFAULT_PAGE).to_i.clamp(1, 1000)
      maxresults = [(params[:maxresults] || DEFAULT_MAXRESULTS).to_i, MAXRESULTS_LIMIT].min.clamp(1, 1000)

      pagy(scope, page:, items: maxresults, overflow: :last_page)
    end
  end
end
