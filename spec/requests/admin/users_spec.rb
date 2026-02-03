# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Users" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:user) { create(:user, :administrator, local_authority:, name: "Carrie Taylor") }

  before { sign_in(user) }

  describe "PATCH /admin/users/:id" do
    it "does not allow a user to change their own role" do
      expect {
        patch "/admin/users/#{user.id}", params: {user: {role: "assessor"}}
      }.not_to change { user.reload.role }
    end

    it "allows changing another user's role" do
      other_user = create(:user, :reviewer, local_authority:)

      expect {
        patch "/admin/users/#{other_user.id}", params: {user: {role: "assessor"}}
      }.to change { other_user.reload.role }.from("reviewer").to("assessor")
    end
  end
end
