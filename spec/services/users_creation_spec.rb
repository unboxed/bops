# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersCreation do
  let(:local_authority) { create(:local_authority) }

  context "with a user that is active" do
    let(:params) do
      {
        name: "Alice Planner",
        email: "alice.planner@example.com",
        role: "assessor",
        local_authority: local_authority
      }
    end

    it "creates a new User with the correct attributes" do
      expect {
        described_class.new(**params).perform
      }.to change(User, :count).by(1)

      u = User.find_by(email: "alice.planner@example.com")
      expect(u).to have_attributes(
        name: "Alice Planner",
        email: "alice.planner@example.com",
        role: "assessor",
        local_authority: local_authority
      )
    end
  end

  context "with a user that has been deactivated" do
    deactivated_at_date = Time.zone.parse("2025-05-27 10:38:35.469341000 +0100")

    let(:params) do
      {
        name: "Bob Planner",
        email: "bob.planner@example.com",
        role: "reviewer",
        deactivated_at: deactivated_at_date,
        local_authority: local_authority
      }
    end

    it "creates a new User with the correct attributes" do
      expect {
        described_class.new(**params).perform
      }.to change(User, :count).by(1)

      u = User.find_by(email: "bob.planner@example.com")
      expect(u).to have_attributes(
        name: "Bob Planner",
        email: "bob.planner@example.com",
        role: "reviewer",
        deactivated_at: deactivated_at_date,
        local_authority: local_authority
      )
    end
  end
end
