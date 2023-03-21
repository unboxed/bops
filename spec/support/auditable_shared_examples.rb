# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "Auditable" do
  describe "#audit!" do
    context "when current user is present" do
      let(:user) { create(:user) }

      before { Current.user = user }

      it "creates audit assoicated with user" do
        subject.send(:audit!, activity_type: "assigned")

        expect(subject.audits.reload.last).to have_attributes(
          activity_type: "assigned",
          user:,
          api_user: nil,
          automated_activity: false
        )
      end
    end

    context "when current API user is present" do
      let(:api_user) { create(:api_user) }

      before { Current.api_user = api_user }

      it "creates audit assoicated with API user" do
        subject.send(:audit!, activity_type: "assigned")

        expect(subject.audits.reload.last).to have_attributes(
          activity_type: "assigned",
          user: nil,
          api_user:,
          automated_activity: false
        )
      end
    end

    context "when no user is present" do
      it "creates audit with automated_activity set to true" do
        subject.send(:audit!, activity_type: "assigned")

        expect(subject.audits.reload.last).to have_attributes(
          activity_type: "assigned",
          user: nil,
          api_user: nil,
          automated_activity: true
        )
      end
    end
  end
end
