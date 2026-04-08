# frozen_string_literal: true

module Tasks
  class AddAndAssignNeighboursForm < Form
    self.task_actions = %w[save_and_complete save_draft add_addresses remove_all edit_neighbour]

    after_initialize do
      @consultation = planning_application.consultation
    end

    attr_reader :consultation

    def flash(type, controller)
      case action
      when "add_addresses"
        flash_for_add_addresses(type, controller)
      else
        super
      end
    end

    private

    def add_addresses
      return false if neighbour_addresses.empty?

      consultation.update!(consultation_params)

      task.start!
    end

    def remove_all
      consultation.neighbours.destroy_all

      task.start!
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

    def neighbour_addresses
      Array.wrap(consultation_params.fetch(:neighbours_attributes, []))
    end

    def flash_for_add_addresses(type, controller)
      result = case type
      when :notice
        "success"
      when :alert
        "failure"
      end

      return if result.nil?

      if neighbour_addresses.empty?
        controller.t(:".#{slug}.#{action}.no_addresses")
      else
        controller.t(:".#{slug}.#{action}.#{result}")
      end
    end
  end
end
