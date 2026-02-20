# frozen_string_literal: true

module Tasks
  class PermittedDevelopmentRightsForm < Form
    self.task_actions = %w[save_and_complete save_draft edit_form]

    attribute :removed, :boolean
    attribute :removed_reason, :string

    after_initialize do
      if (pdr = current_permitted_development_right)
        self.removed = pdr.removed
        self.removed_reason = pdr.removed_reason
      end
    end

    with_options on: :save_and_complete do
      validates :removed, inclusion: {in: [true, false], message: "Select whether permitted development rights have been removed."}
      validates :removed_reason, presence: {message: "Explain why the permitted development rights have been removed"}, if: :removed
    end

    def permitted_development_rights
      planning_application.permitted_development_rights.returned
    end

    private

    def clear_removed_reason_unless_removed
      self.removed_reason = nil unless removed
    end

    def current_permitted_development_right
      planning_application.permitted_development_rights.last
    end

    def save_and_complete
      transaction do
        create_permitted_development_right("complete")
        super
      end
    end

    def save_draft
      transaction do
        create_permitted_development_right("in_progress")
        super
      end
    end

    def create_permitted_development_right(status)
      clear_removed_reason_unless_removed
      pdr = current_permitted_development_right
      if pdr.nil?
        planning_application.permitted_development_rights.create!(
          removed: removed, removed_reason: removed_reason, status: status, assessor: Current.user
        )
      elsif pdr.to_be_reviewed?
        planning_application.permitted_development_rights.create!(
          removed: removed, removed_reason: removed_reason, status: "updated", assessor: Current.user
        )
      else
        pdr.update!(removed: removed, removed_reason: removed_reason, status: status, assessor: Current.user)
      end
    end
  end
end
