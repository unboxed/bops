# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class DocumentsAndPhotosForm < Form
      self.task_actions = %w[save_and_complete attach_file]

      attribute :file

      validates :file, presence: true, on: :attach_file

      private

      def attach_file
        case_record.documents.create! do |doc|
          doc.file = file
          doc.user = Current.user
          doc.owner = enforcement
        end
      end
    end
  end
end
