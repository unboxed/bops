# frozen_string_literal: true

class SearchesController < AuthenticationController
  def create
    search = Search.new(search_params)

    render(
      json: {
        html: render_to_string(
          partial: "planning_applications/planning_application_table",
          locals: {
            planning_applications: search.results.order(created_at: :desc),
            planning_application_status: "all",
            title: "All your applications",
            search: search
          }
        )
      }
    )
  end

  private

  def search_params
    params.require(:search).permit(:query, planning_application_ids: [])
  end
end
