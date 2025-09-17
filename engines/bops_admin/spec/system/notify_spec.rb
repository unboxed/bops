# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GOV.UK Notify settings", type: :system do
  let(:local_authority) { create(:local_authority, :default, :unconfigured) }
  let(:user) { create(:user, :administrator, local_authority:) }

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

    visit "/admin/profile"
    expect(page).to have_link("Manage GOV.UK Notify", href: "/admin/notify/edit")

    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

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

  it "sends a test SMS immediately via Notify from the suffix link" do
    client = instance_double(Notifications::Client)
    allow(Notifications::Client).to receive(:new)
      .with(local_authority.notify_api_key)
      .and_return(client)

    allow(client).to receive(:send_sms)

    local_authority.update!(sms_template_id: "9d06d78e-ba05-4789-915d-a053c49be0cb")

    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    click_link "Send test SMS"
    expect(page).to have_content(/Send a test SMS/i)

    fill_in "Phone number", with: "07900900123"
    fill_in "Body", with: "This is the SMS body for testing."

    click_button "Send test"

    expect(client).to have_received(:send_sms).with(
      phone_number: "07900900123",
      template_id: "9d06d78e-ba05-4789-915d-a053c49be0cb",
      personalisation: {"body" => "This is the SMS body for testing."}
    )

    expect(page).to have_current_path("/admin/notify/edit", ignore_query: true)
    expect(page).to have_content("SMS test sent to 07900900123")
  end

  it "sends a test email immediately via Notify" do
    client = instance_double(Notifications::Client)
    allow(Notifications::Client).to receive(:new)
      .with(local_authority.notify_api_key)
      .and_return(client)
    allow(client).to receive(:send_email)

    local_authority.update!(sms_template_id: "9d06d78e-ba05-4789-915d-a053c49be0ca")

    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    click_link "Send test email"
    expect(page).to have_content(/Send a test email/i)

    fill_in "Email", with: "test@example.com"
    fill_in "Subject", with: "A subject for testing."
    fill_in "Body", with: "This is the email body for testing."

    click_button "Send test"

    expect(client).to have_received(:send_email).with(
      email_address: "test@example.com",
      template_id: "9d06d78e-ba05-4789-915d-a053c49be0ca",
      personalisation: {"subject" => "A subject for testing.", "body" => "This is the email body for testing."}
    )
    expect(page).to have_current_path("/admin/notify/edit", ignore_query: true)
    expect(page).to have_content("Email test sent to test@example.com")
  end

  it "allows the administrator to preview a letter" do
    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    fill_in "Letter template", with: "9d06d78e-ba05-4789-915d-a053c49be0ca"
    click_button "Submit"
    click_link "Preview letter"

    expect(page).to have_button("Preview letter")

    fill_in "Address line 1", with: "Jane Doe"
    fill_in "Address line 2", with: "1 Test Street"
    fill_in "Address line 3", with: "Flat 2"
    fill_in "Address line 4", with: "Test Town"
    fill_in "Address line 5", with: "TE5 1NG"
    fill_in "Heading", with: "This is a preview heading for the letter."
    fill_in "Message", with: "This is a preview body for the letter."

    click_button "Preview letter"

    expect(page).to have_selector("h1", text: /Letter|Letter preview/i)
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("1 Test Street")
    expect(page).to have_content("Flat 2")
    expect(page).to have_content("Test Town")
    expect(page).to have_content("TE5 1NG")
    expect(page).to have_content("This is a preview heading for the letter.")
    expect(page).to have_content("This is a preview body for the letter.")
  end
end
