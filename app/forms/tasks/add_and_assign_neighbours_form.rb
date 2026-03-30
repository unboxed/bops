# frozen_string_literal: true

module Tasks
  class AddAndAssignNeighboursForm < Form
    self.task_actions = %w[save_and_complete save_draft edit_neighbour]

    after_initialize do
      @consultation = planning_application.consultation
    end

    attr_reader :consultation

    private

    def save_and_complete
      super do
        consultation.update!(consultation_params)
      end
    end

    def save_draft
      super do
        consultation.update!(consultation_params)
      end
    end

    def edit_neighbour
      neighbour_params.each_pair do |id, attrs|
        consultation.neighbours.find(id).update!(address: attrs[:address])
      end

      task.start!
    end

    def consultation_params
      params.require(:consultation).permit(:polygon_geojson, neighbours_attributes: %i[id address source])
    end

    def neighbour_params
      params.require(:neighbour)
    end
  end
end
