# frozen_string_literal: true

class DocumentChecklistItem < ApplicationRecord
  has_many :documents, dependent: :destroy
end
