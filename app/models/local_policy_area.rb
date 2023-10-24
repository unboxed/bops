# frozen_string_literal: true

class LocalPolicyArea < ApplicationRecord
  belongs_to :local_policy

  validates :assessment, :policies, :area, presence: {if: :completed?}

  attr_reader :policy

  private

  def completed?
    local_policy.status == "complete"
  end
end
