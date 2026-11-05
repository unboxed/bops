# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class DocumentsAndPhotosForm < Form
      self.task_actions = %w[save_and_complete attach_file edit_document archive_document]

      attribute :file
      attribute :numbers, :string
      attribute :received_at, :date
      attribute :tags, :list, default: []

      validates :file, presence: true, on: :attach_file

      after_initialize do |params|
        document_id = @params.dig("tasks_documents_and_photos_form", "document_id") || @params[:id]
        @document = document_id.present? ? enforcement.documents.find(document_id) : nil
        @numbers = @document&.numbers
        @received_at = @document&.received_at
      end
      attr_reader :document, :numbers, :received_at

      private

      def attach_file
        task.in_progress! if task.not_started?

        case_record.documents.create! do |doc|
          doc.file = file
          doc.user = Current.user
          doc.owner = enforcement
        end
      end

      def edit_document
        task.in_progress! if task.not_started?

        document.update!(attributes.except("file"))
      end

      def archive_document
        document.archive("archived")
      end

      def form_params(params)
        params.require(param_key).permit(*attribute_names, tags: [])
      end
    end
  end
end
