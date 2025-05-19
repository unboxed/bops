# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessing correct local authority" do
  let!(:lambeth) { create(:local_authority, :lambeth) }
  let!(:southwark) { create(:local_authority, :southwark) }

  context "when the council exists" do
    it "renders a page" do
      on_subdomain("lambeth") do
        expect {
          visit "/"

          expect(page).to have_content("Lambeth Back-office Planning System")
          expect(page).not_to have_content("Southwark Back-office Planning System")
        }.not_to raise_error
      end
    end
  end

  context "with non-existent council" do
    it "visit non existing path" do
      on_subdomain("biscuits") do
        expect {
          visit "/"
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
