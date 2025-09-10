# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GOV.UK Notify settings", type: :system do
  include ActiveJob::TestHelper

  let(:local_authority) { create(:local_authority, :default, :unconfigured) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
    ActiveJob::Base.queue_adapter = :test

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

  it "enqueues a SendTestMessageJob when sending a test email via the suffix link" do
    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    fill_in "Email template", with: "9d06d78e-ba05-4789-915d-a053c49be0ce"
    click_button "Submit"

    click_link "Send test email"
    expect(page).to have_content(/Send a test Notify message/i)

    fill_in "Email", with: "test@example.com"
    fill_in "Subject", with: "A subject for testing"
    fill_in "Body", with: "This is the email body for testing."

    expect {
      click_button "Send test"
    }.to have_enqueued_job(SendTestMessageJob).with(
      hash_including(
        channel: "email",
        template_id: "9d06d78e-ba05-4789-915d-a053c49be0ce",
        email: "test@example.com",
        personalisation: {"subject" => "A subject for testing", "body" => "This is the email body for testing."},
        local_authority_id: local_authority.id
      )
    )

    expect(page).to have_current_path("/admin/notify", ignore_query: true)
    expect(page).to have_content("Email test queued for test@example.com")
  end

  it "enqueues a SendTestMessageJob when sending a test SMS via the suffix link" do
    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    fill_in "SMS template", with: "9d06d78e-ba05-4789-915d-a053c49be0cb"
    click_button "Submit"

    click_link "Send test SMS"
    expect(page).to have_content(/Send a test Notify message/i)

    fill_in "Phone number", with: "07900900123"
    fill_in "Body", with: "This is the SMS body for testing."

    expect {
      click_button "Send test"
    }.to have_enqueued_job(SendTestMessageJob).with(
      hash_including(
        channel: "sms",
        template_id: "9d06d78e-ba05-4789-915d-a053c49be0cb",
        phone: "07900900123",
        personalisation: {"body" => "This is the SMS body for testing."},
        local_authority_id: local_authority.id
      )
    )

    expect(page).to have_current_path("/admin/notify", ignore_query: true)
    expect(page).to have_content("SMS test queued for 07900900123")
  end

  it "allows the administrator to preview a letter" do
    visit "/admin/profile"
    click_link "Manage GOV.UK Notify"
    expect(page).to have_selector("h1", text: "Manage GOV.UK Notify settings")

    fill_in "Letter template", with: "9d06d78e-ba05-4789-915d-a053c49be0ca"
    click_button "Submit"
    click_link "Preview letter"

    expect(page).to have_button("Preview letter")

    fill_in "Sender name", with: "Case Officer Smith"
    fill_in "Sender department (optional)", with: "Planning Department"
    fill_in "Recipient name", with: "Jane Doe"
    fill_in "Address line 1", with: "1 Test Street"
    fill_in "Address line 2 (optional)", with: "Flat 2"
    fill_in "Town/City", with: "Test Town"
    fill_in "Postcode", with: "TE5 1NG"
    fill_in "Body", with: "This is a preview body for the letter."

    click_button "Preview letter"

    expect(page).to have_selector("h1", text: /Letter|Letter preview/i)
    expect(page).to have_content("Jane Doe")
    expect(page).to have_content("1 Test Street")
    expect(page).to have_content("Flat 2")
    expect(page).to have_content("Test Town")
    expect(page).to have_content("TE5 1NG")
    expect(page).to have_content("This is a preview body for the letter.")
  end
end
