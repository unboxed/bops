# frozen_string_literal: true

module DrawingWizard
  class ArchiveForm < BaseForm
    validates :archive_reason,
              inclusion: { in: Drawing.archive_reasons.keys,
                          message: "Please select one of the below options" }
  end
end
