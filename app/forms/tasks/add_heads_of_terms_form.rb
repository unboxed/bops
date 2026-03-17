# frozen_string_literal: true

module Tasks
  class AddHeadsOfTermsForm < Form
    self.task_actions = %w[save_and_complete save_draft add_term update_term]

    attribute :title, :string
    attribute :text, :string

    after_initialize do
      @heads_of_terms = planning_application.heads_of_term
      @term = params[:id].present? ? heads_of_terms.terms.find(params[:id]) : heads_of_terms.terms.build

      self.title = @term.title
      self.text = @term.text
    end

    with_options on: %i[add_term update_term], presence: true do
      validates :title
      validates :text
    end

    attr_reader :heads_of_terms, :term

    private

    def save_and_complete
      super do
        @heads_of_terms.confirm_pending_requests! unless planning_application.pre_application?
      end
    end

    def add_term
      heads_of_terms.terms.create!(title:, text:)
      task.start!
    end

    def update_term
      term.update!(title:, text:)
      task.start!
    end
  end
end
