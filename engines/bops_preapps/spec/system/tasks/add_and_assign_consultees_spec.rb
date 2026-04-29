# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add and assign consultees task", type: :system do
  let(:path_prefix) { "preapps" }
  let(:slug_path) { "consultees/add-and-assign-consultees" }
  let(:planning_application) { create(:planning_application, :pre_application, :in_assessment, local_authority:, api_user:) }

  before do
    sign_in(user)

    visit "/preapps/#{reference}/consultees/determine-consultation-requirement"
    expect(page).to have_selector("h1", text: "Determine consultation requirement")

    within_fieldset "Is consultation required?" do
      choose "Yes"
    end

    click_button "Save and mark as complete"
    expect(page).to have_content("Consultation requirement was successfully updated")
  end

  it_behaves_like "add and assign consultees task", :pre_application
end
