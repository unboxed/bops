# frozen_string_literal: true

require "securerandom"

class CaseRecord < ApplicationRecord
  delegated_type :caseable, types: %w[Enforcement], dependent: :destroy

  belongs_to :local_authority
  belongs_to :user, optional: true
  belongs_to :submission, optional: true

  after_initialize :generate_uuid

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid_v7
  end
end
