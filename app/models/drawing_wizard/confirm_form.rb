# frozen_string_literal: true

module DrawingWizard
  class ConfirmForm < BaseForm
    validates :archive_reason, presence: true
    validates :complete, presence: true
  end
end
