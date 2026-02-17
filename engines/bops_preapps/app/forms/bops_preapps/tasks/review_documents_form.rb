# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ReviewDocumentsForm < Form
      self.task_actions = %w[save_draft save_and_complete edit_form]
    end
  end
end
