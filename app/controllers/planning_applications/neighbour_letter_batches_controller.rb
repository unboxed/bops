# frozen_string_literal: true

class PlanningApplications::NeighbourLetterBatchesController < AuthenticationController
  def index
    set_planning_application

    respond_to do |format|
      format.csv do
        headers = %w[address batch date]
        result = CSV.generate(headers:, force_quotes: [0, 1, 2]) do |csv|
          csv << headers
          @planning_application.consultation.neighbour_letter_batches.each_with_index do |batch, i|
            batch.neighbour_letters.each do |letter|
              csv << [letter.neighbour.address.to_s, "Neighbour letter #{i + 1}", batch.created_at.to_s]
            end
          end
        end

        render plain: result, layout: false
      end
      format.html
    end
  end
end
