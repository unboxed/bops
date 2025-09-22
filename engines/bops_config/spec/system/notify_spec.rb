# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "GOV.UK Notify settings", type: :system do
  let(:local_authority) { create(:local_authority, :default, :unconfigured) }
  let(:user) { create(:user, :global_administrator) }

  before do
    sign_in(user)

    allow(Rails.configuration).to receive(:default_notify_api_key)
      .and_return("test-dc7c299a-bf1a-4890-ad05-c1a47b524c8e-e30ecdbb-329a-4833-bc28-43666d160729")

    allow(Rails.configuration).to receive(:default_letter_template_id)
      .and_return("aa09dc93-75cd-4862-a0aa-1494bde65a72")
  end

  it "allows the administrator to update the GOV.UK Notify settings" do
    # TODO: change these to `nil` when we stop using the default account
    expect(local_authority).to have_attributes(
      notify_api_key: "test-dc7c299a-bf1a-4890-ad05-c1a47b524c8e-e30ecdbb-329a-4833-bc28-43666d160729",
      email_reply_to_id: nil,
      email_template_id: nil,
      sms_template_id: nil,
      letter_template_id: "aa09dc93-75cd-4862-a0aa-1494bde65a72"
    )

    visit "/local_authorities"
    expect(page).to have_selector("h1", text: "Review all local authorities")

    within "#all" do
      click_link "PlanX"
    end

    expect(page).to have_selector("h1", text: "PlanX onboarding progress")
    click_link "Edit GOV.UK Notify settings"

    expect(page).to have_selector("h1", text: "Update GOV.UK Notify settings")

    click_button "Submit"
    expect(page).to have_content("Enter the ID of the email template you will be using")
    expect(page).to have_content("Enter the ID of the SMS template you will be using")

    fill_in "API key", with: "live-f06ff28b-f1d1-45b2-bc73-8e1e3df534e9-2c51a5fd-d68b-4687-b9b0-39e2cdf46ad5"
    fill_in "Reply-to email address", with: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb"
    fill_in "Email template", with: "9d06d78e-ba05-4789-915d-a053c49be0ce"
    fill_in "SMS template", with: "80147304-ac8d-422f-aee4-1d540ad70be9"
    fill_in "Letter template", with: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109"

    click_button "Submit"
    expect(page).to have_content("GOV.UK Notify settings successfully updated")

    expect(local_authority.reload).to have_attributes(
      notify_api_key: "live-f06ff28b-f1d1-45b2-bc73-8e1e3df534e9-2c51a5fd-d68b-4687-b9b0-39e2cdf46ad5",
      email_reply_to_id: "13d8cb67-4d5c-40d1-8a4b-bda6661523fb",
      email_template_id: "9d06d78e-ba05-4789-915d-a053c49be0ce",
      sms_template_id: "80147304-ac8d-422f-aee4-1d540ad70be9",
      letter_template_id: "5d2c947e-9c32-478d-b2d7-c0c5a5b92109"
    )
  end
end
