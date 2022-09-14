# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ValidationRequestable" do
  describe "#sent_by" do
    let(:user) { create(:user) }
    let(:request) { create(described_class.name.underscore) }

    before { Current.user = user }

    it "returns user for audit associated with send event" do
      expect(request.sent_by).to eq(user)
    end
  end
end
