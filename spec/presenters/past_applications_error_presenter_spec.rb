# frozen_string_literal: true

require "rails_helper"

RSpec.describe PastApplicationsErrorPresenter do
  let(:error_messages) do
    [
      [:entry, ["can't be blank"]],
      [:additional_information, ["can't be blank"]]
    ]
  end

  let(:presenter) { described_class.new(error_messages) }

  describe "#formatted_error_messages" do
    it "returns formatted error messages" do
      expect(
        presenter.formatted_error_messages
      ).to contain_exactly(
        [:entry, "Application reference numbers can't be blank"],
        [:additional_information, "Relevant information can't be blank"]
      )
    end
  end
end
