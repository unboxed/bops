# frozen_string_literal: true

module Tasks
  class AddConditionsForm < Form
    self.task_actions = %w[save_and_complete save_draft add_condition update_condition delete_condition]

    attribute :condition_id, :integer
    attribute :title, :string
    attribute :text, :string
    attribute :reason, :string

    after_initialize do
      @condition_set = planning_application.condition_set
      @conditions = @condition_set.conditions.select(&:persisted?).sort_by(&:position)

      if @condition_set.current_review&.to_be_reviewed? && !task.action_required?
        task.action_required!
      end
    end

    attr_reader :condition_set, :conditions

    with_options on: %i[add_condition update_condition] do
      validates :text, presence: {message: "Enter condition"}
      validates :reason, presence: {message: "Enter a reason for this condition"}
    end

    def condition
      @condition ||= if condition_id.present?
        condition_set.conditions.find(condition_id)
      else
        condition_set.conditions.build
      end
    end

    def edit_condition_url(cond)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: cond.id, only_path: true)
    end

    def flash(type, controller)
      return nil unless type == :notice && after_success == "redirect"

      case action
      when "save_and_complete"
        controller.t(".add-conditions.success")
      when "save_draft"
        controller.t(".add-conditions.draft")
      when "add_condition"
        controller.t(".add-conditions.condition_added")
      when "update_condition"
        controller.t(".add-conditions.condition_updated")
      when "delete_condition"
        controller.t(".add-conditions.condition_deleted")
      end
    end

    private

    def add_condition
      condition_set.conditions.create!(title:, text:, reason:, standard: false)
      task.start! unless task.in_progress?
    end

    def update_condition
      condition.update!(title:, text:, reason:)
      task.start! unless task.in_progress?
    end

    def delete_condition
      condition.destroy!
    end

    def save_draft
      super do
        condition_set.create_or_update_review!("in_progress")
      end
    end

    def save_and_complete
      super do
        condition_set.create_or_update_review!("complete")
      end
    end
  end
end
