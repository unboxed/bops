# frozen_string_literal: true

class DocumentChecklistItem < ApplicationRecord
  belongs_to :document_checklist
  has_many :documents, dependent: :destroy
end
