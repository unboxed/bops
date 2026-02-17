# frozen_string_literal: true

module Tasks
  class ReviewDocumentsForm < Form
    self.task_actions = %w[save_and_complete edit_form save_document]

    attribute :numbers, :string
    attribute :publishable, :boolean
    attribute :referenced_in_decision_notice, :boolean
    attribute :available_to_consultees, :boolean
    attribute :validated, :boolean
    attribute :tags, :list
    attribute :invalidated_document_reason, :string

    with_options on: :save_document do
      validates :validated, inclusion: {in: [true, false, "true", "false"], message: "Select whether the document is valid"}
      validates :invalidated_document_reason, presence: {message: "List all issues with the document"}, if: :document_invalid?
      validates :numbers, presence: {message: "Enter a document reference number"}, if: :referenced_in_decision_notice?
    end

    def documents
      @documents ||= planning_application.documents.active
    end

    def document
      @document ||= documents.find(params[:id]) if params[:id].present?
    end

    def has_open_replacement_request?
      document&.replacement_document_validation_request&.open_or_pending?
    end

    def url(options = {})
      if params[:id].present?
        edit_task_component_path(
          planning_application,
          slug: task.full_slug,
          id: params[:id],
          **options.with_defaults(only_path: true)
        ).sub(%r{/edit$}, "")
      else
        super
      end
    end

    private

    def document_invalid?
      validated.to_s == "false"
    end

    def referenced_in_decision_notice?
      referenced_in_decision_notice.to_s == "true"
    end

    def form_params(params)
      params.fetch(param_key, {}).permit(
        :numbers, :publishable, :referenced_in_decision_notice,
        :available_to_consultees, :validated, :invalidated_document_reason,
        tags: []
      )
    end

    def save_document
      transaction do
        document.update!(
          numbers: numbers,
          publishable: publishable,
          referenced_in_decision_notice: referenced_in_decision_notice,
          available_to_consultees: available_to_consultees,
          validated: validated,
          invalidated_document_reason: document_invalid? ? invalidated_document_reason : nil,
          tags: tags || []
        )

        if document_invalid?
          document.planning_application.replacement_document_validation_requests.create!(
            old_document: document,
            reason: invalidated_document_reason,
            user: Current.user
          )
        end
      end
    end
  end
end
