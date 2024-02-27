# frozen_string_literal: true

class LocalPolicyArea < ApplicationRecord
  belongs_to :local_policy

  validates :assessment, :policies, :area, presence: true
end
