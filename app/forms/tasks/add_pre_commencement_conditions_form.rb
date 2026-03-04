# frozen_string_literal: true

module Tasks
  class AddPreCommencementConditionsForm < Form
    self.task_actions = %w[save_and_complete save_draft add_condition update_condition delete_condition confirm_and_send]

    attribute :condition_id, :integer
    attribute :title, :string
    attribute :text, :string
    attribute :reason, :string

    after_initialize do
      @condition_set = planning_application.pre_commencement_condition_set
      @conditions = @condition_set.not_cancelled_conditions.select(&:persisted?).sort_by(&:position)

      if @condition_set.current_review&.to_be_reviewed? && !task.action_required?
        task.action_required!
      end
    end

    attr_reader :condition_set, :conditions

    with_options on: %i[add_condition update_condition] do
      validates :title, presence: {message: "Enter the title of this condition"}
      validates :text, presence: {message: "Enter the text of this condition"}
      validates :reason, presence: {message: "Enter the reason for this condition"}
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

    def waiting_for_applicant?
      condition_set.validation_requests.any?(&:open?)
    end

    def all_approved?
      condition_set.validation_requests.any? && condition_set.validation_requests.all?(&:approved?)
    end

    def pending_requests?
      condition_set.validation_requests.any?(&:pending?)
    end

    def flash(type, controller)
      return nil unless type == :notice && after_success == "redirect"

      case action
      when "save_and_complete"
        controller.t(".add-pre-commencement-conditions.success")
      when "save_draft"
        controller.t(".add-pre-commencement-conditions.draft")
      when "add_condition"
        controller.t(".add-pre-commencement-conditions.condition_added")
      when "update_condition"
        controller.t(".add-pre-commencement-conditions.condition_updated")
      when "delete_condition"
        controller.t(".add-pre-commencement-conditions.condition_deleted")
      when "confirm_and_send"
        controller.t(".add-pre-commencement-conditions.confirm_sent")
      end
    end

    private

    def add_condition
      condition_set.conditions.create!(title:, text:, reason:)
      task.start! unless task.in_progress?
    end

    def update_condition
      condition.update!(title:, text:, reason:)
      task.start! unless task.in_progress?
    end

    def delete_condition
      condition.destroy!
    end

    def confirm_and_send
      condition_set.confirm_pending_requests!
      task.start! unless task.in_progress?
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
