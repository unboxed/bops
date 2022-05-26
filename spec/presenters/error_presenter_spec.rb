# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorPresenter do
  let(:error_messages) { [[:name, ["is invalid"]]] }
  let(:presenter) { described_class.new(error_messages) }

  describe "#formatted_error_messages" do
    it "returns formatted error messages" do
      expect(
        presenter.formatted_error_messages
      ).to contain_exactly(
        [:name, "Name is invalid"]
      )
    end
  end
end
