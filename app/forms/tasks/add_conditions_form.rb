# frozen_string_literal: true

module Tasks
  class AddConditionsForm < Form
    self.task_actions = %w[save_and_complete save_draft add_condition update_condition delete_condition]

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
      @condition ||= if params[:id].present?
        condition_set.conditions.find(params[:id])
      else
        condition_set.conditions.build
      end
    end

    def condition_url
      route_for(:task_component, planning_application, slug: task.full_slug, id: condition.id, only_path: true)
    end

    def edit_condition_url(condition)
      route_for(:edit_task_component, planning_application, slug: task.full_slug, id: condition.id, only_path: true)
    end

    def remove_condition_url(condition)
      route_for(:planning_application_assessment_condition, planning_application, condition, redirect_to: url, only_path: true)
    end

    def failure_template
      case action
      when "update_condition"
        :edit
      else
        super
      end
    end

    private

    def add_condition
      condition_set.conditions.create!(title:, text:, reason:, standard: false).tap do
        task.start! unless task.in_progress?
      end
    end

    def update_condition
      condition.update!(title:, text:, reason:).tap do
        task.start! unless task.in_progress?
      end
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
