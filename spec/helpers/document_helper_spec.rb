# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentHelper, type: :helper do
  describe "#archive_reason_collection_for_radio_buttons" do
    it "maps the reasons correctly" do
      expect(archive_reason_collection_for_radio_buttons[2]).
          to eq(["dimensions", "Revise dimensions"])
    end
  end
end
