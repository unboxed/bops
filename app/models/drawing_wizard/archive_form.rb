# frozen_string_literal: true

module DrawingWizard
  class ArchiveForm < BaseForm
    validates :archive_reason, presence: true
    validates :updated_at, presence: true

    validates :archive_reason,
              inclusion: {in: %w(scale design dimensions other),
                          on: :update,
                          message: "Please select one of the above reasons"}
  end
end
