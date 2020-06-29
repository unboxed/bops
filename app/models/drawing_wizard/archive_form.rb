# frozen_string_literal: true

module DrawingWizard
  class ArchiveForm < BaseForm
    validates :archive_reason, presence: true
    validates :updated_at, presence: true
  end
end
