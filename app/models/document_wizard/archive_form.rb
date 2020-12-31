# frozen_string_literal: true

module DocumentWizard
  class ArchiveForm < BaseForm
    validates :archive_reason,
              inclusion: { in: Document.archive_reasons.keys,
                           message: "Please select one of the below options" }
  end
end
