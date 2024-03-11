# frozen_string_literal: true

class DocumentChecklist < ApplicationRecord
  belongs_to :planning_application

  has_many :document_checklist_items, dependent: :destroy
end
