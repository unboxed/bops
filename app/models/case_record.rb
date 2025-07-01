# frozen_string_literal: true

require "securerandom"

class CaseRecord < ApplicationRecord
  belongs_to :local_authority

  after_initialize :generate_uuid

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid_v7
  end
end
