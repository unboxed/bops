# frozen_string_literal: true

class CaseConstraint < ApplicationRecord
  belongs_to :constrainable, polymorphic: true
  belongs_to :constraint
end
