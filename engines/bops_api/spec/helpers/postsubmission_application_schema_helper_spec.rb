# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BopsApi::PostsubmissionApplicationSchemaHelper, type: :helper do
  include BopsApi::PostsubmissionApplicationSchemaHelper

  describe '#format_date?' do
    it 'formats a DateTime object to UTC and returns it in YYYY-MM-DD format' do
      date = DateTime.new(2025, 3, 6, 12, 0, 0)
      expect(format_date?(date)).to eq('2025-03-06')
    end

    it 'returns nil if the date is nil' do
      expect(format_date?(nil)).to be_nil
    end
  end

  describe '#format_datetime?' do
    it 'formats a DateTime object to UTC and returns it in ISO 8601 format' do
      date = DateTime.new(2025, 3, 6, 12, 0, 0)
      expect(format_datetime?(date)).to eq('2025-03-06T12:00:00Z')
    end

    it 'returns nil if the date is nil' do
      expect(format_datetime?(nil)).to be_nil
    end
  end
end