# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ValidationRequest" do
  describe "#sent_by" do
    let(:user) { create(:user) }
    let(:request) { create(:validation_request, planning_application:) }

    before { Current.user = user }

    context "when a planning application has been invalidated" do
      let(:planning_application) { create(:planning_application, :invalidated) }

      it "returns user for audit associated with send event" do
        expect(request.sent_by).to eq(user)
      end
    end

    context "before a planning application is invalidated" do
      let(:planning_application) { create(:planning_application, :not_started) }

      it "returns user for audit associated with add event" do
        expect(request.sent_by).to eq(user)
      end
    end
  end
end
